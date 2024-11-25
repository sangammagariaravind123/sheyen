
/*
 * Copyright (c) 1999 University of Southern California.
 * All rights reserved.                                            
 *                                                                
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation, advertising
 * materials, and other materials related to such distribution and use
 * acknowledge that the software was developed by the University of
 * Southern California, Information Sciences Institute.  The name of the
 * University may not be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

/*
 * This finle contains includes used only internally to tclcl.
 */

#ifndef tclcl_internal_h
#define tclcl_internal_h

/*
 * snprintf can't be in tclcl.h since HAVE_SNPRINTF isn't guaranteed
 * to be defined properly by whoever includes tclcl.h.  :-(
 */
#ifndef HAVE_SNPRINTF
extern "C" {
	extern int snprintf(char *buf, int size, const char *fmt, ...);
}
#endif

#endif
