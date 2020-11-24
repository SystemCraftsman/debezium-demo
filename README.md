# Debezium Demo

* Install the prereqs:

** Strimzi Kafka CLI:

`sudo pip install strimzi-kafka-cli`

** oc or kubectl
** helm

Login to a Kubernetes or OpenShift cluster and create a new namespace/project

Let's say we create a namespace called `debezium-demo` by running the following command on OpenShift:

`oc new-project debezium-demo`

* Install demo app

`git clone https://github.com/mabulgu/the-neverending-blog.git`

`git checkout debezium-demo`

`cd the-neverending-blog`

`oc start-build neverending-blog --from-dir=. `

`helm template the-neverending-blog chart | oc apply -f - -n debezium-demo`

* Deploy a Kafka cluster with Strimzi Kafka CLI

`export STRIMZI_KAFKA_CLI_STRIMZI_VERSION=0.19.0`

`kfk clusters --create --cluster demo -n debezium-demo`

`unset STRIMZI_KAFKA_CLI_STRIMZI_VERSION`

* Deploy a Kafka Connect cluster with Strimzi Kafka CLI

`oc apply -f resources/kafka-connect-debezium.yaml`


* Deploy and configure a Debezium connector for MySQL

`oc apply -f resources/kafka-connector-mysql-debezium.yaml`

* See the topics:

`kfk topics --list -n debezium-demo -c demo`


