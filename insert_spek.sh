#!/bin/bash

# Assumes fuseki-server --update --mem /ds

curl -v -X PUT --data-binary @example/class_test/spek.json \
  --header 'Content-type: application/ld+json' \
  'http://localhost:3030/ds/data?default'

echo "Done."
