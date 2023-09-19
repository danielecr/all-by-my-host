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

### Safe guestmount/guestunmount

To be safe from race condition, so that the image can be used immediately after mount/change/unmount operation, I
follow the manpage directions and I write a bash script in `scripts/` folder.

In order to be confortable I change /etc/fuse.conf and uncomment `user_allow_other` line.

Ouop. That is

~~~
:~/Development/all-by-my-host$ ./scripts/gumount.sh debian-12-genericcloud-amd64.qcow2 mnt/
both exists
/home/daniele/Development/all-by-my-host/debian-12-genericcloud-amd64.qcow2
/home/daniele/Development/all-by-my-host/mnt/
:~/Development/all-by-my-host$ ls mnt/
bin  boot  dev  etc  home  lib  lib32  lib64  libx32  lost+found  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
:~/Development/all-by-my-host$ ls -l mnt/
total 76
lrwxrwxrwx  1 root root     7 set 10 06:39 bin -> usr/bin
drwxr-xr-x  4 root root  4096 set 10 06:42 boot
drwxr-xr-x  2 root root  4096 set 10 06:40 dev
drwxr-xr-x 64 root root  4096 set 10 06:42 etc
drwxr-xr-x  2 root root  4096 lug 14 18:00 home
lrwxrwxrwx  1 root root     7 set 10 06:39 lib -> usr/lib
lrwxrwxrwx  1 root root     9 set 10 06:39 lib32 -> usr/lib32
lrwxrwxrwx  1 root root     9 set 10 06:39 lib64 -> usr/lib64
lrwxrwxrwx  1 root root    10 set 10 06:39 libx32 -> usr/libx32
drwx------  2 root root 16384 set 10 06:39 lost+found
drwxr-xr-x  2 root root  4096 set 10 06:39 media
drwxr-xr-x  2 root root  4096 set 10 06:39 mnt
drwxr-xr-x  2 root root  4096 set 10 06:39 opt
drwxr-xr-x  2 root root  4096 lug 14 18:00 proc
drwx------  3 root root  4096 set 10 06:40 root
drwxr-xr-x  2 root root  4096 set 10 06:40 run
lrwxrwxrwx  1 root root     8 set 10 06:39 sbin -> usr/sbin
drwxr-xr-x  2 root root  4096 set 10 06:39 srv
drwxr-xr-x  2 root root  4096 lug 14 18:00 sys
drwxrwxrwt  2 root root  4096 set 10 06:41 tmp
drwxr-xr-x 14 root root  4096 set 10 06:39 usr
drwxr-xr-x 11 root root  4096 set 10 06:39 var
~~~

Check:

~~~
:~/Development/all-by-my-host$ ./scripts/gu-check.sh 
3024601 ?        Ss     0:00 guestmount -a debian-12-genericcloud-amd64.qcow2 -m /dev/sda1 --pid-file guestmount.pid -o allow_other mnt/
3025542 pts/16   S+     0:00 grep 3024601
~~~

and finally umount:

~~~
:~/Development/all-by-my-host$ ./scripts/g-umount.sh mnt/
:~/Development/all-by-my-host$ ./scripts/gu-check.sh 
3025930 pts/16   S+     0:00 grep 3024601
:~/Development/all-by-my-host$ ls -l mnt/
total 0
~~~

### A default user (and snapshots)

Now I have to configure a first image from which I am going to clone.
I want a non-privileged user, I name it `bymyself`, all VMs will have this name.

During the setup of an image is possible to adopt the strategy to make a progressive change history, I think there are tools around for this.

~~~
:~/Development/all-by-my-host$ virsh snapshot-create-as --domain ubuntu-g1 --disk-only --live before-adduser
error: Operation not supported: live snapshot creation is supported only during full system snapshots

:~/Development/all-by-my-host$ virsh snapshot-create-as --domain ubuntu-g1 --disk-only before-adduser
Domain snapshot before-adduser created

