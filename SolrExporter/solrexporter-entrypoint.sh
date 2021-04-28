#!/bin/bash

./bin/solr-exporter -p 8094 -z http://10.10.193.92:2181/solr -f /opt/solr-8.8.2/contrib/prometheus-exporter/conf/solr-exporter-config_core.xml -n 16 & disown
#./bin/solr-exporter -p 8095 -z http://10.10.193.92:2181/solr -f /opt/solr-8.8.2/contrib/prometheus-exporter/conf/solr-exporter-config_jvm.xml -n 16 & disown
#./bin/solr-exporter -p 8096 -z http://10.10.193.92:2181/solr -f /opt/solr-8.8.2/contrib/prometheus-exporter/conf/solr-exporter-config_Jetty_Node_ClusterStatus_OverseerStatus.xml -n 16 & disown











