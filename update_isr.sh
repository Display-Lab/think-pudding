#!/bin/bash

# Assumes fuseki-server with dataset named 'ds'

curl -v --data-binary @example/class_test/upd.sparql \
  --header 'Content-type: application/sparql-update' \
  'http://localhost:3030/ds/update'

echo "Done."
