all: build vers
build:
	./build.sh

vers:
	docker run -it --rm rainbond/rbd-lb:3.6 version
