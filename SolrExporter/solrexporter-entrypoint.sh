#!/bin/bash

./bin/solr-exporter -p 8094 -b http://10.16.251.22:8983/solr -f /mnt/solrexporter/solr-exporter-config_core.xml -n 16 & disown
./bin/solr-exporter -p 8095 -b http://10.16.251.22:8983/solr -f /mnt/solrexporter/solr-exporter-config_jvm.xml -n 16 & disown
./bin/solr-exporter -p 8096 -b http://10.16.251.22:8983/solr -f /mnt/solrexporter/solr-exporter-config_Jetty_Node_ClusterStatus_OverseerStatus.xml -n 16 & disown
