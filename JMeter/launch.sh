#!/bin/bash

set -e
freeMem=`awk '/MemFree/ { print int($2/1024) }' /proc/meminfo`
s=$(($freeMem/10*3))
x=$(($freeMem/10*3))
n=$(($freeMem/10*1))
export JVM_ARGS="-Xmn${n}m -Xms${s}m -Xmx${x}m"

echo "START Running Jmeter on `date`"
echo "JVM_ARGS=${JVM_ARGS}"
echo "jmeter args=$@"
echo "container folder - $(pwd)"

# Keep entrypoint simple: we must pass the standard JMeter arguments
jmeter $@
echo "END Running Jmeter on `date`"
