#!/bin/bash

# Default values for variables
REPO=dorowu/ubuntu-desktop-lxde-vnc
TAG=latest

RED='\033[0;32m'


#for i in $(seq -w 1 2); \
#do \
#	echo -e "$(docker run --privileged \
#	-p 60${i}:80 -p 6081:443 \
#	-v ${PWD}:/src:ro \
#	-e USER=doro -e PASSWORD=mypassword \
#	-e ALSADEV=hw:2,0 \
#	-e SSL_PORT=443 \
#	-e RELATIVE_URL_ROOT=approot \
#	-e OPENBOX_ARGS="--startup /usr/bin/lxterminal" \
#	-v ${PWD}/ssl:/etc/nginx/ssl \
#	--device /dev/snd \
#	--name ubuntu${i} \
#	$REPO:$TAG);" \
#done


for i in $(seq -w 1 99); \
do \
	(docker run --privileged \
	-p 60$((i)):80 -p 6$((i+100)):443 \
	-v ${PWD}:/src:ro \
	-e USER=doro -e PASSWORD=mypassword \
	-e ALSADEV=hw:2,0 \
	-e SSL_PORT=443 \
	-e RELATIVE_URL_ROOT=approot \
	-e OPENBOX_ARGS="--startup /usr/bin/lxterminal" \
	-v ${PWD}/ssl:/etc/nginx/ssl \
	--device /dev/snd \
	--name ubuntu${i} \
	$REPO:$TAG) & \
done
