#!/usr/bin/env bash
COL_WIDTH=30
COL_WIDTH=30
KNOWLEDGE_BASE_DIR="${DISPLAY_LAB_HOME}/vert-ramp-affirmation/"
OUTPUT_DIR=test_outputs
LOG_FILE=test_log.txt
VR_SCRIPTS_DIR="${DISPLAY_LAB_HOME}/vert-ramp-affirmation/scripts"

# CHeck for data and knowledge base overrides
PARAMS=()
while (("$#")); do
  case "$1" in
  -k | --knowledge)
    KNOWLEDGE_BASE_DIR="${2}"
    shift 2
    ;;
  -d | --data)
    PFP_DATA_DIR="${2}"
    shift 2
    ;;
  -f | --file)
    PFP_DATA_FILE="${2}"
    shift 2
    ;;
  -o | --output)
    OUTPUT_DIR="${2}"
    shift 2
    ;;
  -l | --log)
    LOG_FILE="${2}"
    shift 2
    ;;
  -x | --debug)
    DEBUG_MODE="TRUE"
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
  # Try to start custom fuseki locally, will temporarily create a run/ directory
  ${FUSEKI_HOME}/fuseki-server --mem --update /ds 1>fuseki.out 2>&1 &
  read -t 5
fi
printf "\nPFP E2E TEST: ${PFP_DATA_FILE} ************************************************\n" | tee -a ${LOG_FILE}

$DISPLAY_LAB_HOME/vert-ramp-affirmation/pfp.sh \
  -k ${KNOWLEDGE_BASE_DIR} \
  -f ${PFP_DATA_FILE} \
  -d ${PFP_DATA_DIR} \
  -o ${OUTPUT_DIR} \
  -l ${LOG_FILE} \
  -x

printf "\nBit Stomach Summary: " >>${LOG_FILE} 2>&1
$VR_SCRIPTS_DIR/summarize_graph.sh \
  -s ${OUTPUT_DIR}/spek_bs.json \
  >>${LOG_FILE} 2>&1
printf "\nCandidate Smasher Summary: " >>${LOG_FILE} 2>&1
$VR_SCRIPTS_DIR/summarize_graph.sh \
  -s ${OUTPUT_DIR}/spek_cs.json \
  >>${LOG_FILE} 2>&1
printf "\nThink Pudding Summary: " >>${LOG_FILE} 2>&1
$VR_SCRIPTS_DIR/summarize_graph.sh \
  -s ${OUTPUT_DIR}/spek_tp.json \
  >>${LOG_FILE} 2>&1
printf "\nEsteemer Summary: " >>${LOG_FILE} 2>&1
$VR_SCRIPTS_DIR/summarize_graph.sh \
  -s ${OUTPUT_DIR}/spek_es.json \
  >>${LOG_FILE} 2>&1

#Run cleanup if debug is not enabled
if [[ -z ${DEBUG_MODE} ]]; then
  ./test_cleanup.sh -o ${OUTPUT_DIR}
fi
