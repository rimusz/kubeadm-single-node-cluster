# kubeadm: Single Node Kubernetes Cluster

This tutorial will walk you through bootstrapping a single-node Kubernetes cluster on [Google Compute Engine](https://cloud.google.com/compute/) using [kubeadm](https://github.com/kubernetes/kubeadm).


## TL;DR

### Clone this project and set settings:
````
$ git clone https://github.com/rimusz/kubeadm-solo-cluster
$ cd kubeadm-solo-cluster
````
* Edit the `settings` file and set `PROJECT and ZONE`, the rest of settings in this file are probably fine, but can be adjusted if need be.

### Bootstrap the cluster
```
$ ./bootstrap_cluster.sh
```
This command will create a single node Kuberntes cluster.

### Cleanup
```
$ ./delete_cluster.sh
```
This command will delete single node Kuberntes cluster VM, firewall rule and `kubeadm-single-node-cluster.conf` file.


## Tutorial

Create a single compute instance:

```
gcloud compute instances create kubeadm-solo-cluster \
  --can-ip-forward \
  --image-family ubuntu-1704 \
  --image-project ubuntu-os-cloud \
  --machine-type n1-standard-4 \
  --metadata kubernetes-version=stable-1.7,startup-script-url=https://raw.githubusercontent.com/rimusz/kubeadm-solo-cluster/master/startup.sh \
  --tags kubeadm-solo-cluster \
  --scopes cloud-platform,logging-write
```

Enable secure remote access to the Kubernetes API server:

```
gcloud compute firewall-rules create default-allow-kubeadm-solo-cluster \
  --allow tcp:6443 \
  --target-tags kubeadm-solo-cluster \
  --source-ranges 0.0.0.0/0
```

Fetch the client kubernetes configuration file:

```
gcloud compute scp kubeadm-solo-cluster:/etc/kubernetes/admin.conf \
  kubeadm-solo-cluster.conf
```

> It may take a few minutes for the cluster to finish bootstrapping and the client config to become readable.

Set the `kubeadm-solo-cluster` kubeconfig server address to the public IP address:

```
kubectl config set-cluster kubernetes \
  --kubeconfig kubeadm-solo-cluster.conf \
  --server https://$(gcloud compute instances describe kubeadm-solo-cluster \
     --format='value(networkInterfaces.accessConfigs[0].natIP)'):6443
```

## Verification

List the Kubernetes nodes:

```
kubectl get nodes --kubeconfig kubeadm-solo-cluster.conf
```
```
NAME                          STATUS    AGE       VERSION
kubeadm-solo-cluster   Ready     14m       v1.7.0
```

Create a nginx deployment:

```
kubectl run nginx --image nginx:1.13 --port 80 \
  --kubeconfig kubeadm-solo-cluster.conf
```

Expose the nginx deployment:

```
kubectl expose deployment nginx \
  --type LoadBalancer \
  --kubeconfig kubeadm-solo-cluster.conf
```

## Cleanup

```
gcloud compute instances delete kubeadm-solo-cluster
```

```
gcloud compute firewall-rules delete default-allow-kubeadm-solo-cluster
```

```
rm kubeadm-solo-cluster.conf
```
