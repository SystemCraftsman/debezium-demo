# ASAP! – The Storyfied Demo of Introduction to Debezium and Kafka on Kubernetes

> ## Pre-Demo Installations
> 
> ### Install the prereqs:
> 
> * Strimzi Kafka CLI:
> 
> `sudo pip install strimzi-kafka-cli`
> 
> * `oc` or `kubectl`
> * `helm`
> 
> Login to a Kubernetes or OpenShift > cluster and create a new namespace/project.
> 
> Let's say we create a namespace called > `debezium-demo` by running the following > command on OpenShift:
> 
> `oc new-project debezium-demo`
> 
> ### Install demo application 'The NeverEnding Blog'
> 
> Clone the repository:
> 
> `git clone https://github.com/mabulgu/the-neverending-blog.git`
> 
> Checkout the `debezium-demo` branch:
> 
> `git checkout debezium-demo`
> 
> Go into the application directory:
> 
> `cd the-neverending-blog`
> 
> Install the helm template:
> 
> `helm template the-neverending-blog chart | oc apply -f - -n debezium-demo`
> 
> Start the s2i build for the application:
> 
> `oc start-build neverending-blog --from-dir=. -n debezium-demo`
> 
> ...and OpenShift will take care of the rest and you should have a blog application called 'The NeverEnding Blog' in the end:
> 
> ![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/blog.png)
> 
> ### Install Elasticsearch
> 
> Apply Elasticsearch resources to OpenShift:
> 
> `oc apply -f resources/elasticsearch.yaml -n debezium-demo`
> 
> Expose the route for Elasticsearch:
> 
> `oc expose svc elasticsearch-es-http -n debezium-demo`
>
> By clicking on the `route` of the application in the browser you should see a page like this:
>
> ![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/elasticsearch.png)
> 
> And for the overall applications before the demo you should be having something like this (OpenShift Developer Perspective is used here):
> 
> ![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/initial_apps.png)
> 
> So you should have a Django application which uses a MySQL database and an Elasticsearch that has no data connection to the application -yet:)

## ASAP!

So you are working at a company as a `Software Person` and you are responsible for the company's blog application which runs on Django and use MYSQL as a database.

One day your boss comes and tells you this:

![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/os_boss.jpg)

So getting the `command` from your boss, you think that this is a good use case for using Change Data Capture (CDC) pattern.

Since the boss wants it ASAP, you have to find a way to apply this request easily and you think it will be best to implement it via [Debezium](https://debezium.io/) on your `OpenShift Office Space` cluster along with [Strimzi: Kafka on Kubernetes](https://strimzi.io/).

Oh, you can wear a [Hawaiian shirt and jeans](https://www.rottentomatoes.com/m/office_space/quotes/) while you are doing all these even if it's not Friday:)

### Deploy a Kafka cluster with Strimzi Kafka CLI

In order to install Strimzi cluster on OpenShift you decide to use use [Strimzi Kafka CLI](https://github.com/systemcraftsman/strimzi-kafka-cli) which you can also install the operator of it.

First install the Strimzi operator:

`kfk operator --install -n debezium-demo`

---
**IMPORTANT**

If you have already an operator installed, please check the version. If the Strimzi version you've been using is older than 0.20.0, you have to set the right version as an environment variable, so that you will be able to use the right version of cluster custom resource. 

`export STRIMZI_KAFKA_CLI_STRIMZI_VERSION=0.19.0`

---

Let's create a Kafka cluster called `demo` on our OpenShift namespace `debezium-demo`. 

`kfk clusters --create --cluster demo -n debezium-demo`

In the opened editor you may choose 3 broker, 3 zookeeper configuration which is the default. So after saving the configuration file of the Kafka cluster in the developer preview of OpenShift you should see the resources that are created for the Kafka cluster:

![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/strimzi_kafka_cluster.png)

### Deploy a Kafka Connect for Debezium

Now it's time to create a Kafka Connect cluster via using Strimzi custom resources.Since Strimzi Kafka CLI is not capable of creating connect objects yet at the time of writing this article we will create it by using the sample resources in the demo project.

Create a custom resource like the following:

`
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaConnect
metadata:
  annotations:
    strimzi.io/use-connector-resources: 'true'
  name: debezium
spec:
  bootstrapServers: 'demo-kafka-bootstrap:9092'
  config:
    config.storage.replication.factor: '1'
    config.storage.topic: debezium-cluster-configs
    group.id: debezium-cluster
    offset.storage.replication.factor: '1'
    offset.storage.topic: debezium-cluster-offsets
    status.storage.replication.factor: '1'
    status.storage.topic: debezium-cluster-status
  image: 'quay.io/hguerreroo/rhi-cdc-connect:2020-Q3'
  jvmOptions:
    gcLoggingEnabled: false
  replicas: 1
  resources:
    limits:
      memory: 2Gi
    requests:
      memory: 2Gi
`
And apply it to OpenShift `debezioum-demo` namespace (or just apply the one you have in this demo repository)

`oc apply -f resources/kafka-connect-debezium.yaml -n debezium-demo`

This will create a Kafka Connect cluster with the name `debezium` on your namespace:

![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/debezium_connect.png)

### Deploy a Debezium connector for MySQL

So you have the Kafka Connect cluster to be able to use with Debezium. Now it's time for the real magic; the Debezium connector for MySQL.

Create the custom resource like the following, by noticing the parts of configuration starts with `database`. 

Since you have to capture the changes in the `neverendingblog` database which has the `posts` database your configuration should be something like this:

`
apiVersion: kafka.strimzi.io/v1alpha1
kind: KafkaConnector
metadata:
  labels:
    strimzi.io/cluster: debezium
  name: debezium-mysql-connector
spec:
  class: io.debezium.connector.mysql.MySqlConnector
  config:
    database.server.name: db
    database.hostname: mysql
    database.user: debezium
    database.password: dbz
    database.server.id: '184054'
    database.port: '3306'
    database.dbname: neverendingblog
    database.history.kafka.topic: db.history
    database.history.kafka.bootstrap.servers: 'demo-kafka-bootstrap:9092'
  tasksMax: 1
` 

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

Add a new post titled `Javaday Istanbul 2020`
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