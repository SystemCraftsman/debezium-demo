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
> ...and OpenShift will take care of the rest.
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
> So before the demo you should be having something like this:
> 
> ![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/initial_apps.png)
> 
> So you should have a Django application which uses a MySQL database and an Elasticsearch that has no data connection to the application -yet:)

## Demo Instructions ASAP!

So you are working at a company as a `Software Person` and you are responsible for the company's blog application which runs on Django and use MYSQL as a database.

One day your boss comes and tells you this:

![](https://github.com/systemcraftsman/debezium-demo/blob/main/images/os_boss.jpg)

So getting the `command` from your boss, you think that this is a good use case for using Change Data Capture (CDC) pattern.

Since the boss wants it ASAP, you have to find a way to apply this request easily and you think it will be best to implement it via [Debezium](https://debezium.io/) on your `OpenShift Office Space` cluster along with [Strimzi: Kafka on Kubernetes](https://strimzi.io/).

Oh, you can wear a [Hawaiian shirt and jeans](https://www.rottentomatoes.com/m/office_space/quotes/) while you are doing all these even if it's not Friday:)

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