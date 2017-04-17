# Kafka-on-Kubernetes
Configurations and [Docker](https://www.docker.com/what-docker) files for running [Apache Kafka](https://kafka.apache.org/intro) on [Kubernetes](https://kubernetes.io/). 

## Requirements
Kafka uses [Zookeeper](https://zookeeper.apache.org/doc/current/) for this configuration managment. You can use your own Zookeeper setup for this, or make use of the included Zookeeper configurations and Dockerfile, which is based on the [Official Kubernetes Tutorial](https://kubernetes.io/docs/tutorials/stateful-application/zookeeper/). I presume you are able to create working Zookeeper setup using the provided files and the Kubernetes tutorial as guidance. Obviously, you will also need a working Kubernetes and Docker environment :)

## Configurations

### Kafka YAML and configuration files
The Kafka Docker image, which we will create below, contains a generateConfig.sh file which creates the configuration file used by Kafka. In this kafka-image/generateConfig.sh file you should specify the location of your Zookeeper cluster by modifying the line `echo "zookeeper.connect=<ZK-HOST>:<ZK-PORT>/kafka" >> $KAFKA_CONFIG_FILE` and replacing `<ZK-HOST>:<ZK-PORT>` with your Zookeeper cluster's information.

Next are the files located in kafka-configuration. This directory contains all the files for Kubernetes to create the Kafka cluster. The main configuration in located in kafka-stateful.yml, which describes the statefulset. Important configurations in this file are:
* `image: <DOCKER-IMAGE>` This is a reference to the Kafka Docker image we will create below
* `hostNetwork: true` This indicates we will use the Kubenetes Node's network and not the Kubernetes networking layer. (I've enabled this because I needed to interact with Kafka outside of Kubernetes)

To ensure that data persists, even if a Kafka node dies for whatever reason, three presistant volumes are defined in kafka-volume.yml. This creates volumes for our stateful sets, which will always be claimed by the same Kafka node, due to the way stateful sets and persistant volume claims work in Kubernetes. More info can be found [here](https://kubernetes.io/docs/concepts/storage/persistent-volumes/). Please configure this file to match your own setup, by editing the `<server>` and `<path>` variables.

The kafka-service.yml can be used to expose Kafka outside of the Kubernetes cluster, but since I use the `hostNetwork: true` configuration this is not needed. More about Kubernetes services can be found [here](https://kubernetes.io/docs/concepts/services-networking/service/).

### Kafka Docker Image
The docker image containing the Kafka application is located in the kafka-image directory and can be build using the following command: `docker build -t <YOUR-TAG> .`, where you replace `<YOUR-TAG>` with how you want to name your Kafka Docker image. This image uses openjdk 8 and sets up the Scala and Kafka data from their respective sources. The file generateConfig.sh is used to create the Kafka configuration file from within the contain, to allow for a more dynamic setup.

### Zookeeper Docker Image
Similar to the Kafka Docker image, the Zookeeper image is created in similar fashion. The Dockerfile uses Google's image, the one they use in their Kubernetes tutorial, without any modifications. Please use the [Official Kubernetes Tutorial](https://kubernetes.io/docs/tutorials/stateful-application/zookeeper/) on how to run Zookeeper on Kubernetes.
