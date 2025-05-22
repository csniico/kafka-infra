#!/bin/bash

# Start observability stack
docker-compose -f observability-compose.yml up -d

# Then start microservices
docker-compose -f microservices-compose.yml up -d
