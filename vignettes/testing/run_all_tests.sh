#!/usr/bin/env bash
COL_WIDTH=30
COL_WIDTH=30
KNOWLEDGE_BASE_DIR="${DISPLAY_LAB_HOME}/vert-ramp-affirmation/vignettes/test"
TEST_DATA_DIR="test_data"
OUTPUT_DIR=test_outputs
LOG_FILE=test_log.txt
VR_SCRIPTS_DIR="${DISPLAY_LAB_HOME}/vert-ramp-affirmation/scripts"

# CHeck for data and knowledge base overrides
PARAMS=()
while (("$#")); do
  case "$1" in
  -x | --debug)
    DEBUG_MODE="TRUE"
    shift 1
    ;;
  esac
done

# Create ${OUTPUT_DIR} directory
mkdir -p ${OUTPUT_DIR}

#run pfp on each csv file in the TEST_DATA_DIR directory, and output speks / logs
for file in ${TEST_DATA_DIR}/*.csv; do
  directory_name=$(dirname "${file}")
  test_name=$(basename "${file}")
  $KNOWLEDGE_BASE_DIR/pfp_e2e_test.sh \
    -k ${KNOWLEDGE_BASE_DIR} \
    -d ${directory_name} \
    -f ${test_name} \
    -o ${OUTPUT_DIR} \
    -l ${LOG_FILE} \
    -x
done
