#!/bin/bash

docker-compose -f observability-compose.yml down --remove-orphans
docker-compose -f microservices-compose.yml down --remove-orphans