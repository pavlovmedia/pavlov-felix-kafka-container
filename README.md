pavlov-kafka-container
----------------------

This project is a docker container to help get moving quickly running a OSGi system
using Apache Felix.

It starts on a ubunutu 14.04 lts image, adds Oracle Java 8, and then sets up Apache ZooKeeper, Apache Kafka, dependencies for Apache Traffic Server and Apache Felix with a number of common bundles that are used by Pavlov Media.

To build the container, use the convenience script:
~~~
./buildContainer.sh
~~~

It also sets up a number of things that you can use to make it convient to run with Docker.

Be sure to expose the following ports to be accessible by the host:
  * 8000 RCP
  * 8080 Felix WebConsole
  * 2181 ZooKeeper
  * 9092 Kafka
\

Here is an example of running this in debug mode:

~~~
docker run -ti -p 8000:8000 -p 8080:8080 -p 2181:2181 -p 9092:9092 -v /tmp/load:/opt/felix/current/load pavlovmedia/pavlov-kafka-container
~~~
