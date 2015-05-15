#!/bin/bash

##
## zookeeper, kafka, and felix. Although we want felix to start as the foreground application
##

# runs zookeeper, kafka via supervisor configuration files
supervisord

/opt/felix/current/startFelix.sh