:~/Development/all-by-my-host$ virsh snapshot-dumpxml --domain ubuntu-g1 before-adduser | grep source.*before-adduser
      <source file='/home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.before-adduser'/>

:~/Development/all-by-my-host$ ls -l | grep jammy-server
-rw------- 1 libvirt-qemu kvm      11665408 set 15 07:50 jammy-server-cloudimg-amd64.before-adduser
-rw-rw-r-- 1 libvirt-qemu kvm     793903104 set 15 07:42 jammy-server-cloudimg-amd64.img
~~~

The snapshot is created in the same folder as the source image, but the user:group is libvirt-qemu:kvm, also I did not noticed it
before: libvirt take the qcow2 image ownership.

For convenience I write a `snapshot-new.sh` script and the relative complete `abmh_complete.sh` to get the list of available domain.

But surprisingly when I try to revert I found it does not work:

~~~
:~/Development/all-by-my-host$ virsh snapshot-revert --domain ubuntu-g1 --snapshotname before-adduser 
error: Failed to revert snapshot before-adduser
error: unsupported configuration: revert to external snapshot not supported yet
~~~

looking around I found https://virt.fedoraproject.narkive.com/SaNf9XFu/fedora-how-to-revert-an-external-snapshot

That is very strange. The suggestion look like, maybe:

```
# Create the external snapshot
virsh snapshot-create $dom --no-metadata --disk-only
# Copy the base image to bk-host, for an appropriate $copy
"$copy" host... bk-host...
# Commit the temporary qcow2 snapshot wrapper back into the main disk
foreach disk in $dom:
virsh blockcommit $dom $disk --active --shallow --verbose --pivot
```

If I look at xml (by editing) I found:

```
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.secondo-primo'/>
      <backingStore type='file'>
        <format type='qcow2'/>
        <source file='/home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.second-before'/>
        <backingStore type='file'>
          <format type='qcow2'/>
          <source file='/home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.before-adduser'/>
          <backingStore type='file'>
            <format type='qcow2'/>
            <source file='/home/daniele/Development/all-by-my-host/jammy-server-cloudimg-amd64.img'/>
          </backingStore>
        </backingStore>
      </backingStore>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </disk>
```

That make sense, because qcow2 is an overlayed storage, but how to deal with it?

And that is maybe where `virsh blockcommit` plays its role. Anyway it is getting too complicated for the focus of this project.

```
virsh domfsfreeze $dom
virsh snapshot-create $dom --no-metadata --disk-only
virsh domfsthaw $dom
"$copy" host... bk-host...
```

This look a more effective advice, it imply there is a freeze and a matching thaw operation. Looking around (in manpage) there is a snapshot option, `--quiesce`, that does both operation before and after taking a snapshot. But it requires QEMU Guest Agent.

This goes away from my focus, but it look interesting, so I search for such a staff, I think it is easily supported by ubuntu cloud image, I hope so. Actually doc is from redhat https://access.redhat.com/solutions/732773

Apparently I have `apt-cache show qemu-guest-agent` on host machine, but not in the the cloud image.

I have to wait until I settled up the network staff. Anyway looking at xml is interesting.

The format is documented in libvirt.org website, and this https://libvirt.org/formatdomain.html#network-interfaces is
the section for network. I want to understand all supported options for network, and this is on-topic for this project

The first thing I notice is

```
<interface type='bridge'>
  <mac address='52:54:00:3f:4b:aa'/>
  <source bridge='virbr0'/>
  <model type='virtio'/>
  <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
</interface>
```

the option I used 2 days ago, `--network bridge=virbr0,model=virtio` has this kind of xml counter part.
I do not know what had choosen the mac address, but that is what I see in the guest machine.

