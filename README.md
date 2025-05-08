# Kafka KRaft Mode Setup Documentation

This document provides a comprehensive guide to setting up Apache Kafka in KRaft mode using Docker containers. It explains the configuration details, core concepts of Kafka, and how to integrate Kafka with your projects.

## Table of Contents

1. [Docker Compose Configuration](#docker-compose-configuration)
2. [Understanding Kafka Core Concepts](#understanding-kafka-core-concepts)
3. [KRaft Mode Explained](#kraft-mode-explained)
4. [Integrating Kafka With Your Projects](#integrating-kafka-with-your-projects)
5. [Common Use Cases and Patterns](#common-use-cases-and-patterns)
6. [Monitoring and Management with Kafka UI](#monitoring-and-management-with-kafka-ui)
7. [Security Considerations](#security-considerations)
8. [Troubleshooting](#troubleshooting)

## Docker Compose Configuration

Below is our working Docker Compose configuration for running Kafka in KRaft mode:

```yaml
version: "3.8"

services:
  kafka:
    image: bitnami/kafka:latest
    container_name: kafka
    environment:
      # Kafka specific configurations
      KAFKA_BROKER_ID: 1
      KAFKA_CFG_NODE_ID: 1
      KAFKA_CFG_PROCESS_ROLES: broker,controller
      KAFKA_CFG_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      KAFKA_CFG_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_CFG_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CFG_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_CFG_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_KRAFT_MODE: true
      KAFKA_CLUSTER_ID: "WfCj5oh9SrmxT-Xzvx11Fw"
      ALLOW_PLAINTEXT_LISTENER: "yes"
    ports:
      - "9092:9092"
    networks:
      - kafka-net
    volumes:
      - kafka_data:/bitnami/kafka

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
    ports:
      - "8080:8080"
    networks:
      - kafka-net
    depends_on:
      - kafka

networks:
  kafka-net:
    driver: bridge

volumes:
  kafka_data:
    driver: local
```

### Configuration Explained

Let's break down each configuration parameter:

#### Kafka Service Configuration

| Parameter                                                                            | Description                                                                                                                                      |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `KAFKA_BROKER_ID: 1`                                                                 | Unique identifier for the Kafka broker within the cluster. In a multi-broker setup, each broker needs a unique ID.                               |
| `KAFKA_CFG_NODE_ID: 1`                                                               | Unique node identifier used in KRaft mode. Must be unique within the cluster.                                                                    |
| `KAFKA_CFG_PROCESS_ROLES: broker,controller`                                         | Specifies that this node acts as both a broker (handling data) and a controller (handling metadata) in KRaft mode.                               |
| `KAFKA_CFG_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093`            | Defines two listeners: one for client communication (PLAINTEXT on port 9092) and another for controller communication (CONTROLLER on port 9093). |
| `KAFKA_CFG_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092`                         | The address clients will use to connect to this broker. For external access, change localhost to your server's hostname or IP.                   |
| `KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT` | Maps listener names to security protocols. Both are using PLAINTEXT (unencrypted) in this setup.                                                 |
| `KAFKA_CFG_CONTROLLER_LISTENER_NAMES: CONTROLLER`                                    | Specifies which listener will be used for controller communication.                                                                              |
| `KAFKA_CFG_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093`                                   | Defines the controller quorum members. Format: `<node_id>@<hostname>:<port>`. For multi-node setups, this would be a comma-separated list.       |
| `KAFKA_CFG_INTER_BROKER_LISTENER_NAME: PLAINTEXT`                                    | The listener that brokers will use to communicate with each other.                                                                               |
| `KAFKA_KRAFT_MODE: true`                                                             | Enables KRaft mode (Kafka Raft metadata mode).                                                                                                   |
| `KAFKA_CLUSTER_ID: "WfCj5oh9SrmxT-Xzvx11Fw"`                                         | A unique identifier for the Kafka cluster. Can be generated with `kafka-storage.sh random-uuid`.                                                 |
| `ALLOW_PLAINTEXT_LISTENER: "yes"`                                                    | Allows unencrypted connections (not recommended for production).                                                                                 |

#### Kafka UI Service Configuration

| Parameter                                       | Description                                                                 |
| ----------------------------------------------- | --------------------------------------------------------------------------- |
| `KAFKA_CLUSTERS_0_NAME: local`                  | Name of the Kafka cluster in the UI.                                        |
| `KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092` | Connection string for the Kafka cluster. Uses Docker service name and port. |

#### Network and Volume Configuration

| Configuration                        | Description                                        |
| ------------------------------------ | -------------------------------------------------- |
| `networks: kafka-net`                | Creates a dedicated network for Kafka services.    |
| `volumes: kafka_data:/bitnami/kafka` | Mounts a persistent volume for Kafka data storage. |

## Understanding Kafka Core Concepts

### What is Apache Kafka?

Apache Kafka is a distributed event streaming platform capable of handling trillions of events per day. It was originally developed by LinkedIn and later open-sourced as an Apache project. Kafka is designed for high-throughput, fault-tolerant, publish-subscribe messaging.

### Core Components

1. **Topics**: The fundamental unit of organization in Kafka. A topic is a category or feed name to which records are published. Topics are partitioned for scalability.

2. **Partitions**: Each topic consists of one or more partitions, which are ordered, immutable sequences of records. Each partition has a leader broker and zero or more follower brokers.

3. **Producers**: Applications that publish (write) data to Kafka topics.

4. **Consumers**: Applications that subscribe to (read) data from Kafka topics.

5. **Consumer Groups**: A group of consumers that jointly consume a set of topics. Each partition is consumed by exactly one consumer within a group.

6. **Brokers**: Kafka servers that store and serve data. A Kafka cluster consists of one or more brokers.

7. **ZooKeeper/KRaft**: Manages the Kafka cluster metadata. Traditional Kafka uses ZooKeeper, while newer versions can use KRaft (our setup) to eliminate the ZooKeeper dependency.

### Message Flow in Kafka

1. **Producers** send messages to Kafka topics.
2. **Brokers** store these messages in partitions.
3. **Consumers** read messages from partitions, keeping track of their position (offset).

### Key Properties of Kafka

- **Durability**: Messages are persisted to disk and replicated across brokers.
- **Scalability**: Horizontally scalable by adding more brokers and partitioning topics.
- **High Performance**: High-throughput, low-latency performance for both publishing and subscribing.
- **Fault Tolerance**: Replication ensures no data loss even if brokers fail.
- **Message Retention**: Messages can be retained for a configurable period, allowing replay of historical data.

## KRaft Mode Explained

KRaft (Kafka Raft) is a consensus protocol implemented in Kafka to replace the dependency on ZooKeeper for managing cluster metadata. KRaft was introduced in Kafka 2.8 as a preview feature and became production-ready in more recent versions.

### Benefits of KRaft Mode

1. **Simplified Architecture**: Eliminates the need for a separate ZooKeeper cluster.
2. **Improved Scalability**: Can handle more partitions and brokers.
3. **Better Performance**: Reduces the overhead of metadata operations.
4. **Simplified Deployment and Operations**: Only one system to manage instead of two.

### How KRaft Works

In KRaft mode, Kafka nodes can take on one or both of these roles:

1. **Controller**: Manages metadata and handles administrative operations.
2. **Broker**: Handles the actual data storage and client requests.

The controller quorum uses the Raft consensus algorithm to maintain metadata consistency. This is why the `KAFKA_CFG_CONTROLLER_QUORUM_VOTERS` setting is crucial - it defines the nodes participating in this consensus.

## Integrating Kafka With Your Projects

### Common Client Libraries

Here are some popular Kafka client libraries for different programming languages:

- **Java**: Kafka's native client
- **Python**: kafka-python, confluent-kafka-python
- **Node.js**: node-rdkafka, kafkajs
- **Go**: sarama, confluent-kafka-go
- **C#/.NET**: confluent-kafka-dotnet
- **Ruby**: ruby-kafka

### Basic Producer Example (Python)

```python
from kafka import KafkaProducer
import json

# Create a producer
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Send a message
producer.send('my-topic', {'key': 'value'})

# Ensure all messages are sent
producer.flush()
```

### Basic Consumer Example (Python)

```python
from kafka import KafkaConsumer
import json

# Create a consumer
consumer = KafkaConsumer(
    'my-topic',
    bootstrap_servers=['localhost:9092'],
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    group_id='my-group',
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

# Consume messages
for message in consumer:
    print(f"Received: {message.value}")
```

### Spring Boot Integration Example (Java)

For Java applications using Spring Boot, Kafka integration is straightforward.

First, add the dependency to your `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

Configure Kafka in `application.properties`:

```properties
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=my-group
spring.kafka.consumer.auto-offset-reset=earliest
```

Producer example:

```java
@Service
public class KafkaProducerService {
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    public void sendMessage(String topic, String message) {
        kafkaTemplate.send(topic, message);
    }
}
```

Consumer example:

```java
@Service
public class KafkaConsumerService {
    @KafkaListener(topics = "my-topic", groupId = "my-group")
    public void consume(String message) {
        System.out.println("Received message: " + message);
        // Process the message
    }
}
```

### Node.js Integration Example

Using KafkaJS library:

```javascript
const { Kafka } = require("kafkajs");

const kafka = new Kafka({
  clientId: "my-app",
  brokers: ["localhost:9092"],
});

// Producer
async function produceMessage() {
  const producer = kafka.producer();
  await producer.connect();
  await producer.send({
    topic: "my-topic",
    messages: [{ value: JSON.stringify({ key: "value" }) }],
  });
  await producer.disconnect();
}

// Consumer
async function consumeMessages() {
  const consumer = kafka.consumer({ groupId: "my-group" });
  await consumer.connect();
  await consumer.subscribe({ topic: "my-topic", fromBeginning: true });
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      console.log({
        value: JSON.parse(message.value.toString()),
      });
    },
  });
}
```

## Common Use Cases and Patterns

### Event Sourcing

Store all changes to application state as a sequence of events. Kafka's immutable log is perfect for this pattern.

### CQRS (Command Query Responsibility Segregation)

Separate read and write operations. Commands (writes) go through Kafka and are processed asynchronously, while queries (reads) access a read-optimized store.

### Microservices Communication

Kafka serves as a message broker between microservices, enabling loose coupling and asynchronous communication.

### Real-time Analytics

Process streams of data in real-time for analytics, dashboards, and monitoring.

### Log Aggregation

Collect logs from various services into a central system for processing and analysis.

### Data Pipeline / ETL

Extract, transform, and load data between various systems in a scalable way.

## Monitoring and Management with Kafka UI

The Kafka UI provides a graphical interface for monitoring and managing your Kafka cluster.

### Features of Kafka UI

1. **Topic Management**: Create, delete, and configure topics.
2. **Consumer Group Monitoring**: View consumer groups, their offsets, and lag.
3. **Message Browsing**: Inspect messages within topics.
4. **Broker Information**: View broker status and configuration.
5. **Performance Metrics**: Monitor throughput, latency, and other performance metrics.

### Accessing Kafka UI

With our Docker Compose setup, Kafka UI is accessible at `http://localhost:8080`.

### Common Operations in Kafka UI

1. **Creating a Topic**:

   - Navigate to the "Topics" section
   - Click "Add a Topic"
   - Specify name, number of partitions, and replication factor
   - Click "Create"

2. **Browsing Messages**:

   - Select a topic from the list
   - Navigate to the "Messages" tab
   - Set filters if needed and click "Load Messages"

3. **Monitoring Consumer Groups**:
   - Go to the "Consumer Groups" section
   - Select a group to view its details

## Security Considerations

Our current setup uses plaintext (unencrypted) communication, which is not suitable for production. For production environments, consider:

### 1. Encryption (SSL/TLS)

Encrypt communication between clients and brokers using SSL/TLS:

```yaml
KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT,SSL:SSL
KAFKA_CFG_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093,SSL://0.0.0.0:9094
KAFKA_CFG_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092,SSL://localhost:9094
```

You'll also need to configure SSL keystores and truststores.

### 2. Authentication

Implement SASL authentication:

```yaml
KAFKA_CFG_SASL_ENABLED_MECHANISMS: PLAIN
KAFKA_CFG_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
KAFKA_CFG_LISTENERS: SASL_PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
```

### 3. Authorization

Configure ACLs (Access Control Lists) to control which clients can read from or write to which topics:

```yaml
KAFKA_CFG_AUTHORIZER_CLASS_NAME: kafka.security.authorizer.AclAuthorizer
KAFKA_CFG_ALLOW_EVERYONE_IF_NO_ACL_FOUND: "false"
```

## Troubleshooting

### Common Issues and Solutions

1. **Connection Refused**:

   - Check if the Kafka container is running
   - Verify port mappings
   - Ensure the advertised listeners match how clients are trying to connect

2. **Topic Not Found**:

   - Verify the topic exists using Kafka UI
   - Check spelling and case sensitivity

3. **Consumer Not Receiving Messages**:

   - Verify consumer group ID
   - Check if another consumer in the same group is consuming the partitions
   - Verify auto.offset.reset configuration

4. **Producer Not Sending Messages**:

   - Check connection settings
   - Look for error callbacks in the producer code

5. **Permission Denied**:
   - Check ACLs if security is enabled
   - Verify authentication credentials

### Viewing Kafka Logs

To view Kafka container logs:

```bash
docker logs kafka
```

For continuous monitoring:

```bash
docker logs -f kafka
```

### Connecting to the Kafka Container

To execute commands inside the Kafka container:

```bash
docker exec -it kafka bash
```

From there, you can use Kafka's command-line tools in the `/opt/bitnami/kafka/bin` directory.

---

This documentation provides a solid foundation for understanding and working with Kafka in KRaft mode. As your Kafka usage grows, you may need to explore more advanced topics such as exactly-once semantics, schema management with systems like Apache Avro and Schema Registry, and more sophisticated deployment patterns.
