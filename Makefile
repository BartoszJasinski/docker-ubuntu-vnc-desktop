SHELL := /bin/bash

.PHONY: build run

# Default values for variables
REPO  ?= dorowu/ubuntu-desktop-lxde-vnc
TAG   ?= latest
# you can choose other base image versions
IMAGE ?= ubuntu:20.04
# IMAGE ?= nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04
# choose from supported flavors (see available ones in ./flavors/*.yml)
FLAVOR ?= lxde
# armhf or amd64
ARCH ?= amd64

MIN_UBUNTU ?= 1
MAX_UBUNTU ?= 99

# These files will be generated from teh Jinja templates (.j2 sources)
templates = Dockerfile rootfs/etc/supervisor/conf.d/supervisord.conf

# Rebuild the container image
build: $(templates)
	docker build -t $(REPO):$(TAG) .

# Test run the container
# the local dir will be mounted under /src read-only
run:
	docker run --privileged --rm \
		-p 6080:80 -p 6081:443 \
		-v ${PWD}:/src:ro \
		-e USER=doro -e PASSWORD=pass \
		-e ALSADEV=hw:2,0 \
		-e SSL_PORT=443 \
		-e RELATIVE_URL_ROOT=approot \
		-e OPENBOX_ARGS="--startup /usr/bin/lxterminal" \
		-v ${PWD}/ssl:/etc/nginx/ssl \
		--device /dev/snd \
		--name ubuntu-test \
		$(REPO):$(TAG)


# First run many containers in parallel
run-many:
	bash run-many.sh
#	for i in $(seq -w 1 2); \
#	do \
#		docker run --privileged \
#		-p 60${i}:80 -p 6081:443 \
#		-v ${PWD}:/src:ro \
#		-e USER=doro -e PASSWORD=mypassword \
#		-e ALSADEV=hw:2,0 \
#		-e SSL_PORT=443 \
#		-e RELATIVE_URL_ROOT=approot \
#		-e OPENBOX_ARGS="--startup /usr/bin/lxterminal" \
#		-v ${PWD}/ssl:/etc/nginx/ssl \
#		--device /dev/snd \
#		--name ubuntu${i} \
#		$(REPO):$(TAG); \
#	done
	
#		for i in $(enum -e 1 11); do docker run --privileged -p 60${i}:80 -p 6081:443 -v ${PWD}:/src:ro -e USER=doro -e  PASSWORD=mypassword -e ALSADEV=hw:2,0 -e SSL_PORT=443 -e RELATIVE_URL_ROOT=approot -e OPENBOX_ARGS="--startup /usr/bin/lxterminal" -v ${PWD}/ssl:/etc/nginx/ssl --device /dev/snd --name ubuntu${i} $(REPO):$(TAG)	done

	
# Start existing containers
start-many:
	bash start-many.sh $(MIN_UBUNTU) $(MAX_UBUNTU)

# Stop existing containers	
stop-many:
	docker stop $(docker ps -aq)

# Remove exising containers
remove-many:
	docker rm $(docker ps -aq)
	
# Connect inside the running container for debugging
shell:
	docker exec -it ubuntu-desktop-lxde-test bash

# Generate the SSL/TLS config for HTTPS
gen-ssl:
	mkdir -p ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ssl/nginx.key -out ssl/nginx.crt

clean:
	rm -f $(templates)

extra-clean:
	docker rmi $(REPO):$(TAG)
	docker image prune -f

# Run jinja2cli to parse Jinja template applying rules defined in the flavors definitions
%: %.j2 flavors/$(FLAVOR).yml
	docker run -v $(shell pwd):/data vikingco/jinja2cli \
		-D flavor=$(FLAVOR) \
		-D image=$(IMAGE) \
		-D localbuild=$(LOCALBUILD) \
		-D arch=$(ARCH) \
		$< flavors/$(FLAVOR).yml > $@ || rm $@
