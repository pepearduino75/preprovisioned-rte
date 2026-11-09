nkp create cluster preprovisioned --cluster-name ${CLUSTER_NAME} \
  --control-plane-endpoint-host 10.68.42.30 \
  --pre-provisioned-inventory-file preprovisioned_inventory.yaml \
  --ssh-private-key-file /home/mansolo/.ssh/nkp-bastion \
  --registry-mirror-url=${REGISTRY_URL} \
  --registry-mirror-cacert=${REGISTRY_CA} \
  --registry-mirror-username=${REGISTRY_USERNAME} \
  --registry-mirror-password=${REGISTRY_PASSWORD} \
  --virtual-ip-interface ens33