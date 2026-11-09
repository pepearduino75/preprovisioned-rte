
helm repo add nutanix-helm https://nutanix.github.io/helm-releases
helm repo update

helm install nutanix-csi-snapshot nutanix-helm/nutanix-csi-snapshot \
  --namespace ntnx-system \
  --create-namespace


helm install nutanix-storage nutanix-helm/nutanix-csi-storage \
  --version 3.9.0 \
  --namespace ntnx-system \
  --create-namespace \
  --set createPrismCentralSecret=false \
  --set pcSecretName=ntnx-pc-secret \
  --set authType=basic-auth \
  --set createSecret=false \
  --set kubeletDir="/var/lib/kubelet" \
  --set kubernetesClusterDeploymentType="bare-metal" \
  --set ntnxInitConfigMap.usePC=true \
  --set ntnxInitConfigMap.associateCategoriesToVolume=false \
  --set createVolumeSnapshotClass=true \
  --wait \
  --set node.port=9828 \
  --timeout 10m
