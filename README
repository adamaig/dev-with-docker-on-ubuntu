# dev-with-docker-on-ubuntu

After fighting with Docker on OSX and the need for 2-way syncs, fsevents, etc.
I developed a desire to get back to a simple(r) development on a linux based
VM. This project is a jumping off point.

# Resizing VBox disks

The VMDK format cannot be resized current (2016-09-05), but it is possible to
clone the drive to the VDI format, and increase the max size of the disk. The 
VM must be off in order for this process to execute.

```shell
# clone the drive to a new format
VBoxManage clonehd disk /path/to/current.mdk /path/to/clone.vdi --format vdi
# Resize it to desired size (e.g., 60GB here)
VBoxManage modifyhd /path/to/clone.vdi --resize $(expr 6 \* 10240)
# Replace the original drive 
VBoxManage storageattach udev --storagectl SATA --port 0 --device 0 \
  --type hdd --medium /path/to/clone.vdi 
```


