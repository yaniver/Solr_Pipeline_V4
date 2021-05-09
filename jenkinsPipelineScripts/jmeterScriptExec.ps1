$solr_pipeline_home=$args[0]

# Host info
$jmeter_full_path=$solr_pipeline_home + "\\JMeter"
# Container info
$container_name="jmeter"


cd $jmeter_full_path

docker build -t $container_name .


docker run --name $container_name -p 3182:3182  --volume ${jmeter_full_path}:/mnt/jmeter jmeter -n -Jcsv_staticParams=/mnt/jmeter/static_parameters.txt -Jmy_csv=/mnt/jmeter/collectionsList.txt -JThreads=1 -t /mnt/jmeter/SolrJ.jmx -l /mnt/jmeter/tmp/result_1.jtl -j /mnt/jmeter/tmp/jmeter_1.log