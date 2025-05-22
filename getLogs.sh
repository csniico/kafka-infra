#!/bin/bash


timestamp="****$(date '+%Y-%m-%d %H:%M:%S')****"

# Microservices
{
  echo "$timestamp"
  docker logs task-api
} >> microservice_app_logs/taskService.logs

{
  echo "$timestamp"
  docker logs user-service
} >> microservice_app_logs/userService.logs

{
  echo "$timestamp"
  docker logs notification-service
} >> microservice_app_logs/notificationService.logs

# Kafka
{
  echo "$timestamp"
  docker logs kafka
} >> kafka_logs/kafka.logs

# Observability
{
  echo "$timestamp"
  docker logs jaeger
} >> observability_stack_logs/jaeger.logs

{
  echo "$timestamp"
  docker logs prometheus
} >> observability_stack_logs/prometheus.logs
