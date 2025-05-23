import RPi.GPIO as g
import time
g.setwarnings(False)
g.setmode(g.BOARD)
g.setup(12,g.IN,pull_up_down=g.PUD_UP)
g.setup(8,g.OUT)
while True:
	try:
		btn=g.input(12)
		if(btn==g.LOW):
			g.output(8,g.HIGH)
			print("Button pressed")
			time.sleep(0.5)
		elif(btn==g.HIGH):
			g.output(8,g.LOW)
	except:
		g.cleanup()