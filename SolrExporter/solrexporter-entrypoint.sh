#!/bin/bash

echo "Hello World"
./bin/solr-exporter.sh -p 8094 -z 10.10.193.92:2181 -f /opt/solr-8.8.2/contrib/prometheus-exporter/conf/solr-exporter-config_core.xml -n 16
#./bin/solr-exporter.sh -p 8095 -z 10.10.193.92:2181 -f /opt/solr-8.8.2/contrib/prometheus-exporter/conf/solr-exporter-config_jvm.xml -n 16
#./bin/solr-exporter.sh -p 8096 -z 10.10.193.92:2181 -f /opt/solr-8.8.2/contrib/prometheus-exporter/conf/solr-exporter-config_Jetty_Node_ClusterStatus_OverseerStatus.xml -n 16