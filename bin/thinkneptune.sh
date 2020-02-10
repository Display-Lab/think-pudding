#!/usr/bin/env bash

# Usage message
read -r -d '' USE_MSG <<'HEREDOC'
Usage:
  thinkneptune.sh
  thinkneptune.sh --end-point http://example.com --port 8182
  thinkneptune.sh -h

This assumes a nebula cluster running and loaded.
Expects the following ENV vars availalble:

END_POINT      #Endpoint of neptune cluster
PORT           #Listening port of neptune cluster (8182)
SPEK_GPH_IRI   #Base IRI for spek graph 
CAUSAL_GPH_IRI #Base IRI for causal pathways graph
HEREDOC

while (( "$#" )); do
  case "$1" in
    -p|--port)
      PORT="${2}"
      shift
      shift
      ;;
    -e|--end-point)
      END_POINT="${2}"
      shift 
      shift
      ;;
    -h|--help)
      echo "${USE_MSG}"
      exit 0
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


# Check for missing neptune endpoint
if [[ -z ${END_POINT} ]]; then
  echo >&2 "Neptune endpoing not in env."; 
  exit 1;
fi

# Default to 8182 port
PORT=${PORT:-8182}

read -r -d '' UPD_SPARQL <<UPDSPARQL
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX slowmo: <http://example.com/slowmo#>

INSERT {
  GRAPH <http://example.com/spek> {
    ?candi slowmo:acceptable_by ?path .
  }
}
USING <http://example.com/spek>
USING <http://example.com/seeps>
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
UPDSPARQL

# Trim the endlines off the query to accomodate Neptune's HTTP bullshit
QUERY=${UPD_SPARQL//$'\n'/}

curl -X POST --data-binary "update=${QUERY}" "${END_POINT}:${PORT}/sparql"

