nkp upload image-artifacts \
  --ssh-host "${CONTROL_PLANE_1_ADDRESS},${CONTROL_PLANE_2_ADDRESS},${CONTROL_PLANE_3_ADDRESS},${WORKER_1_ADDRESS},${WORKER_2_ADDRESS},${WORKER_3_ADDRESS},${WORKER_4_ADDRESS}," \
  --ssh-username "${SSH_USER}" \
  --ssh-private-key-file="${SSH_PRIVATE_KEY_FILE}" \
  --artifacts-directory "${ARTIFACTS_DIRECTORY}" \
  --provider="${PROVIDER}"