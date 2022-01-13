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
HEREDOC

# From Chris Down https://gist.github.com/cdown/1163649
urlencode() {
  old_lc_collate=$LC_COLLATE
  LC_COLLATE=C
  local length="${#1}"
  for ((i = 0; i < length; i++)); do
    local c="${1:$i:1}"
    case $c in
    [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
    *) printf '%%%02X' "'$c" ;;
    esac
  done
  LC_COLLATE=$old_lc_collate
}

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

# Check if FUSEKI is running.
FUSEKI_PING=$(curl -s -o /dev/null -w "%{http_code}" localhost:3030/$/ping)
if [[ -z ${FUSEKI_PING}} || ${FUSEKI_PING} -ne 200 ]]; then
  # Error
  echo >&2 "Fuseki not running locally."

  # Try to start custom fuseki locally
  ${FUSEKI_HOME}/fuseki-server --mem --update /ds 1>fuseki.out 2>&1 &
  read -p "Waiting five secs for Fuseki to start..." -t 5
fi

# SPARQL Queries for updates
read -r -d '' UPD_SPARQL <<'USPARQL'
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX slowmo: <http://example.com/slowmo#>

INSERT {
  GRAPH <http://localhost:3030/ds/spek> {
    ?candi slowmo:acceptable_by ?path .
  }
}
USING <http://localhost:3030/ds/spek>
USING <http://localhost:3030/ds/seeps>
WHERE {
  ?path a obo:cpo_0000029 .
  ?candi a obo:cpo_0000053 .

  FILTER NOT EXISTS {
    ?path slowmo:HasPrecondition ?attr .
    ?attr a ?atype .
    FILTER NOT EXISTS {
      ?candi obo:RO_0000091 ?disp .
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

  FUSEKI_DATASET_URL="http://localhost:3030/ds"
  SPEK_URL="${FUSEKI_DATASET_URL}/spek"
  ENCODED_SPEK_URL=$(urlencode "${SPEK_URL}")
  CAUSAL_PATHWAYS_URL="${FUSEKI_DATASET_URL}/seeps"
  ENCODED_CAUSAL_PATHWAYS_URL=$(urlencode "${CAUSAL_PATHWAYS_URL}")

  # Load in spek
  curl --silent -X PUT --data-binary "@${SPEK_FILE}" \
    --header 'Content-type: application/ld+json' \
    "${FUSEKI_DATASET_URL}?graph=${ENCODED_SPEK_URL}" >&2

  # Load in causal pathways
  curl --silent -X PUT --data-binary @${CP_FILE} \
    --header 'Content-type: application/ld+json' \
    "${FUSEKI_DATASET_URL}?graph=${ENCODED_CAUSAL_PATHWAYS_URL}" >&2

# run update sparql
curl --silent -X POST --data-binary "${UPD_SPARQL}" \
  --header 'Content-type: application/sparql-update' \
  "${FUSEKI_DATASET_URL}/update" >&2

# get updated spek and emit to stdout.
  curl --silent -G --header 'Accept: application/ld+json' \
    --data-urlencode "graph=${SPEK_URL}" \
    "${FUSEKI_DATASET_URL}"
