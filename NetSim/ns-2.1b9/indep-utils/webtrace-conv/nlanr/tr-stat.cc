// Generate statistics from UCB traces
// All we need to know: 
// 
// (1) client request streams: 
//     <time> <clientID> <serverID> <URL_ID> 
// (2) server page mod stream(s):
//     <serverID> <URL_ID> <PageSize> <access times>
//
// Part of the code comes from Steven Gribble's UCB trace parse codes
// 
// $Header: /nfs/jade/vint/CVSROOT/ns-2/indep-utils/webtrace-conv/nlanr/tr-stat.cc,v 1.2 1999/07/09 21:19:08 haoboy Exp $

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <tcl.h>

#include "logparse.h"

Tcl_HashTable cidHash;  // Client id (IP, port) hash
int client = 0;		// client sequence number

Tcl_HashTable sidHash;	// server id (IP, port) hash
int server = 0;		// server sequence number

Tcl_HashTable urlHash;	// URL id hash
int url = 0;		// URL sequence number
int* umap;		// URL mapping table, used for url sort
struct URL {
	URL(int i, int sd, int sz) : access(1), id(i), sid(sd), size(sz) {}
	int access;	// access counts
	int id;
	int sid, size;
};

FILE *cf, *sf;
double initTime = -1;
double duration = -1;
double startTime = -1;

struct ReqLog {
	ReqLog() {}
	ReqLog(double t, unsigned int c, unsigned int s, unsigned int u) :
		time(t), cid(c), sid(s), url(u) {}
	double time;
	unsigned int cid, sid, url;
};
ReqLog* rlog = NULL;
unsigned int num_rlog = 0, sz_rlog = 0;

int compare(const void *a1, const void *b1)
{
	const ReqLog *a = (const ReqLog*)a1, *b = (const ReqLog*)b1;
	return (a->time > b->time) ? 1 : 
		(a->time == b->time) ? 0 : -1;
}

void sort_rlog()
{
	qsort((void *)rlog, num_rlog, sizeof(ReqLog), compare);
	double t = rlog[0].time;
	for (unsigned int i = 0; i < num_rlog; i++) {
		rlog[i].time -= t;
		fprintf(cf, "%f %d %d %d\n", rlog[i].time, 
			rlog[i].cid, rlog[i].sid, umap[rlog[i].url]);
	}
	delete []umap;
	// Record trace duration and # of unique urls
	fprintf(cf, "i %f %u\n", rlog[num_rlog-1].time, url);
}

int compare_url(const void* a1, const void* b1)
{
	const URL **a = (const URL**)a1, **b = (const URL**)b1;
	return ((*a)->access > (*b)->access) ? -1:
		((*a)->access == (*b)->access) ? 0 : 1;
}

void sort_url()
{
	// XXX use an interval member of Tcl_HashTable
	URL** tbl = new URL*[urlHash.numEntries];
	Tcl_HashEntry *he;
	Tcl_HashSearch hs;
	int i = 0, sz = urlHash.numEntries;
	for (he = Tcl_FirstHashEntry(&urlHash, &hs);
	     he != NULL;
	     he = Tcl_NextHashEntry(&hs))
		tbl[i++] = (URL*)Tcl_GetHashValue(he);
	Tcl_DeleteHashTable(&urlHash);

	// sort using access frequencies
	qsort((void *)tbl, sz, sizeof(URL*), compare_url);
	umap = new int[url];
	// write sorted url to page table
	for (i = 0; i < sz; i++) {
		umap[tbl[i]->id] = i;
		fprintf(sf, "%d %d %d %u\n", tbl[i]->sid, i,
			tbl[i]->size, tbl[i]->access);
		delete tbl[i];
	}
	delete []tbl;
}

