#!/bin/bash
# Create single node cluster

# Get settings from the file
source settings

# Set cloud project
gcloud config set project ${PROJECT}

echo "Creating server:"
gcloud compute instances create ${SERVER} \
  --zone ${ZONE} \
  --image-family ubuntu-1704 \
  --image-project ubuntu-os-cloud \
  --boot-disk-type ${DISK_TYPE} \
  --boot-disk-size ${DISK_SIZE} \
  --machine-type ${MACHINE_TYPE} \
  --metadata kubernetes-version=${K8S_VERSION} \
  --metadata-from-file=startup-script=startup.sh \
  --can-ip-forward \
  --tags ${SERVER} \
  --scopes cloud-platform,logging-write,compute-rw \
  --preemptible
echo

echo "Waiting for ${SERVER} to be ready..."
spin='-\|/'
a=1
until gcloud compute instances describe --zone ${ZONE} ${SERVER} | grep "RUNNING" >/dev/null 2>&1; do a=$(( (a+1) %4 )); printf "\r${spin:$a:1}"; sleep .1; done
echo

echo "Enable secure remote access to the Kubernetes API server:"
gcloud compute firewall-rules create default-allow-${SERVER} \
  --allow tcp:6443 \
  --target-tags ${SERVER} \
  --source-ranges 0.0.0.0/0
echo

echo "It may take a few minutes for the cluster to finish bootstrapping and the client config to become readable."
echo "So we sleep for a few minutes"
sleep 120
echo

echo "Fetch the client kubernetes configuration file:"
gcloud compute scp --zone ${ZONE} ${SERVER}:/etc/kubernetes/admin.conf \
  ${SERVER}.conf
echo

echo "Set the ${SERVER} kubeconfig server address to the public IP address:"
kubectl config set-cluster kubernetes \
  --kubeconfig ${SERVER}.conf \
  --server https://$(gcloud compute instances describe --zone ${ZONE} ${SERVER} \
     --format='value(networkInterfaces.accessConfigs[0].natIP)'):6443
echo

echo "Verification"
echo "List the Kubernetes nodes:"
kubectl get nodes --kubeconfig ${SERVER}.conf
echo

echo "Create a nginx deployment:"
kubectl run nginx --image nginx:1.13 --port 80 \
  --kubeconfig ${SERVER}.conf
echo

echo "Expose the nginx deployment:"
kubectl expose deployment nginx \
  --type LoadBalancer \
  --kubeconfig ${SERVER}.conf
echo

echo "Done !!!"
