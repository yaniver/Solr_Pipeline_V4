$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$search_day_from=$args[2]
$domain=$args[3]

# Host info
$jmeter_full_path=$solr_pipeline_home + "\\JMeter"
# Container info
$container_name="jmeter"


cd $jmeter_full_path

#$script_path=$jmeter_full_path + "\\static_parameters.txt"
# Replace params in JMeter config file
#$file_content=(Get-Content -path $script_path -Raw)
# Replace to idu_ip
#$string_to_search=",{(.*)},"
#$file_content -match $string_to_search
#($file_content -replace $matches[1],$idu_ip) | Set-Content -Path $script_path
# Replace to search_day_from
#$string_to_search="tom,(.*),"
#$file_content -match $string_to_search
#($file_content -replace $matches[1],$search_day_from) | Set-Content -Path $script_path
# Replace to domain
#$string_to_search="p@ssword1,(.*),"
#$file_content -match $string_to_search
#($file_content -replace $matches[1],$domain) | Set-Content -Path $script_path

docker build -t $container_name .


docker run --name $container_name -p 443:443 --volume ${jmeter_full_path}:/mnt/jmeter jmeter -n -Jcsv_staticParams="/mnt/jmeter/static_parameters.txt" -Jmy_csv="/mnt/jmeter/searchbody_parameters.txt" -JThreads=1 -t /mnt/jmeter/SOLR_SEARCH.jmx -l /mnt/jmeter/tmp/result_1.jtl -j /mnt/jmeter/tmp/jmeter_1.log