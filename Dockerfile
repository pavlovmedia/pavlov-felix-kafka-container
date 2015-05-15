FROM pavlovmedia/pavlov-felix-container
MAINTAINER Shawn Dempsay <sdempsay@pavlovmedia.com>

##
## This is a container that will configure and start Apache ZooKeeper, Apache Kafka, and Apache Felix.
##

ENV DEBIAN_FRONTEND noninteractive 

#
# Set up Kafka.
# Reference: https://github.com/spotify/docker-kafka/blob/master/kafka/Dockerfile
#

# Download and copy the Kafka archive
ADD http://apache.mirrors.spacedump.net/kafka/0.8.2.1/kafka_2.9.1-0.8.2.1.tgz /tmp/kafka_2.9.1-0.8.2.1.tgz

# Install 
RUN apt-get update && \
    apt-get install -y zookeeper wget supervisor dnsutils && \
    rm -rf /var/lib/apt/lists/* && \
    tar xfz /tmp/kafka_2.9.1-0.8.2.1.tgz -C /opt && \
    rm /tmp/kafka_2.9.1-0.8.2.1.tgz

# set up the start script to be called by the supervisor
ENV KAFKA_HOME /opt/kafka_2.9.1-0.8.2.1
ADD files/scripts/start-kafka.sh /usr/bin/start-kafka.sh

# Supervisor configs to start the applications
ADD files/supervisor-conf/zookeeper.conf /etc/supervisor/conf.d/zookeeper.conf
ADD files/supervisor-conf/kafka.conf /etc/supervisor/conf.d/kafka.conf

# 2181 is zookeeper, 9092 is kafka, 8080 8000 for felix
EXPOSE 2181 9092 8080 8000

# copy the main start-up script
COPY files/scripts/start-all.sh /usr/bin/

# run all will start kafka, zookeeper, felix, but felix will be on the foreground
CMD ["/usr/bin/start-all.sh"]
