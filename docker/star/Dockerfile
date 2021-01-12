FROM ubuntu:18.04

MAINTAINER ="mischler"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y\
    default-jdk \
    unzip \
    perl \
    wget \
    git

RUN apt-get update \
	&& apt-get install -y gcc \
	&& apt-get install -y python3-pip python3-dev \
	&& cd /usr/local/bin \
    && ln -s /usr/bin/python3 python \
  	&& pip3 --no-cache-dir install --upgrade pip \
	&& apt-get install -y zlib1g-dev libssl-dev \
	&& apt-get install -y samtools 

#install STAR
ADD https://github.com/alexdobin/STAR/archive/2.7.1a.tar.gz /usr/bin/
RUN tar -xzf /usr/bin/2.7.1a.tar.gz -C /usr/bin
RUN cp /usr/bin/STAR-2.7.1a/bin/Linux_x86_64/* /usr/local/bin
