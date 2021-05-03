1. Install Grafana msi.
2. Update prometheus.yml with the correct exporters you need.
3. Run promethues.exe from command line
4. In Grafana UI, add Prometheus datasource

Loki steps:
==========
1. Start Loki server by running command "loki-windows-amd64.exe --config.file=loki-local-config.yaml"
2. In Grafana UI, add Prometheus datasource and called it "loki-Prometheus" and set URL to "http://localhost:3100/loki"
3. Import Loki dashboard (json file) in Grafana UI
4. If required - Update promtail-local-config.yaml with the required logs name and path
5. Start promtail for collecting logs to Loki by running command "promtail-windows-amd64.exe --config.file=promtail-local-config.yaml"