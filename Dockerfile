FROM ubuntu:14.04
MAINTAINER Mark-Anthony Hutton <mark-anthony.hutton@opsysinc.com>

##
## This is a container that will configure and start Apache ZooKeeper, Apache Kafka, Apache Traffic Server dependencies, and Apache Felix.
##

ENV DEBIAN_FRONTEND noninteractive 

#
# Set up Oracle Java 8
#

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
ADD files/webupd8team-java-trusty.list /etc/apt/sources.list.d/webupd8team-java-trusty.list
RUN apt-get update -y
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer

#
# Install Apache Traffic Server dependencies
#
RUN apt-get -y build-dep trafficserver
RUN apt-get -y install autoconf tcl8.4 tcl8.4-dev libhwloc-dev libhwloc5 libunwind8 libunwind8-dev \
    autoconf pkg-config libtool gcc g++ make openssl libssl-dev tcl8.4 tcl8.4-dev expat libpcre3 \
    libpcre3-dev libcap2 libcap-dev flex hwloc lua5.2 libncurses5 libncurses5-dev curl libxml2 libxml2-dev

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

#
# Now get felix set up
#

ADD http://archive.apache.org/dist/felix/org.apache.felix.main.distribution-4.6.0.tar.gz /tmp/
RUN mkdir -p /opt/felix && cd /opt/felix && tar xzvf /tmp/org.apache.felix.main.distribution-4.6.0.tar.gz
RUN ln -s /opt/felix/felix-framework-4.6.0 /opt/felix/current

#
# Basic plugins to get us running
#

## Pull directly from Apach if possbile
ADD http://archive.apache.org/dist/felix/org.apache.felix.configadmin-1.8.0.jar /opt/felix/current/bundle/
ADD http://mirrors.ibiblio.org/apache/felix/org.apache.felix.eventadmin-1.4.2.jar /opt/felix/current/bundle/
ADD http://archive.apache.org/dist/felix/org.apache.felix.fileinstall-3.4.0.jar /opt/felix/current/bundle/
ADD http://mirrors.ibiblio.org/apache/felix/org.apache.felix.http.api-2.3.2.jar /opt/felix/current/bundle/
ADD http://archive.apache.org/dist/felix/org.apache.felix.http.jetty-3.0.0.jar /opt/felix/current/bundle/
ADD http://mirrors.ibiblio.org/apache/felix/org.apache.felix.http.servlet-api-1.1.0.jar /opt/felix/current/bundle/
ADD http://mirrors.ibiblio.org/apache/felix/org.apache.felix.http.whiteboard-2.3.2.jar /opt/felix/current/bundle/
ADD http://archive.apache.org/dist/felix/org.apache.felix.metatype-1.0.10.jar /opt/felix/current/bundle/
ADD http://mirrors.ibiblio.org/apache/felix/org.apache.felix.log-1.0.1.jar /opt/felix/current/bundle/
## SCR was newer in maven oddly.
ADD http://repo1.maven.org/maven2/org/apache/felix/org.apache.felix.scr/1.8.2/org.apache.felix.scr-1.8.2.jar /opt/felix/current/bundle/
ADD http://archive.apache.org/dist/felix/org.apache.felix.webconsole-4.2.6-all.jar /opt/felix/current/bundle/
ADD http://mirrors.ibiblio.org/apache/felix/org.apache.felix.webconsole.plugins.ds-1.0.0.jar /opt/felix/current/bundle/
ADD http://mirrors.ibiblio.org/apache/felix/org.apache.felix.webconsole.plugins.event-1.1.2.jar /opt/felix/current/bundle/

#
# This section is more specifically for getting JAX-RS running
# We aren't entirely happy with the OSGi connector here, but have yet to find a replacement, so I guess we use it 
#

ADD http://repo1.maven.org/maven2/com/eclipsesource/osgi-jaxrs-connector/3.2.1/osgi-jaxrs-connector-3.2.1.jar /opt/felix/current/bundle/
ADD http://repo1.maven.org/maven2/com/eclipsesource/jaxrs/jersey-all/2.10.1/jersey-all-2.10.1.jar /opt/felix/current/bundle/

#
# And Jackson for good measure, incredibly useful when it comes to json serilization with web services
#

ADD http://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-core/2.4.0/jackson-core-2.4.0.jar /opt/felix/current/bundle/
ADD http://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.4.0/jackson-annotations-2.4.0.jar /opt/felix/current/bundle/
ADD http://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.4.0/jackson-databind-2.4.0.jar /opt/felix/current/bundle/

#
# Now expose where config manager dumps thigs so we can persist
# across starts
#

RUN echo 'felix.cm.dir=/opt/felix/current/configs' >> /opt/felix/current/conf/config.properties
RUN mkdir -p /opt/felix/current/configs

# copy the felix start script
COPY files/scripts/start-felix.sh /opt/felix/current/

# Supervisor configs to start the applications
ADD files/supervisor-conf/zookeeper.conf /etc/supervisor/conf.d/zookeeper.conf
ADD files/supervisor-conf/kafka.conf /etc/supervisor/conf.d/kafka.conf

# 2181 is zookeeper, 9092 is kafka, 8080 8000 for felix
EXPOSE 2181 9092 8080 8000

# copy the main start-up script
COPY files/scripts/start-all.sh /usr/bin/

# run all will start kafka, zookeeper, felix, but felix will be on the foreground
CMD ["/usr/bin/start-all.sh"]
