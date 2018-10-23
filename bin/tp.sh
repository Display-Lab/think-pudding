#!/usr/bin/env bash

# Usage message
read -r -d '' USE_MSG <<'HEREDOC'
Usage:
  tp.sh -h
  tp.sh -p causal_pathway.json
  tp.sh -s spek.json  

TP reads a spek from stdin or provided file path.  

Options:
  -h | --help   print help and exit
  -p | --pathways path to configuration file
  -s | --spek   path to spek file (default to stdin)
HEREDOC

# Parse args
# Parse args
PARAMS=()
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "${USE_MSG}"
      exit 0
      ;;
    -p|--pathways)
      CP_FILE="${2}"
      shift 2
      ;;
    -s|--spek)
      SPEK_FILE="${2}"
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Aborting: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS+=("${1}")
      shift
      ;;
  esac
done

if [[ -z ${CP_FILE} ]]; then
  echo >&2 "Causal pathway file required."; 
  exit 1;
fi

# Check if FUSEKI is running.
FUSEKI_PING=$(curl -s -o /dev/null -w "%{http_code}" localhost:3030/$/ping)
if [[ -z ${FUSEKI_PING}} || ${FUSEKI_PING} -ne 200 ]]; then
  # Error
  echo >&2 "Fuseki not running locally."; exit 1;

  # Try to start custom fuseki locally
  FUSEKI_DIR=/opt/fuseki/apache-jena-fuseki-3.8.0
  ${FUSEKI_DIR}/fuseki-server --mem --update /ds 1> fuseki.out 2>&1 &

  # Exit
  exit 1
fi

# Define SPARQL Queries for updates and results
read -r -d '' UPD_SPARQL <<'USPARQL'
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX cpo: <http://example.com/cpo#>
PREFIX slowmo: <http://example.com/slowmo#>

INSERT {
  GRAPH <http://localhost:3030/ds/spek> {
    ?candi slowmo:acceptable_by ?path .
  }
}
USING <http://localhost:3030/ds/spek>
USING <http://localhost:3030/ds/seeps>
WHERE {
  ?candi a cpo:cpo_0000053 .
  ?path a cpo:causal_pathway .
  
  FILTER NOT EXISTS {
    ?path cpo:has_prerequisite ?attr .
    FILTER NOT EXISTS {
      ?candi obo:RO_0000091|slowmo:uses_intervention_property ?attr .
    }
  }
}
USPARQL

# Read from SPEK_FILE or pipe from stdin
#   Use '-' to instruct curl to read from stdin
if [[ -z ${SPEK_FILE} ]]; then
  SPEK_FILE="-"
fi

curl --silent -X PUT --data-binary "@${SPEK_FILE}" \
  --header 'Content-type: application/ld+json' \
  'http://localhost:3030/ds?graph=spek'

# Load in causal pathways
curl --silent -X PUT --data-binary @${CP_FILE} \
  --header 'Content-type: application/ld+json' \
  'http://localhost:3030/ds?graph=seeps'

# run update sparql
curl --silent -X POST --data-binary "${UPD_SPARQL}" \
  --header 'Content-type: application/sparql-update' \
  'http://localhost:3030/ds/update'

# get updated spek
curl --silent -X GET --header 'Accept: application/ld+json' \
  'http://localhost:3030/ds?graph=spek'
  

# done

