# Debezium Demo

## Pre Demo Installations

### Install the prereqs:

* Strimzi Kafka CLI:

`sudo pip install strimzi-kafka-cli`

* oc or kubectl
* helm

Login to a Kubernetes or OpenShift cluster and create a new namespace/project

Let's say we create a namespace called `debezium-demo` by running the following command on OpenShift:

`oc new-project debezium-demo`

### Install demo app

`git clone https://github.com/mabulgu/the-neverending-blog.git`

`git checkout debezium-demo`

`cd the-neverending-blog`

`helm template the-neverending-blog chart | oc apply -f - -n debezium-demo`

`oc start-build neverending-blog --from-dir=. -n debezium-demo`

### Install Elasticsearch

`oc apply -f resources/elasticsearch.yaml`

`oc expose svc elasticsearch-es-http`

## Demo Time!

### Deploy a Kafka cluster with Strimzi Kafka CLI

`export STRIMZI_KAFKA_CLI_STRIMZI_VERSION=0.19.0`

`kfk clusters --create --cluster demo -n debezium-demo`

`unset STRIMZI_KAFKA_CLI_STRIMZI_VERSION`

### Deploy a Kafka Connect for Debezium

`oc apply -f resources/kafka-connect-debezium.yaml -n debezium-demo`


### Deploy a Debezium connector for MySQL

`oc apply -f resources/kafka-connector-mysql-debezium.yaml -n debezium-demo`

### See the topics:

`kfk topics --list -n debezium-demo -c demo`

### Observe the changes

`kfk console-consumer --topic db.neverendingblog.posts -n debezium-demo -c demo`


### Apply conversion and transformation

`oc apply -f resources/kafka-connector-mysql-debezium_transformed.yaml -n debezium-demo`

### Observe transformed changes

Consume the messages:

`kfk console-consumer --topic db.neverendingblog.posts -n debezium-demo -c demo`

Open the browser and open Neverending Blog admin page.

Add a new post like `Java Day Istanbul 2020`
### Deploy a Kafka Connect Cluster for Camel

`oc apply -f resources/kafka-connect-camel.yaml -n debezium-demo`

### Deploy a Camel Sink connector for Elasticsearch

`oc apply -f resources/kafka-connector-elastic-camel.yaml -n debezium-demo`


### Let's test Elasticsearch

Get posts index:

`
curl -X GET \
  http://elasticsearch-es-http-debezium-demo.apps.cluster-jdayist-6d29.jdayist-6d29.example.opentlc.com/posts/_search \
  -H 'Postman-Token: 03ff72a2-84bc-4323-b863-c66ddd1cbf5c' \
  -H 'cache-control: no-cache'
`

Search for `Javaday Istanbul 2020` titled post changes:

`
curl -X GET \
  'http://elasticsearch-es-http-debezium-demo.apps.cluster-jdayist-6d29.jdayist-6d29.example.opentlc.com/posts/_search?q=title:Javaday%20Istanbul%202020' \
  -H 'Postman-Token: b9c787ac-ce07-4060-9f61-821d110b7389' \
  -H 'cache-control: no-cache'
`