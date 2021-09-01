FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update\
 && apt-get upgrade -y\
 && apt-get install -y python2.7\
 && apt-get install -y samtools\
 && apt-get install -y trimmomatic\
 && apt-get install -y wget\
 && ln -s /usr/bin/python2.7 /usr/local/bin/python\
 && wget -O /tmp/PathoScope-2.0.7.tar.gz https://github.com/PathoScope/PathoScope/archive/refs/tags/v2.0.7.tar.gz\
 && tar -C /tmp -xf /tmp/PathoScope-2.0.7.tar.gz\
 && cd /tmp/PathoScope-2.0.7\
 && python /tmp/PathoScope-2.0.7/ez_setup.py\
 && python /tmp/PathoScope-2.0.7/setup.py install\
 && rm -rf /tmp/PathoScope-2.0.7.tar.gz 
