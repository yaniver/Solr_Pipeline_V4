Prerequsite (Installing Docker + Docker-compose + Jenkins): 
===========
  Linux VM with Internet connection (such as,  Ubuntu 19 create from Hyper-V or VMware workstation  in Windows)
    Notes: 
    -  Deploy Ubuntu on Hyper-V --> https://wiki.ubuntu.com/Hyper-V
    -  Enable internet connection link: https://superuser.com/questions/469806/windows-8-hyper-v-how-to-give-vm-internet-access)
  sudo apt install git
  git clone --depth=1  https://github.com/yaniver/Solr_Pipeline.git
  cd CICD
  Run script --> "sudo ./prerequisiteCICD.sh"
  (Optional (for Git push later on)- 
   Run command --> sudo cp -avr ~/CICD /var/lib/jenkins
   cd /var/lib/jenkins/CICD
   git init)

Jenkins - login + Plugins install
===============================
Open browser (http://localhost:8080/) and Copy-Paste value from  command "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
Add user name and pw (username:yaniv ;  pw=err) and change Jenkins URL to VM hostname
Select "Installed suggested Plugins"
Inside Jenkins Plugin Manager-->Available, install blue ocean plugin
Enter Blue ocean UI, upload existing pipeline (from Jenkins file located in GitHub) by creating new pipeline (note: github token required for login)


Environment config:
- In solrexporter folder, Update Solr or ZK IP in solrexporter-entrypoint.sh (in case you have already old image then you need to delete and recreate it).
- In JMeter folder, update Solr ip and collections name in collectionsList.txt.



Following deployments are done by running Jenkins pipeline form Blue Ocena UI:
=============================================================================
	Prometheus+Grafana+Alert_Manager Installation:
	=============================================
	Link (Full details): https://github.com/stefanprodan/dockprom
	Check script in ../CICD/jenkinsPipelineShellScripts/dockpromDeploy.sh
	(note: in case you need to delete all resources create by docker-compose including volume run the following command "sudo docker-compose down -v")

	Prometheus exporter:
	===================
	Check script in ../CICD/jenkinsPipelineShellScripts/solrExporterDeploy.sh

	JMeter deploy:
	==============
	Check script in ../CICD/jenkinsPipelineShellScripts/jmeterScriptExec.sh

GIT:
====
  Push local changes to github -
	git init (only for first time)
	git add -u
	git commit -m "<relevant comment>"
	for checking if other files were change\added\deleted run command - git status
	git push ( or git push origin master)


Grafana Email support: 
====================
  Option 1 (no internet - "email")-
  Note 1: this option will work only inside LAB VM
  Note 2: GF_... setting not required since i already define it in dockprom.zip in docker-compose.yml
  - In docker-compose yml file, in Grafana env add
      - GF_SMTP_ENABLED=true
      - GF_SMTP_HOST=labmail.varonis.com:25
      - GF_SMTP_USER=graphana_user@qa.varonis.com
      - GF_SMTP_PASSWORD=H9JUvRXh0e
      - GF_SMTP_SKIP_VERIFY=true
      - GF_SMTP_FROM_ADDRESS=graphana_user@qa.varonis.com
      - GF_SMTP_FROM_NAME=Grafana
  - In Grafana UI add alert rule in relevant graph (once alerts will be defined in dashboard you can export the json and save it in "dockerpromModification" folder).
  - In Grafana UI add email notification channel (you define a user that already exist in above SMTP server).

  Option 2 (Internet exist - "Microsoft Teams")-
  - In Grafana UI add Microsoft Teams notification channel and configure it with "Teams Incoming webhook url"
    note: Teams Incoming webhook url = https://outlook.office.com/webhook/625e7c6e-9df3-4f88-bc78-41ed9ae4443b@080f3eaf-1e2e-4baf-8c3b-e36006ff4ee8/IncomingWebhook/5a10e4f9a23b4d87bced776b5bbdbb91/1214397b-7abf-44ec-b4eb-a7477eabbae1


