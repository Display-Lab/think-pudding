#!/usr/bin/env bash
# This is designed to be run from within a specific vignette's directory
#   Use verify script as a reminder of what this particular result should be.

##################################
# DEFINITIONS OF EXPECTED VALUES #
##################################
EXPECTED_FILE=outputs/spek_tp.json
FULL_CP="http://feedbacktailor.org/ftkb#SocialBetter"
FULL_TEMPLATE="http://feedbacktailor.org/ftkb#ReachedSocial"
SHORT_CP=$(echo "${FULL_CP}" | sed 's;http://feedbacktailor.org/ftkb#;;')
PERFORMER="Alice"

######################
# Verification logic #
######################

# Expect spek from think pudding to exist and not be empty.
if [[ -f "${EXPECTED_FILE}" ]]; then
  echo "${EXPECTED_FILE} exists"
else
  echo "${EXPECTED_FILE} missing"
  exit 1
fi

# Use jq as hacky search of output

echo "Expected candidate contents:"
cat << HEREDOC
  "@type" : "http://purl.obolibrary.org/obo/cpo_0000053",
  "AncestorPerformer" : "_:p${PERFORMER}",
  "AncestorTemplate" : "${FULL_TEMPLATE}",
  "acceptable_by" : "${FULL_CP}",
HEREDOC

echo -e "\nActual candidate:"

jq --arg PERF "_:p${PERFORMER}" \
  '."@graph"[] | select(.AncestorPerformer | . == $PERF)' \
  "${EXPECTED_FILE}"


# Specific test for expected candidate
RESULT=$(jq --arg CP "${SHORT_CP}" --arg PERF "_:p${PERFORMER}" \
            '."@graph"[] | 
            select(.AncestorPerformer | . == $PERF) | 
            select(.acceptable_by | contains($CP)) // [] | 
            length'\
    "${EXPECTED_FILE}"
)
RESULT=${RESULT:-0}

if [[ ${RESULT} != 0 ]]; then
  echo -e "\n✓ Candidate appears good."
else
  echo -e "\n✗ No candidate appears good."
fi

echo -e "\nExamine ${EXPECTED_FILE} for more details."
