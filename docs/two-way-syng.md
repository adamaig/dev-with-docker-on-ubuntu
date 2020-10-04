# Two Way Sync

Developing within the virtual machine does create some risk of loos (depending on how system bakcups are managed). In order to mitigate that, this system includes a module that will maintain a 2-way sync of files, keeping files local to the virtual machine, while persisting them to the host as a way to mitigate the risk.

## The rsync model

This part of the document is derived from [a tutorial on birdirectional syncs with rsync](https://www.infosecmonkey.com/2020/01/19/2-way-sync-with-rsync/).

1. Create a template representing the local and remote filesystems as directories.

    ```bash
    mkdir local_machine remote_machine remote_service
    for f in file1 file2 file3 file4; do touch local_machine/$f ; done
    for f in file5 file6 file7 file8; do touch remote_machine/$f ; done
    ```

1. Sync local_machine to remote_service using the `-a` archive mode, `-u` update (skip files that are newer on destination), and `-v` verbose flags.

    ```bash
    rsync -auv local_machine/ remote_service
    ```

1. Sync remote_machine to remote_service using the same flags

    ```bash
    rsync -auv remote_machine/ remote_service
    ```

1. Sync remote_service to both the local_machine and remote_machine

    ```bash
    rsync -auv remote_service/ local_machine
    rsync -auv remote_service/ remote_machine
    ```

1. To combine all of this into a single script that moves everything to the common remote_service before replicating down to the machines we would run a script like this.

    ```bash
    rsync -auv local_machine/ remote_service
    rsync -auv remote_machine/ remote_service
    rsync -auv remote_service/ local_machine
    rsync -auv remote_service/ remote_machine
    ```

Try this out by making edits to random files on each side, and ensure that only the latest edits are present after syrnchonizing the data.

## Use with the virtual machine

In practice if code was always committed and pushed to a remote git service, and all files are persisted in source control, this syncing wouldn't be necessary at all. In practice there are always gaps, WIP, etc. As a result supporting a 2-way sync between just the host machine and the vagrant guest seems like a reasonable way to avoid most cases of loss that can arise in this setup. I personally have removed a virtual machine disk before realizing I had excluded it from backups, and separately have encountered issues restarting a VM, and recovery was too time-consuming.

The point of this project is to have a repeatable development environment that can be spun up on a new machine to get anyone up and running as quickly as possible. Not losing all your work is an important part of that.

In order to achieve this goal, I've added hooks to the `vagrant up` and `vagrant halt` commands to execute rsync TO THE VM ON START, and FROM THE VM ON HALT. This behavior is configurable and can be disabled if desired.
