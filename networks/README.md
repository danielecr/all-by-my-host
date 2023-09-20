# Simple network commands

> virsh net-list --all

> virsh net-dumpxml networname

> virsh net-define XMLFILE

> virsh net-start --network networkname

> virsh net-undefine --network networname

## Attach

> virsh attach-interface --domain unode1 --type network --source network-b --model virtio --mac 52:94:00:b1:9c:df --config --live

> virsh domiflist vm1


## Detatch

> virsh detach-interface --domain unode1 --type network --mac 52:53:00:4b:75:6f --config

Do not detach --live (because of traffic). Detach by mac: `virsh domiflist vm1` for network/MAC relation.

## Note

Edit does not work, or it is not so easy.

When an interface is called **enp1s0** or **enp7s0**, that means in xml {bus 1, slot 0} and {bus 7, slot 0}

`<address>` sub-element of interface must be compatible with other devices' address.

Anyway it could be "fun" to expect a given network name (it is udev that assign the names).

On my host machine I see `enp8s0`:

* 'en': EtherNet
* 'p8': position 8 (bus 8)
* 's0': slot 0

and `wlp7s0`:

* 'wl': WireLess
* 'p7': position 7 (bus 7)
* 's0': slot 0

While on the guest, `lspci`:

```
$ lspci 
00:00.0 Host bridge: Intel Corporation 82G33/G31/P35/P31 Express DRAM Controller
00:01.0 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:01.1 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:01.2 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:01.3 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:01.4 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:01.5 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:01.6 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:01.7 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:02.0 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:02.1 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:02.2 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:02.3 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:02.4 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:02.5 PCI bridge: Red Hat, Inc. QEMU PCIe Root port
00:1f.0 ISA bridge: Intel Corporation 82801IB (ICH9) LPC Interface Controller (rev 02)
00:1f.2 SATA controller: Intel Corporation 82801IR/IO/IH (ICH9R/DO/DH) 6 port SATA Controller [AHCI mode] (rev 02)
00:1f.3 SMBus: Intel Corporation 82801I (ICH9 Family) SMBus Controller (rev 02)
01:00.0 Ethernet controller: Red Hat, Inc. Virtio network device (rev 01)
02:00.0 USB controller: Red Hat, Inc. QEMU XHCI Host Controller (rev 01)
03:00.0 Communication controller: Red Hat, Inc. Virtio console (rev 01)
04:00.0 SCSI storage controller: Red Hat, Inc. Virtio block device (rev 01)
05:00.0 Unclassified device [00ff]: Red Hat, Inc. Virtio memory balloon (rev 01)
06:00.0 Unclassified device [00ff]: Red Hat, Inc. Virtio RNG (rev 01)
07:00.0 Ethernet controller: Red Hat, Inc. Virtio network device (rev 01)
```

So it could be advisable to run lspci on the guest _before_ editing xml using a pci bus and slot, and to avoid conflict.
