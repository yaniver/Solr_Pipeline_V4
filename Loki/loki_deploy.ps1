#Install Garfana 
Start-Process -Wait '.\Prometheus_plus_Grafana/grafana-7.3.3.windows-amd64.msi' '/quiet'
#Start Prometheus Server
Start-Process ".\Prometheus_plus_Grafana\prometheus-2.23.0.windows-amd64\prometheus.exe" -WorkingDirectory ".\Prometheus_plus_Grafana\prometheus-2.23.0.windows-amd64"
#Start Loki Server
Start-Process ".\loki-windows-amd64.exe" "--config.file=loki-local-config.yaml" -WorkingDirectory ".\"
#Create data sources in Grafana
Copy-Item ".\provisioning\datasources\default.yaml" -Destination "C:\Program Files\GrafanaLabs\grafana\conf\provisioning\datasources"
Restart-Service -Name Grafana
#Import Loki dashboard (json file) in Grafana
Copy-Item ".\provisioning\dashboards\default.yaml" -Destination "C:\Program Files\GrafanaLabs\grafana\conf\provisioning\dashboards"
Copy-Item ".\Logs_Dashboard.json" -Destination "C:\Program Files\GrafanaLabs\grafana\conf\provisioning\dashboards"
Restart-Service -Name Grafana
#Start promtail for collecting logs
Start-Process ".\promtail-windows-amd64.exe" "--config.file=promtail-local-config.yaml" -WorkingDirectory ".\"
