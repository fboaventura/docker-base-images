#!/bin/bash 
#########################################################################
#                                                                       #
# docker-builder.sh is a script for managing complex docker images     #
# It provivides an easy mechanism for creating and building docker      #
# images                                                                #
#                                                                       #
# Author:	Felix Imobersteg                                              #
# Email:	felix@whatwedo.ch                                             #
# Website:	http://whatwedo.ch                                          #
#                                                                       #
#########################################################################


######################################################## 
# CHECK PREREQUISITES                                  # 
########################################################

#Exit on error
#set -e

#Check software
dockerTest=$(which docker)
m4Test=$(which m4)
[ -z "$dockerTest" ] && { echo "docker doesn't appear to be installed - this is required for script to run"; exit 1; }
[ -z "$m4Test" ] && { echo "m4 doesn't appear to be installed - this is required for script to run"; exit 1; }

#Set directory
cd "$(dirname "$0")"


######################################################## 
# MAIN                                                 # 
########################################################

#build all dockerfiles
build-files() {
  rm -rf "dist" 
	for file in images/*.m4; do
	  name="${file##*/}"
	  name="${name%.*}"
	  build-file $name
	done
}


#build the given dockerfile
build-file() {
  rm -rf "dist/$1" 
  mkdir -p "dist/$1"
  cp -R files "dist/$1"
  echo "
##################################################
#                                                #
# DO NOT EDIT THIS FILE MANUALLY                 #
# AUTOMATICALLY CREATED WITH docker-builder.sh   #
#                                                #
##################################################
  " > "dist/$1/Dockerfile"

  lastline=""
  templine=""
  while read -r line; do
    if  [[ $line == RUN* ]] && [[ $templine == RUN* ]] ;
    then
      echo "$lastline && \\" >> "dist/$1/Dockerfile"
      templine=$line
      lastline=$(echo "$line" | sed 's/^RUN //g' )
    elif [[ $line == LASTRUN* ]] && [[ $templine == RUN* ]] ;
    then
      line=$(echo "$line" | sed 's/^LASTRUN\ /RUN\ /g' )
      echo "$lastline" >> "dist/$1/Dockerfile"
      templine=$line
      lastline=$line
    else
      line=$(echo "$line" | sed 's/^LASTRUN\ /RUN\ /g' )
      echo "$lastline" >> "dist/$1/Dockerfile"
      templine=$line
      lastline=$line
    fi
  done <<< "$(m4 -I "modules/*.m4" "images/$1.m4" | grep -v '^\#' | grep -v '^\s*$')"
  echo "$lastline" >> "dist/$1/Dockerfile"

  echo "LABEL ch.whatwedo.image.base=\"whatwedo/$1\"" >> "dist/$1/Dockerfile"

  cp "images/$1.md" "dist/$1/README.md"
}


#build all images
build-images() {
  for file in images/*.m4; do
    name="${file##*/}"
    name="${name%.*}"
    build-image $name
  done
}


#build the given image
build-image() {
  build-file $1
  cd "dist/$1"
  DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4" docker build --no-cache --rm -t "$1:latest" . 
  cd ../..
}

#build the given image with cache
build-cached-image() {
  build-file $1
  cd "dist/$1"
  DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4" docker build --rm -t "$1:latest" . 
  cd ../..
}

#download latest base images
update-base-images() {
  docker pull ubuntu:14.04
  docker pull whatwedo/base:latest
}


if [ "$1" = "build-files" ]; then
  build-files
elif [ "$1" = "build-file" ]; then
  [ -z "$2" ] && { echo "Image name not specified"; exit 1; }
  build-file $2
elif [ "$1" = "build-images" ]; then
  update-base-images
  build-files
  build-images
elif [ "$1" = "build-image" ]; then
  [ -z "$2" ] && { echo "Image name not specified"; exit 1; }
  update-base-images
  build-file $2
  build-image $2
elif [ "$1" = "build-cached-image" ]; then
  [ -z "$2" ] && { echo "Image name not specified"; exit 1; }
  update-base-images
  build-file $2
  build-cached-image $2
else
	echo "
  docker-builder.sh is a script for managing complex docker images
  It provivides an easy mechanism for creating and building docker
  images  
  
  USAGE:
  
  ./docker-builder.sh build-files         - This will build all dockerfiles
  ./docker-builder.sh build-file [name]   - This will build the given dockerfile
  ./docker-builder.sh build-images        - This will build all images
  ./docker-builder.sh build-image [name]  - This will build the given image

  "
fi
