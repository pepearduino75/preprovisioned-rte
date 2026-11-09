kubectl create secret generic ${SSH_PRIVATE_KEY_SECRET_NAME} \ 
--from-file=ssh-privatekey=${SSH_PRIVATE_KEY_FILE}

kubectl label secret ${SSH_PRIVATE_KEY_SECRET_NAME} clusterctl.cluster.x-k8s.io/move=