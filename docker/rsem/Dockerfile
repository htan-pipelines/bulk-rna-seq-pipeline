FROM ubuntu:18.04

MAINTAINER ="mischler"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y gcc \
	&& apt-get install -y python3-pip python3-dev \
	&& cd /usr/local/bin \
    && ln -s /usr/bin/python3 python \
  	&& pip3 --no-cache-dir install --upgrade pip \
	&& apt-get install -y zlib1g-dev libssl-dev \
	&& apt-get install -y samtools 

RUN apt-get install --yes \
    perl \
    perl-base \
    r-base \
    r-base-core \
    r-base-dev \
    git

RUN apt-get install --yes bowtie

# Install RSEM 
WORKDIR /usr/local/
RUN pwd
RUN git clone https://github.com/deweylab/RSEM.git
WORKDIR /usr/local/RSEM
RUN pwd
RUN git checkout v1.3.1
RUN make
ENV PATH /usr/local/RSEM:$PATH
