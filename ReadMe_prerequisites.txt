1. Install Performance labs (8.6 and 8.7)
===========================
	Update SQL Server configuration (memory, …) base on "SQL Server Database troubleshooting Performance Guide.docx" document located in "Solr_Pipeline" folder.
	Install clean lab with valid build.
	Create Data prerequisites 
	(Folders, AD Data, Exchange data and 30 days Events retention base on the previous data )
	Note: data creation is outside of pipeline automation since it’s done single time after the lab creation
	but quantity validation for each data type will be done automatically. 
	Prerequisities for enabling Solr Exporter (=Solr metrics) -
	-	In Varonis Management Console UI, set solr ssl to false by
		(Search ssl in “Advanced Application configuration” and change value to 0.
		Go to Solr configuration and change port from 2181 to 2182 and then back to 2181
		and then click on “Save” button.
	-	Disable zookeeper acl (so “solr exporter” will be able to authenticate) as describe in -					https://varonis.sharepoint.com/tfs/dev/Application/_layouts/15/Doc.aspx?sourcedoc={18c1dc17-1e1c-4de4-97c9-4eb450ec7b61}&action=edit&wd=target%28Zookeeper%20Acls.one%7Cead6b9d1-cc1b-4267-b16c-605a9aff61a1%2FHow%20to%20disable%20zookeeper%20acls%7Cbd43a3a6-a69b-4ec0-a928-b6174aba9b42%2F%29
	-	In both Solr and ZK VM’s, set SolrAuthenticationEnable=”False” in watchdog config file.
	-	Stop all Solr and ZK vm’s –
		o	Compress WD folder only in Solr vm’s.
		o	Only in Solr VM’s inside WD folder, overwrite with files that exist in (check if needed for version 8.6)
		\\varonis.com\global\Engineering\Shared\YanivEran\DisableAuthenticationBugFixForVersion8.6
	o	In Solr VM’s, Add the following lines in solr.in.cmd –
		set WebDaUser=WebDaUser
		set WebDaPassword=WebDaPassword
		Then start first all ZK vm’s and then Solr Vm’s

Note: Make sure you import the last Solr services grafana dashboard from TFS (for Varonis services Grafana dashboard)..
TFS link - $/idu Client-Server/WebDA/v8.6/Common/Data Store Team Dashboard.json

==========================================================================================================================



2. Prerequsites (Installing Java + Jenkins + Docker + Docker-compose + GIT ): 
===========================================================================
  - Having 2 Vm's: 
		-  Online VM with Windows 10 OS that come with Docker desktop for getting new DataStore VIP pack every period.
			(this VM can be the personal work computer)
		-  Offline VM (8 cores + 16 GB RAM) also with Windows 10 that have folder access to folder share in Online VM.
  - Online VM: in Windows VM (with internet connection), install Java + Jenkins + GIT + Docker desktop
    Offline VM(no internet): 
		- Download msi's from online VM, copy to offline VM and install all of them except GIT + 
		- Load offline Docker images from Images folder in CMD by running command "docker load –i c:\images\<image tar file>"
			(tar file where created in online VM with this command as example - "docker save -o c:\images\prometheus.tar prom/prometheus")
	  
  - Online VM: Open CMD and cd to C:\ and run command "git clone --depth=1 https://github.com/yaniver/Solr_Pipeline_V4.git"
    Offline VM: Copy "Solr_Pipeline_V4" folder from online VM to offline VM.
  
  - cd  "Solr_Pipeline_V4" folder
  
  - Only for Online VM: Run command "git init"
  
  - In Jenkinsfile that exist in "Solr_Pipeline_V4" folder, update params inside "environment" section.



3. Jenkins - login + Plugins install + Create Jenkins pipeline project + VIP folder configuration
=================================================================================================
	Open browser (http://localhost:8080/) and Copy-Paste value from  file "..\jenkins\secrets\initialAdminPassword"
	(file location - C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Jenkins\.jenkins\secrets)
	Add user name and pw (username:yaniver ;  pw=err) and change Jenkins URL to VM hostname

	Only in Online VM: In case you have internet connection -
		Select "Installed suggested Plugins"
		Inside Jenkins Plugin Manager-->Available, install blue ocean plugin
	Offline VM:
		Extarct plugins.zip content inside C:\Users\yeran\AppData\Local\Jenkins\.jenkins\plugins and restart Jenkins service.
		(or in C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Jenkins\.jenkins\plugins)
		
	Only in Online VM: Enter Blue ocean UI, upload existing pipeline (from Jenkins file located in GitHub) by creating new pipeline (note: github token required for login).
	Offline VM: 
		In Jenkins UI, select "New Item" then choose "freestyle project" with name "Solr Pipeline".
		Copy Pase JenkinsFile content inside "Pipeline-->Script" section.
		Modify in the copied content the powershell scripts path to full path instead of relative path.

	Only in Online VM: Enter new created jenkins pipeline and in Select "Configure" and in "Scan Repository Triggers" check checkbox "Priodically if not otherwise run" and set interval to 1 min.
	
	In online vm: Copy "DownloadVIP" folder to desktop and give Read permission to Everyone for sub-folder "DataStoreVIP"
	In offline vm: Open File Explorer window and enter "\\<online vm ip>" and then enter the credential (required for InstallVIP.ps1 script)



4. Run Jenkins pipeline
=======================
	in CMD under C:\Solr_Pipeline_V4 folder run commit.bat that will commit any changes done in files to GitHub and trigger the pipeline
	(more details about the content of the pipeline can be found below OR by looking at Jenkinsfile content
	Note: Slack notification channel should already be configured in Grafana UI under "Notification channels" and if not then create a Slack channel (as described below).










GENERAL NOTES:
=============

	Following deployments are done by running Jenkins pipeline form Blue Ocena UI (not all deployments included here):
	=============================================================================
		Prometheus+Grafana Installation:
		=============================================
		Link (Full details): https://github.com/stefanprodan/dockprom
		Check script in ../Solr_Pipeline/jenkinsPipelineShellScripts/promdeploy.ps1
		(note: in case you need to delete all resources create by docker-compose including volume run the following command "sudo docker-compose down -v")

		Metrics exporters (such as Solr exporter):
		========================================
		Check script in ../Solr_Pipeline/jenkinsPipelineShellScripts/solrExporterDeploy.ps1

		JMeter deploy:
		==============
		Check script in ../Solr_Pipeline/jenkinsPipelineShellScripts/jmeterScriptExec.ps1




Grafana Notification channel support: 
===================================
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

  Option 2 (Internet exist - "Slack")-
  - In Grafana UI add Slack notification channel and configure it with "Slack Incoming webhook url"


