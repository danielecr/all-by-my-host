# Kubernetes exercizes

Finally I get 3 machines each with an ethernet interface and ip address up:

- unode1 192.168.122.31
- unode2 192.168.122.32
- unode3 192.168.122.33

(I will explore more on)

## On each VM

First, the signing and retrieve tools

> sudo apt-get install -y apt-transport-https ca-certificates curl

Then, 1. sign the remote k8s key (and store it in `/etc/apt/keyrings/kubernetes-apt-keyring.gpg`)

> curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

And 2. create a source list in /etc/apt/sources.list.d/

> echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

Update

> sudo apt update

Install:

> sudo apt install kubelet cri-tools kubernetes-cni conntrack ebtables socat

## Before start

Most of these scripts comes from https://github.com/sandervanvugt/cka/ and from kubernetes.io
But specific for Ubuntu I just add/change comment for convenience.

see `k8s-scripts/setup-cri.sh` Container Runtime Infastructure, setup containerd
see `k8s-scripts/setup-kubetools.sh` kubeadm kubelet kubectl

* kubeadm talk to containerd via crictl: crictl must know where is the containerd socket
* kubeadm provide a number of action, but I use just `init` on control plane and `join` on workers
* kubelet is the service that starts pod, it is "the node agent"
* kubectl communicate with kubenetes API for defining pods, and other objects

I ignore this
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/

I tried:
> kubeadm config print init-defaults

```sh
...
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: node
  taints: null
```

and it is enough since containerd use systemd cgroup driver.

### resize vm partition

> virsh domblklist unode2
> sudo qemu-img info /home/daniele/Development/all-by-my-host/running_img/lunar-unode2.img

> sudo qemu-img resize /home/daniele/Development/all-by-my-host/running_img/lunar-unode2.img +4G

in the guest

> sudo fdisk /dev/vda ... delete, new, save, ... then
> sudo resize2fs /dev/vda1


### on control plane

About kubeadm, I specify the advertise address because I have 2 interfaces in the controlplane
(I should have 2 interfaces somewhere else, but ...)

> kubeadm init --apiserver-advertise-address 192.168.122.31

> kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

next calico version

> kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml

copy `.kube/config`

> sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
> cp $HOME/.kube/config kubeconfig.yaml

#### On workers

first move that kubeconfig.yaml into each node:

> scp unode1:/home/ubuntu/.kube/config kubeconfig.yaml
> scp kubeconfig.yaml unode2:/home/ubuntu/.kube/config
> scp kubeconfig.yaml unode3:/home/ubuntu/.kube/config

(deal with `/home/ubuntu/.kube` no such directory by creating that on unode2 and unode3, then repeat)

> kubeadm join 192.168.122.31:6443 --token 8dyeoi.dyoerhdfhf936tkf --discovery-token-ca-cert-hash sha256:d60ad9d5f25574427b34d68160342953d4c17371a9ad7e80db1d5a6a55a44e8b

Anyway toke has a TTL of 24h, so the list of active token can be taken by

> kubeadm token list

and the hash can me created by:

> openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

Or, if `kubeadmn token list` is void:

> kubeadm token create --print-join-command

Interesting enough, kubeadm open the same ~/.kube/config

> $ strace -e trace=open,creat,openat,openat2,name_to_handle_at -o trace.log kubeadm token list
> $ less trace.log
...
> openat(AT_FDCWD, "/home/ubuntu/.kube/config", O_RDONLY|O_CLOEXEC) = 3

and on all nodes it is the same `server: https://192.168.122.31:6443`, but why calling `join` does something else?

## To understand (missing)

To better understand

* **pause image** or "sandbox image", is used when starting pod to setup something: setup what?
* pod is said to communicate via TCP PORT redirect, it does not have a full ip address. How does it works?

### Security and Firewall

<https://devopstales.github.io/kubernetes/k8s-security/>