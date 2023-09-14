# All By My Host

This is a set of notes about building my own infrastructure inside a single host, using VMs.

The requirements is a precondition for making exercise to acquire CKA, CKAD, CKS, or whatever, without using AWS, GCP, Azure, DigitalOcean, OVH, VMware or whaterver.

It is also a way to experiment and get used to network topology design.


## Objective

* install 5 images of ubuntu
* install a loadbalancer
* define some kind of network and a unique entry point (implement isolation)
* test network inside the crowd
* test the network outside
* try various network driver

## Tools

Command line tools are those provided by Ubuntu distros (and other), because I start this project from my own host

The name "all by my host" is due to my personal condition of doing staff without any support.

* virsh is a tool to manage libvirtd running VMs
* qemu-kvm (or simply KVM) is the virtualization subsystem provided by linux kernel
* libvirt is the API provided for define/run/access/control the VMs


## Installing an Ubuntu from a network install

Using virt-install is possible to install an Ubuntu system. This command:

> virt-install --connect qemu:///system --name ubuntu-guest --os-variant ubuntu20.04 --vcpus 2 --ram 2048 --location http://ftp.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/ --network bridge=virbr0,model=virtio --graphics none --extra-args='console=ttyS0,115200n8 serial' --disk path=/home/daniele/ubuntu22.qcow2,size=4,format=qcow2

will do it.

After a number of installation questions (and my answer, and my time), the installation ended. But the machine hang.
There is just a blank screen and I can not log into the new VM.

I decide to use images provided upstream.

https://cloud-images.ubuntu.com/jammy/current/

this is a good starting point.

Well, really on manpage of virt-install it is said:

```
       path   A path to some storage media to use, existing or not. Existing media can be a file or block device.

              Specifying  a non-existent path implies attempting to create the new storage, and will require specifying a 'size' value. Even for remote hosts, virt-install will try to use libvirt
              storage APIs to automatically create the given path.

              If the hypervisor supports it, path can also be a network URL, like https://example.com/some-disk.img . For network paths, they hypervisor will directly access the storage,  nothing
              is downloaded locally.
```

> virt-install --connect qemu:///system --name ubuntu-guest0 --os-variant ubuntu20.04 --vcpus 2 --ram 2048 --import --network bridge=virbr0,model=virtio --graphics none --disk path=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img,size=4,format=qcow2

should work. But it does not. In fact that is an "installation"(`--os-variant ubuntu20.04`). Maybe I will go back to this. Now:

> wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

and I use `--import`

> sudo virt-install --connect qemu:///system --import --name ubuntu-g1 --memory 2048 --osinfo ubuntu23.04 --graphics none --disk /home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.img


It is difficult to find the password, https://askubuntu.com/questions/451673/default-username-password-for-ubuntu-cloud-image

> sudo apt install libguestfs-tools

(The list of tools are in https://www.libguestfs.org/)

**NOTE**: there is also an ubuntu package `cloud-image-utils`, but I see in the repo: https://git.launchpad.net/cloud-utils/tree/bin it is more limited, at least it has less commands.

It is possible to use guestmount(1) (and `virt-filesystems -d ubuntu-g1` to list mounted fs), but I just want to change password:

> virt-customize -a bionic-server-cloudimg-amd64.img --root-password password:<pass>

Paying attention to this in manpage:

```
WARNING
       Using "virt-customize" on live virtual machines, or concurrently with other disk editing tools, can be dangerous, potentially causing disk corruption.  The virtual machine must be shut
       down before you use this command, and disk images must not be edited concurrently.
```

so `virsh shutdown ubuntu-g1` first. Unfortunately, this removed the virtual machine:

```
$ virsh list --all
 Id   Name   State
--------------------

```

Ouop! it's gone. Going back to import. Now I directly add the bridge staff, I planned to test without it, but ... come on.

> sudo virt-install --connect qemu:///system --import --name ubuntu-g1 --memory 2048 --osinfo ubuntu23.04 --network bridge=virbr0,model=virtio --graphics none --disk /home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.img

~~~
ubuntu login: root
Password: 
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-82-generic x86_64)
...

root@ubuntu:~# ping 8.8.8.8
ping: connect: Network is unreachable
root@ubuntu:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 52:54:00:3f:4b:aa brd ff:ff:ff:ff:ff:ff
~~~

I am in. And it is indeed a good starting point. Network is "unreachable" but the interface exists.

Apperently nobody configured it.

Maybe it is time to clone it, before I assign an ip address that can not be the same for all VMs I am going to use.

```
$ virsh vol-clone `pwd`/jammy-server-cloudimg-amd64.img jammy2
error: Failed to clone vol from jammy-server-cloudimg-amd64.img
error: internal error: Child process (/usr/bin/qemu-img convert -f qcow2 -O qcow2 -o compat=0.10,cluster_size=65536 /home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.img /home/daniele/Development/all-by-my-host/jammy2) unexpected exit status 1: qemu-img: Could not open '/home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.img': Failed to get shared "write" lock
Is another process using the image [/home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.img]?
```

Yes, machine is running. It sounds good. I just need to check if I am able to access it by console, just to be sure that I can work then on configuring network on the cloned images.

But lets see what I have in a ubuntu image:
```
root@ubuntu:~# grep ubuntu /etc/passwd
root@ubuntu:~# 
```

almost nothing. Maybe I selected the wrong image, "cloud" flavour is small (really, not so small).

I download some more image, just for convenience:

> https://cloud.debian.org/images/cloud/

the `genericcloud` flavor is said to be smaller and generic.

> wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

> wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.qcow2

(I am picking up this arm64, I have some idea to use it also)

Going back. `Ctrl-]` to close console, then

> virsh console ubuntu-g1

and again I am in. `console` is not very confortable to work with, but I use it just to install network and ssh.

Now, if I am going to do some network administration task, it would be good to setup an automatic network ip assignment
via DHCP, and things like that. But this would bring me far from the objective to acquire a CKA certification.

So the plan is:

1. configure the network staff for the first image
2. clone the image with `virsh vol-clone` (5 times)
3. edit each of those image using `guestmount(1)` (and probably replacing some string into some /etc/-blah-blah-path)



## Network types

First of all, the funny staff.

> virsh net-edit --network default

is a convenient way to edit the `default`-named network (or any other name other than "default" that is defined).

This similar to `kubectl edit ...`  class of commands, but here the definition is in XML.