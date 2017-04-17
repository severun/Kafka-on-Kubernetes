#!/usr/bin/env bash
KAFKA_CONF_DIR="/opt/kafka/config"
KAFKA_CONFIG_FILE="$KAFKA_CONF_DIR/server.properties"
HOST=`hostname -s`
DOMAIN=`hostname -d`
BROKER_ID=`echo "$POD_NAME" | awk -F '-' '{print $2}'`

function validate_env() {
  echo "Starting environment validation"
  if [ -z $ADVERTISED_HOST_NAME ]; then
    echo "ADVERTISED_HOST_NAME is a mandatory environment variable."
    exit 1
  fi

  if [ -z $ADVERTISED_PORT ]; then
    echo "ADVERTISED_PORT is a mandatory environment variable."
    exit 1
  fi

  if [ -z $POD_IP ]; then
    echo "POD_ID is a mandatory environment variable."
    exit 1
  fi

  echo "ADVERTISED_HOST_NAME=$ADVERTISED_HOST_NAME"
  echo "ADVERTISED_PORT=$ADVERTISED_PORT"
  echo "POD_IP=$POD_IP"
  echo "BROKER_ID=$BROKER_ID"
  echo "Environment validation successful"
}

function create_config() {
  rm -f $KAFKA_CONFIG_FILE
  echo "Creating Kafka configuration in $KAFKA_CONFIG_FILE"

  # Set broker-id based on Kubernetes' stateful set ID
  echo "broker.id=$BROKER_ID" >> $KAFKA_CONFIG_FILE
  echo "" >> $KAFKA_CONFIG_FILE

  # Split external and internal traffic
  echo "listener.security.protocol.map=CLIENT:PLAINTEXT,REPLICATION:PLAINTEXT,INTERNAL_PLAINTEXT:PLAINTEXT,INTERNAL_SASL:PLAINTEXT" >> $KAFKA_CONFIG_FILE
  echo "advertised.listeners=CLIENT://$ADVERTISED_HOST_NAME:30092,REPLICATION://$HOST:30093,INTERNAL_PLAINTEXT://$HOST:30094,INTERNAL_SASL://$HOST:30095" >> $KAFKA_CONFIG_FILE
  echo "listeners=CLIENT://$ADVERTISED_HOST_NAME:30092,REPLICATION://$ADVERTISED_HOST_NAME:30093,INTERNAL_PLAINTEXT://$ADVERTISED_HOST_NAME:30094,INTERNAL_SASL://$ADVERTISED_HOST_NAME:30095" >> $KAFKA_CONFIG_FILE
  echo "inter.broker.listener.name=REPLICATION" >> $KAFKA_CONFIG_FILE
  echo "" >> $KAFKA_CONFIG_FILE

  # Define Zookeeper connections
  echo "zookeeper.connect=<ZK-HOST>:<ZK-PORT>/kafka" >> $KAFKA_CONFIG_FILE
  echo "zookeeper.connection.timeout.ms=6000" >> $KAFKA_CONFIG_FILE
  echo "" >> $KAFKA_CONFIG_FILE

  # Topic management
  echo "auto.create.topics.enable=true" >> $KAFKA_CONFIG_FILE
  echo "delete.topic.enable=true" >> $KAFKA_CONFIG_FILE
  
  # Log retention
  echo "log.dirs=/opt/kafka/data/topics" >> $KAFKA_CONFIG_FILE
  echo "num.partitions=1" >> $KAFKA_CONFIG_FILE
  echo "num.recovery.threads.per.data.dir=1" >> $KAFKA_CONFIG_FILE
  echo "log.retention.hours=4" >> $KAFKA_CONFIG_FILE
  echo "log.segment.bytes=1073741824" >> $KAFKA_CONFIG_FILE
  echo "log.retention.check.interval.ms=300000" >> $KAFKA_CONFIG_FILE
  echo "compression.type=gzip" >> $KAFKA_CONFIG_FILE
  
  # Replication
  echo "default.replication.factor=1" >> $KAFKA_CONFIG_FILE
  echo "reserved.broker.max.id=3000000" >> $KAFKA_CONFIG_FILE
  echo "replica.fetch.max.bytes=10485760" >> $KAFKA_CONFIG_FILE; #DEFAULT
  echo "message.max.bytes=10000000" >> $KAFKA_CONFIG_FILE;
  echo "linger.ms=5" >> $KAFKA_CONFIG_FILE # Send interval when received messages < batch.size(16384)

  # Network and threading
  echo "num.network.threads=16" >> $KAFKA_CONFIG_FILE
  echo "num.io.threads=8" >> $KAFKA_CONFIG_FILE

  # Buffer configurations
  echo "socket.send.buffer.bytes=10485760" >> $KAFKA_CONFIG_FILE
  echo "socket.receive.buffer.bytes=10485760" >> $KAFKA_CONFIG_FILE
  echo "socket.request.max.bytes=104857600" >> $KAFKA_CONFIG_FILE
  echo "queued.max.requests=1000" >> $KAFKA_CONFIG_FILE
  echo "message.max.bytes=10000012" 

  echo "Kafka configuration file written to $KAFKA_CONFIG_FILE"
  cat $KAFKA_CONFIG_FILE
}

validate_env && create_config
