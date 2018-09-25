#!/bin/bash

# Assumes fuseki-server with dataset named 'ds'
# and updated by ISR

curl --data-binary @result.sparql \
  --header 'Content-type: application/sparql-query' \
  'http://localhost:3030/ds/query' | jq .
