FROM ubuntu:16.04

MAINTAINER ="mischler"

USER root

#install dependencies
RUN apt-get update && apt-get install -y\
 default-jre \
 unzip \
 perl

WORKDIR /usr/local/

ADD https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.7.zip /tmp/

RUN unzip /tmp/fastqc_v0.11.7.zip -d . 
RUN chmod 755 FastQC/fastqc
RUN ln -s FastQC/fastqc /usr/local/bin/fastqc
#RUN rm -rf /tmp/fastqc_v0.11.7.zip

ENV PATH="/FASTQC/:${PATH}"

RUN groupadd -r -g 1000 ubuntu && useradd -r -g ubuntu -u 1000 -m ubuntu
USER ubuntu

#run fastqc when container starts
CMD ["fastqc"]
