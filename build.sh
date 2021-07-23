#!/bin/bash
#
#
#  Install devstack on ubuntu 20
#

## Install dependencies before build 
# 
# apt-get install cloud-image-utils wget qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager
#


# get the current interface for bridge 
interface=`ip a | grep "mtu" | cut -d':' -f2 | sed s/\ //g | egrep 'en|et'`

# create a network config file
cat config/net-devstack-public.xml.tmpl | sed s/%INTERFACE%/${interface}/g >config/net-devstack-public.xml

## create Network
virsh net-list | grep devstack-public 2>&1 >/dev/null
if [ $? -gt 0 ]; then
    virsh net-define config/net-devstack-public.xml
    virsh net-autostart devstack-public
    virsh net-start devstack-public
    else
    #virsh net-destroy devstack-public
    #virsh net-destroy devstack-public
    #sleep 2
    #virsh net-define config/net-devstack-public.xml
    #virsh net-autostart devstack-public
    #virsh net-start devstack-public
    echo "Use prepared network config"
fi

# Build ISO File
sudo cloud-localds /var/lib/libvirt/images/cloud-init-devstack.iso config/cloud-init-devstack.yaml

# Download cloud image file
mkdir -p tmp
cd tmp
wget -c https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img  2>&1 >/dev/null
cd ..

# create image
sudo qemu-img convert -f qcow2  -O qcow2 tmp/focal-server-cloudimg-amd64.img /var/lib/libvirt/images/devstack.qcow2
sudo qemu-img resize /var/lib/libvirt/images/devstack.qcow2 1200G


# start vm
virt-install --name devstack --memory 24576 \
  --disk /var/lib/libvirt/images/devstack.qcow2,device=disk,bus=virtio \
  --disk /var/lib/libvirt/images/cloud-init-devstack.iso,device=cdrom \
  --os-type linux \
  --os-variant ubuntu20.04 \
  --virt-type kvm \
  --cpu host-passthrough \
  --vcpus 12 \
  --network type=direct,source=${interface},source_mode=bridge \
  --network network=devstack-public,model=virtio \
  --import \
  --noautoconsole

