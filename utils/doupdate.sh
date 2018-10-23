#!/bin/bash

# Assumes fuseki-server with dataset named 'ds'

curl --data-binary "@${1}" \
  --header 'Content-type: application/sparql-update' \
  'http://localhost:3030/ds/update'

echo "Done."
