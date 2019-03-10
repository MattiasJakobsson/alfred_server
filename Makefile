compile: deps
	mix compile

release: compile
	mix release

deps:
	mix deps.get	

firmware: release
	MIX_TARGET=rpi3 mix firmware

sdcard:
	MIX_TARGET=rpi3 mix firmware.burn

clean:
	mix clean; rm -fr _build _rel _images

distclean: clean
	-rm -fr ebin deps