double lf_analyze(lf_entry& lfe)
{
	double time;
	int ne, cid, sid, uid;
	Tcl_HashEntry *he;

	time = lfe.rt;

	if (initTime < 0) {
		initTime = time;
		time = 0;
	} else 
		time -= initTime;

	// If a trace start time is required, don't do anything
	if ((startTime > 0) && (time < startTime)) 
		return -1;

	// Ignore pages with size 0
	if (lfe.size == 0) 
		return -1;

	// check client id
	if (!(he = Tcl_FindHashEntry(&cidHash, (const char *)lfe.cid))) {
		// new client, allocate a client id
		he = Tcl_CreateHashEntry(&cidHash, (const char *)lfe.cid, &ne);
		Tcl_SetHashValue(he, ++client);
		cid = client;
	} else {
		// existing entry, find its client seqno
		cid = (int)Tcl_GetHashValue(he);
	}

	// check server id
	if (!(he = Tcl_FindHashEntry(&sidHash, lfe.sid))) {
		// new server, assign a server id
		he = Tcl_CreateHashEntry(&sidHash, lfe.sid, &ne);
		Tcl_SetHashValue(he, ++server);
		sid = server;
	} else {
		// existing entry, find its client seqno
		sid = (int)Tcl_GetHashValue(he);
	}

	// check url id
	if (!(he = Tcl_FindHashEntry(&urlHash, lfe.url))) {
		// new client, allocate a client id
		he = Tcl_CreateHashEntry(&urlHash, lfe.url, &ne);
		URL* u = new URL(++url, sid, lfe.size);
		Tcl_SetHashValue(he, (const char*)u);
		uid = u->id;
		//fprintf(sf, "%d %d %ld\n", sid, u->id, lfe.rhl+lfe.rdl);
	} else {
		// existing entry, find its client seqno
		URL* u = (URL*)Tcl_GetHashValue(he);
		u->access++;
		uid = u->id;
	}

	rlog[num_rlog++] = ReqLog(time, cid, sid, uid);
	//fprintf(cf, "%f %d %d %d\n", time, cid, sid, uid);

	if (startTime > 0) 
		return time - startTime;
	else 
		return time;
}

int main(int argc, char**argv)
{
	lf_entry lfntree;
	int      ret;
	double   ctime;

	// Init tcl
	Tcl_Interp *interp = Tcl_CreateInterp();
	if (Tcl_Init(interp) == TCL_ERROR) {
		printf("%s\n", interp->result);
		abort();
	}
	Tcl_InitHashTable(&cidHash, TCL_ONE_WORD_KEYS);
	Tcl_InitHashTable(&sidHash, TCL_STRING_KEYS);
	Tcl_InitHashTable(&urlHash, TCL_STRING_KEYS);

	if ((cf = fopen("reqlog", "w")) == NULL) {
		printf("cannot open request log.\n");
		exit(1);
	}
	if ((sf = fopen("pglog", "w")) == NULL) {
		printf("cannot open page log.\n");
		exit(1);
	}

	if ((argc < 2) || (argc > 4)) {
		printf("Usage: %s <trace size> [<time duration>] [<start_time>]\n", argv[0]);
		return 1;
	}
	if (argc >= 3) {
		duration = strtod(argv[2], NULL);
		if (argc == 4) {
			startTime = strtod(argv[3], NULL);
			printf("start time = %f\n", startTime);
		}
	}

	sz_rlog = strtoul(argv[1], NULL, 10);
	rlog = new ReqLog[sz_rlog];

	while(1) {
		ret = lf_get_next_entry(stdin, lfntree);
		if (ret > 0) {
			if (ret == 1) {
				/* EOF */
				break;
			}
			fprintf(stderr, "Failed to get next entry.\n");
			exit(1);
		} else if (ret < 0) {
			// Unusable entry, i.e., cache miss, cgi-bin, etc.
			continue;
		}
		// Analyse one log entry
		ctime = lf_analyze(lfntree);
		delete []lfntree.url;
		delete []lfntree.sid;
		if ((duration > 0) && (ctime > duration))
			break;
	}
	Tcl_DeleteHashTable(&cidHash);
	Tcl_DeleteHashTable(&sidHash);

	fprintf(stderr, "sort url\n");
	sort_url();
	fclose(sf);

	fprintf(stderr, "sort requests\n");
	sort_rlog();
	fclose(cf);

	fprintf(stderr, 
		"%d unique clients, %d unique servers, %d unique urls.\n", 
		client, server, url);
	return 0;
}
