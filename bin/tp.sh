#!/usr/bin/env bash

# Requires xmllint to be installed
command -v $FUSEKI_HOME/fuseki-server 1>/dev/null 2>&1 ||
  {
    echo >&2 "fuseki-server required but it's not installed.  Aborting."
    exit 1
  }

# Usage message
read -r -d '' USE_MSG <<'HEREDOC'
Usage:
  thinkpudding.sh -h
  thinkpudding.sh -p causal_pathway.json   
  thinkpudding.sh -s spek.json -p causal_pathway.json   

TP reads a spek from stdin or provided file path.  
Emits updated spek to stdout unless update-only is used.

Options:
  -h | --help     print help and exit
  -p | --pathways path to configuration file
  -s | --spek     path to spek file (default to stdin)
  -u | --update-only Load nothing. Run update query. 
  -l | --load-only Load spek and causal pathways but don't run update query. 
HEREDOC

# Parse args
PARAMS=()
while (("$#")); do
  case "$1" in
  -h | --help)
    echo "${USE_MSG}"
    exit 0
    ;;
  -p | --pathways)
    CP_FILE="${2}"
    shift 2
    ;;
  -s | --spek)
    SPEK_FILE="${2}"
    shift 2
    ;;
  -u | --update-only)
    UPDATE_ONLY="TRUE"
    shift 1
    ;;  
  -l | --loade-only)
    LOAD_ONLY="TRUE"
    shift 1
    ;;
  --) # end argument parsing
    shift
    break
    ;;
  -* | --*=) # unsupported flags
    echo "Aborting: Unsupported flag $1" >&2
    exit 1
    ;;
  *) # preserve positional arguments
    PARAMS+=("${1}")
    shift
    ;;
  esac
done

# Unless update only, require causal pathways
if [ -z ${UPDATE_ONLY} ]; then

  # Die if causal pathways file not given.
  if [[ -z ${CP_FILE} ]]; then
    echo >&2 "Causal pathway file required."
    exit 1
  fi

  # Die if causal pathways file not found.
  if [[ ! -r ${CP_FILE} ]]; then
    echo >&2 "Causal Pathway file not readable."
    exit 1
  fi
fi

# Check if FUSEKI is running.
FUSEKI_PING=$(curl -s -o /dev/null -w "%{http_code}" localhost:3030/$/ping)
if [[ -z ${FUSEKI_PING}} || ${FUSEKI_PING} -ne 200 ]]; then
  # Error
  echo >&2 "Fuseki not running locally."

  # Try to start custom fuseki locally, will temporarily create a run/ directory
  ${FUSEKI_HOME}/fuseki-server --mem --update /ds 1>fuseki.out 2>&1 &
  read -p "Waiting 5 seconds for Fuseki to start..." -t 5
fi

# SPARQL Queries for updates
read -r -d '' UPD_SPARQL <<'USPARQL'
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX slowmo: <http://example.com/slowmo#>

# INSERT {
#   GRAPH <http://localhost:3030/ds/spek> {
#     ?candidate slowmo:acceptable_by ?path .
#   }
# }
construct {
    ?candidate slowmo:acceptable_by ?path .
}
USING <http://localhost:3030/ds/spek>
USING <http://localhost:3030/ds/seeps>
WHERE {
  ?path a obo:cpo_0000029 .
  ?candidate a obo:cpo_0000053 .

  FILTER NOT EXISTS {
    ?path slowmo:HasPrecondition ?attr .
    ?attr a ?atype .
    FILTER NOT EXISTS {
      ?candidate obo:RO_0000091 ?disp .
      ?disp a ?atype
    }
  }
}
USPARQL

# Read from SPEK_FILE or pipe from stdin
#   Use '-' to instruct curl to read from stdin
if [[ -z ${SPEK_FILE} ]]; then
  SPEK_FILE="-"
fi

# Unless update only, load spek and causal pathways into fuseki.
if [ -z ${UPDATE_ONLY} ]; then

  FUSEKI_DATASET_URL="http://localhost:3030/ds"
  SPEK_URL="${FUSEKI_DATASET_URL}/spek"
  CAUSAL_PATHWAYS_URL="${FUSEKI_DATASET_URL}/seeps"

  # Load in spek
  curl --silent PUT \
    --data-binary "@${SPEK_FILE}" \
    --header 'Content-type: application/ld+json' \
    "${FUSEKI_DATASET_URL}?graph=${SPEK_URL}" >&2

  # Load in causal pathways
  curl --silent PUT \
    --data-binary @${CP_FILE} \
    --header 'Content-type: application/ld+json' \
      "${FUSEKI_DATASET_URL}?graph=${CAUSAL_PATHWAYS_URL}" >&2
fi

# Unless load only, run update and dump spek graph.
if [ -z ${LOAD_ONLY} ]; then
  # run update sparql
  curl --silent POST \
    --data-binary "${UPD_SPARQL}" \
    --header 'Content-type: application/sparql-update' \
    "${FUSEKI_DATASET_URL}/update" >&2

  # get updated spek and emit to stdout.
  curl --silent \
    --header 'Accept: application/ld+json' \
    "${FUSEKI_DATASET_URL}?graph=${SPEK_URL}"
fi