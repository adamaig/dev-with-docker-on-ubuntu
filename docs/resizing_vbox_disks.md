# Resizing VBox disks

The VMDK format cannot be resized currently (2017-03-05), but it is possible to
clone the drive to the VDI format, and increase the max size of the disk. The
VM must be off in order for this process to execute.

In this example a new 60GB disk will be created.

NOTE: The disk name and storagectl values may differ depending on the box in use.

1. Start downloading the gparted live cd. The version specified is current as of 2017-05,
   and the correct variant of the live CD for a 64bit MacBook Pro.

   ```shell
   wget http://downloads.sourceforge.net/gparted/gparted-live-0.28.1-1-amd64.iso
   # OR
   curl -L -O http://downloads.sourceforge.net/gparted/gparted-live-0.28.1-1-amd64.iso
   ```

2. If the download is continuing, open a new terminal. Stop the vagrant guest,
   clone the existing disk to a new format, resize the disk, and then swap the
   VM's disk in place.

   ```shell
   # Halt the system if it is running
   vagrant halt

   # clone the drive to a new format:
   VBoxManage clonemedium disk \
     ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vmdk \
     ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vdi --format vdi

   # Resize it to desired size (e.g., 60GB here):
   VBoxManage modifymedium ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vdi \
     --resize $(expr 60 \* 1024)

   # Replace the original drive:
   VBoxManage storageattach dev-on-ub --storagectl "SATA Controller" --port 0 \
     --device 0 --type hdd  --medium ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vdi
   ```

3. Configure the boot order (1: optical drive; 2: disk):

   ```shell
   VBoxManage modifyvm dev-on-ub --boot1 dvd --boot2 disk
   ```

4. After running this it may be necessary to restart the box a few times in
   order to get the VM to fully boot up cleanly. It isn't clean but, I found that
   "powercycling" it when it got stuck or issuing a `vagrant halt` command would
   lead to a clean boot after the VM gets stuck.

   Once you have a clean boot up with the new disk attached, and you can proceed
   to modify the partition table so that the new disk space can be used.

5. Attach optical drive w/ cd:

   ```shell
   VBoxManage storageattach dev-on-ub --storagectl "SATA Controller" --port 1 \
     --device 0 --type dvddrive --medium ./gparted-live-0.28.1-1-amd64.iso
   ```

   Note that the disk will be ejected after rebooting. Repeat this step if
   needed.

6. Now everything is ready to boot.

   ```shell
   VBoxManage startvm dev-on-ub --type gui
   ```

7. Follow the prompts in GParted until a GUI appears.
   Choose not to modify the keymap, then select a language you want, then continue
   through the remaining prompts. If GParted does not start automatically, start it.

   Note the partition device and mount point for the next step. In this example,
   these are /dev/sda5 and vagrant--vg-root.

   You will need to "deactivate" the existing partitions (right click to open menu),
   this will remove the locks, then right click the partition you want to resize
   and modify the partition size as desired. Apply the changes.

   This process must be done twice. Once to resize the extended partition so
   that it can use all the space on the physical disk, and again to resize the
   child of the extended partition, /dev/sda5, so that it can use all the space
   in the parent partition.

8. Close the GParted application, then open the terminal (do not reboot) and
   run the following commands IF the disk is setup with LVM. Note the double
   dash in 'vagrant--vg-root'.

   ```shell
   sudo pvresize /dev/sda5
   sudo lvresize -l +100%FREE /dev/mapper/vagrant-–vg-root
   sudo e2fsck -f /dev/mapper/vagrant-–vg-root
   sudo resize2fs /dev/mapper/vagrant-–vg-root
   ```

9. Shutdown the machine.

10. If the disk isn't automatically ejected, Eject the ISO in the optical drive:

    ```shell
    VBoxManage storageattach dev-on-ub --storagectl "SATA Controller" --port 1 \
      --device 0 --type dvddrive --forceunmount --medium emptydrive
    ```

Reboot the virtualbox. It may require a few reboots and/or powercycles as before.
