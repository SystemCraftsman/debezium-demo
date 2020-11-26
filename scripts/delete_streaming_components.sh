oc delete -f resources/kafka-connector-elastic-camel.yaml -n debezium-demo;
oc delete -f resources/kafka-connect-camel.yaml -n debezium-demo;
oc delete -f resources/kafka-connector-mysql-debezium.yaml -n debezium-demo;
oc delete -f resources/kafka-connect-debezium.yaml -n debezium-demo;
kfk clusters --delete --cluster demo -n debezium-demo;