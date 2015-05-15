#!/bin/bash

##
## A script to start felix up. You can customize this to taste so that starting
## things up can be controlled by the environment.
##

# 
# Check the docker environment for RUNTYPE
# By default this is DEV which turns on JVM debugging. Set it to anything else
# to be running a production start without debugging on
#
if [ -z "$RUNTYPE" ]; then
    RUNTYPE=DEV
fi

JVM_OPTIONS=""

case $RUNTYPE in
  DEV)
    JVM_OPTIONS="$JVM_OPTIONS -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n"
  ;;
  *)
  ;;
esac

# Fire up felix
pushd /opt/felix/current && java $JVM_OPTIONS -jar bin/felix.jar

