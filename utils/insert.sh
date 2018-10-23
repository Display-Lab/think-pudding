#!/bin/bash

# Assumes fuseki-server --update --mem /ds

# Load in causal pathways
curl -X PUT --data-binary @${1} \
  --header 'Content-type: application/ld+json' \
  "http://localhost:3030/ds?graph=${2:-demo}"

echo "Done."