So simply bringing up my interface will enable the network access (like if I am in the host: isn't it just a "bridge"?)

I just pass 15 minutes of madness trying to guess why, and what, and how, and why ... thing are ... then I end up trying to dumpxml of net by virsh:

```
:~/Development/all-by-my-host$ virsh net-dumpxml --network default 
<network>
  <name>default</name>
  <uuid>2b68002e-57eb-4ebc-9755-dd502b18118a</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:9e:9f:ce'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

and this is completely arbitrary, I think libvirt take the first available ip for its virbr0 interface, but I could get this from

```
:~/Development/all-by-my-host$ ip a show dev virbr0 
4: virbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 52:54:00:9e:9f:ce brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever
```

So, in the guest:
```
root@ubuntu:~# ip link set enp1s0 up
root@ubuntu:~# ip addr add 192.168.122.2/24 dev enp1s0
root@ubuntu:~# ip route add default via 192.168.122.1
```

And I have network.

```
apt update
```

... but no dns. It is suggested to edit this file

> root@ubuntu:~# vi /etc/systemd/resolved.conf

but really nothing change, until

> root@ubuntu:~# systemctl restart systemd-resolved.service

and in fact /etc/resolv.conf contains 127.0.0.53, that is the way systemd-resolved receive message from nss-resolve.

Ok, ns resolution is a bit off-topic, but nice to know.

Anyway, I need to calm me down and take my time: networking staff is exactly the skill I want to strengthen.

All these step on an awfull console, I want ssh, and

> root@ubuntu:~# journalctl --unit ssh.service

continuously complains about "sshd: no hostkeys available -- exiting". Just googled and

> root@ubuntu:~# ssh-keygen -A

But security conf of sshd is ... good as it is. So it is better I wait until I have a unprivileged user (I am lying here, I temporary broken the guest machine for loging as root via ssh)

The **qemu-guest-agent**:

```
root@ubuntu:~# apt install qemu-guest-agent
root@ubuntu:~# systemctl start qemu-guest-agent.service
```

talking from the host:

```
:~/Development/all-by-my-host$ virsh qemu-agent-command --domain ubuntu-g1 '{"execute":"guest-info"}'
{"return":{"version":"6.2.0","supported_commands":[{"enabled":true,"name":"guest-ssh-remove-authorized-keys","success-response":true},{"enabled":true,"name":"guest-ssh-add-authorized-keys","success-response":true},{"enabled":true,"name":"guest-ssh-get-authorized-keys","success-response":true},{"enabled":false,"name":"guest-get-devices","success-response":true},{"enabled":true,"name":"guest-get-osinfo","success-response":true},{"enabled":true,"name":"guest-get-timezone","success-response":true},{"enabled":true,"name":"guest-get-users","success-response":true},{"enabled":true,"name":"guest-get-host-name","success-response":true},{"enabled":true,"name":"guest-exec","success-response":true},{"enabled":true,"name":"guest-exec-status","success-response":true},{"enabled":true,"name":"guest-get-memory-block-info","success-response":true},{"enabled":true,"name":"guest-set-memory-blocks","success-response":true},{"enabled":true,"name":"guest-get-memory-blocks","success-response":true},{"enabled":true,"name":"guest-set-user-password","success-response":true},{"enabled":true,"name":"guest-get-fsinfo","success-response":true},{"enabled":true,"name":"guest-get-disks","success-response":true},{"enabled":true,"name":"guest-set-vcpus","success-response":true},{"enabled":true,"name":"guest-get-vcpus","success-response":true},{"enabled":true,"name":"guest-network-get-interfaces","success-response":true},{"enabled":true,"name":"guest-suspend-hybrid","success-response":false},{"enabled":true,"name":"guest-suspend-ram","success-response":false},{"enabled":true,"name":"guest-suspend-disk","success-response":false},{"enabled":true,"name":"guest-fstrim","success-response":true},{"enabled":true,"name":"guest-fsfreeze-thaw","success-response":true},{"enabled":true,"name":"guest-fsfreeze-freeze-list","success-response":true},{"enabled":true,"name":"guest-fsfreeze-freeze","success-response":true},{"enabled":true,"name":"guest-fsfreeze-status","success-response":true},{"enabled":true,"name":"guest-file-flush","success-response":true},{"enabled":true,"name":"guest-file-seek","success-response":true},{"enabled":true,"name":"guest-file-write","success-response":true},{"enabled":true,"name":"guest-file-read","success-response":true},{"enabled":true,"name":"guest-file-close","success-response":true},{"enabled":true,"name":"guest-file-open","success-response":true},{"enabled":true,"name":"guest-shutdown","success-response":false},{"enabled":true,"name":"guest-info","success-response":true},{"enabled":true,"name":"guest-set-time","success-response":true},{"enabled":true,"name":"guest-get-time","success-response":true},{"enabled":true,"name":"guest-ping","success-response":true},{"enabled":true,"name":"guest-sync","success-response":true},{"enabled":true,"name":"guest-sync-delimited","success-response":true}]}}
```

and this means it works. So I eventually I can do an effective and usable snapshot. I hope so.

#### Backup

yes, now I can run with --quiesce, but I do not understand what can I do for restore.
I check upstream docs https://libvirt.org/formatbackup.html, it talks about checkpoint, and virsh deals that object too.
But with checkpoint and with backup-begin, still I do not know how to revert!!

I left this dilemma behind me. I go on without snapshotting

#### User

> root@ubuntu:~# adduser bymyself

`bymyself` is the default user with a default password `bymyself`, it has uid 1000 and gid 1000

(bymyself is an horrible name, I know, whenever I will automate this task I need to pick another user name)

### More on network

I am used to NetworkManager, because I am a mostly a desktop user, but in the guest machine:

```
root@ubuntu:~# systemctl status systemd-networkd.service 
● systemd-networkd.service - Network Configuration
     Loaded: loaded (/lib/systemd/system/systemd-networkd.service; enabled; ven>
     Active: active (running) since Fri 2023-09-15 09:26:24 UTC; 46min ago
```

So, this is supposed to work fine with netplan. Netplan config should be something like this:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: no
```

as a yaml file in `/etc/netplan/` folder. The manpage netplan(5) covers a lot of infos.

The `virsh net-dumpxml --network default` command says that the bridge default network has DHCP and distributes
IP to all attached interface, from 2, up to 254. So I can just left this with `dhcp4: yes` and every machine will
have a diffent ip, assigned in order of appeareance. But this is a problem when I am going to ssh: where?

In fact the `bridge` staff hidden what is behind the virbr0 network, or this is what I see from `ip` utility.

Anyway, in the guest image I put this file:

```yaml
## root@ubuntu:~# cat /etc/netplan/0-network.yaml 
network:
  version: 2
  renderer: networkd
  ethernets:
   enp1s0:
    routes:
      - to: default
        via: 192.168.122.1
    addresses: [192.168.122.2/24]
    dhcp4: no
    nameservers:
      addresses: [ 8.8.8.8 ]
```

then wherever I create a new image I just replace this (expecting that networkd would make the magic).

#### A Friday retrospective (2023-09-15)

I think I am a day later, but I gained some knowledge about bridge staff, that is far more complicated than 'a simple bridge' as I was used to think.

~~Now I immagine a bridge like a box with a number of feature, like spanning tree protocol, dhcp, port forwarding, nat, ... all in a box called 'bridge', it is like a bridge with autogrills here and there.~~
`libvirt` packs the network interface definition, including the bridge name, ip address space, ip address of a router, dhcp service running in a (virtual) router, bandwidth, etc.

A `bridge` is just a tap interface. `tap` is layer 2 (ethernet trafic), while `tun` is layer 3 (ip trafic).

Also there is that netplan staff that is interesting, I always relayed on network manager and I did not know about systemd networkd staff, that replace it, and I think now it the time for NetworkManager to be discontinued altogher.

That libvirt backup/snapshot/checkpoint staff is still stocked as a mess in my mind, but everything in libvirt talk xml,
and it is well documented in the official website.

`virsh` has a lot of staff, most of the time (every time?) 'edit' 'xmldump' is available for object handled by virsh.

I must not forget to mention that qemu-guest-agent, from the package description:

```
 This package provides a daemon (agent) to run inside qemu-system
 guests (full system emulation).  It communicates with the host using
 a virtio-serial channel org.qemu.guest_agent.0, and allows one to perform
 some functions in the guest from the host, including:
  - querying and setting guest system time
  - performing guest filesystem sync operation
  - initiating guest shutdown or suspend to ram
  - accessing guest files
  - freezing/thawing guest filesystem operations
  - others.
```

for sure there is:

```
:~/Development/all-by-my-host$ virsh qemu-agent-command --domain ubuntu-g1 '{"execute":"guest-network-get-interfaces"}'
{"return":[{"name":"lo","ip-addresses":[{"ip-address-type":"ipv4","ip-address":"127.0.0.1","prefix":8},{"ip-address-type":"ipv6","ip-address":"::1","prefix":128}],"statistics":{"tx-packets":9408,"tx-errs":0,"rx-bytes":677438,"rx-dropped":0,"rx-packets":9408,"rx-errs":0,"tx-bytes":677438,"tx-dropped":0},"hardware-address":"00:00:00:00:00:00"},{"name":"enp1s0","ip-addresses":[{"ip-address-type":"ipv4","ip-address":"192.168.122.2","prefix":24},{"ip-address-type":"ipv6","ip-address":"fe80::5054:ff:fe3f:4baa","prefix":64}],"statistics":{"tx-packets":12242,"tx-errs":0,"rx-bytes":29714568,"rx-dropped":5791,"rx-packets":27919,"rx-errs":0,"tx-bytes":1488765,"tx-dropped":0},"hardware-address":"52:54:00:3f:4b:aa"}]}
```

also:

```
:~/Development/all-by-my-host$ virsh qemu-agent-command --domain ubuntu-g1 '{"execute":"guest-ssh-get-authorized-keys","arguments":{"username":"root"}}'
{"return":{"keys":["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCT7uZ3E3giGIj6uf7ooyUUqS+VGUXNHga/mbpSmJ3un/UyhCAqWzCceheM/pWi1Q5EIp9n1CIy6yv299W9ReMsXSAeNjzJ7caMhYME7DSZXwrRfv3BWA/TcMfbiFOhrMCHfnt8mc3od9omhVyLTmaTqRhKGIVNg+JarBm6IUCMYY5ZB+wSB+byCE7Rwp5lKkTtej6ZFRB+nitjIPGEOVOXgkrtLXTxv3wlZXynazwJCSQlKUOuaJ4/ht4tqzAfzbHoBphFKz1TlgRCbWyNa4w7294+ex6GJ7+OhaPiXx2rReYk0Mqf6cjFEpspIlN4j2bC9Z/X7inyxmI0JViiEJ1 daniele@smartango.com"]}}
```

But I can not setup the network from outside. It makes sense someway.

## Automate machine image creation

I spent this morning to automate image creation.

The reason was that I ended with an image size too small, and I can not get a good way to resize.

Also it may happens I need to start from a different image base (to import from debian image, for example), and I forgot all the step did so far.

I create a dirty bash script, because code is the better documentation, even when it is not very clean.

## Network types

First of all, the funny staff.

> virsh net-edit --network default

is a convenient way to edit the `default`-named network (or any other name other than "default" that is defined).

This similar to `kubectl edit ...`  class of commands, but here the definition is in XML.


## Side project

Integrate in mush https://github.com/javanile/mush

by https://github.com/francescobianco/mush-packages

https://github.com/vpenso/libvirt-shell-functions
https://github.com/goffinet/virt-scripts

