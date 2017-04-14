# Migration
## Prior Knowledge

## Procedure For Upgrading

## Run LeoFS As a Non-Privileged User
### Since 1.3.3
### Overview
Starting from 1.3.3, all LeoFS nodes are running as non-privileged user `leofs` in official Linux packages.
It should work out of the box for new installations and for new nodes on existing installations.
However, for existing nodes upgrading to 1.3.3 (or later) from earlier versions the change might be not seamless. Compared to the usual upgrade procedure described at [System Maintenance](http://leo-project.net/leofs/docs/admin_guide/admin_guide_10.html),
extra steps are needed. There are a few options, depending on how the node was configured.

### Extra Steps
#### Running LeoFS with default paths
For those who have LeoFS configured with
- queue and mnesia in `/usr/local/leofs/<version>/leo_*/work`
- log files in `/usr/local/leofs/<version>/leo_*/log`
- storage data files in `/usr/local/leofs/<version>/leo_storage/avs`

Follow the below instructions when upgrading.

1. During upgrade of node (of any type), **after** stopping the old version and copying or moving every
files to be moved into the new directories, change the owner with the commands below. It has to be done **before** launching the
new version.
```
# chown -R leofs:leofs /usr/local/leofs/%version/leo_storage/avs
# chown -R leofs:leofs /usr/local/leofs/%version/leo_gateway/cache
# chown -R leofs:leofs /usr/local/leofs/%version/leo_*/log
# chown -R leofs:leofs /usr/local/leofs/%version/leo_*/work
```

2. Remove old temporary directory used by launch scripts. This step is needed because when earlier version was launched with `root` permissions, it creates a set of temporary directories in `/tmp` which cannot be re-used by non-privileged user as is, and launch scripts will fail with obscure messages - or with no message at all, except for an error in syslog (usually `/var/log/messages`).
```
# rm -rf /tmp/usr
```

3. Start the node through its launch script, as per upgrade flow diagram.

#### Running LeoFS with customized paths
For those who have LeoFS configured with, for example, let's say
- queue and mnesia in `/mnt/work`
- log files in `/var/log/leofs`
- storage data files in `/mnt/avs`

1. Before starting new version of a node, execute `chown -R leofs:leofs <..>` for all these external directories

2. Don't forget to remove temporary directory (`rm -rf /tmp/usr`) as well for the reasons described above.

These users might be interested in new features of "environment" config files, which allow to redefine
some environment variables like paths in launch script. We will describe about it on the later section.

#### Running LeoFS with customized launch scripts
For those who have LeoFS already running as non-privileged user.

1. Scripts that are provided by packages generally should be enough to run on most configurations without changes. If needed, change user from `leofs` to some other in "environment" config files (e.g. `RUNNER_USER=localuser`). Please refer to the later section for more details about environment config files.

2. Possible pitfall includes ownership of `/usr/local/leofs/.erlang.cookie` file, which is set to `leofs` during package installation. This should only be a problem when trying to run LeoFS nodes with permissions of some user which is not called `leofs`, but has home directory set to `/usr/local/leofs`. This is not supported due to technical reasons. Home directory of that user must be set to something else.

#### Running LeoFS in any form and keeping LeoFS running as `root`
For those who want to keep maximum compatibility with the previous installation.

1. In "environment" config file, set this option
```
RUNNER_USER=root
```

Please note that switching this node to run as non-privileged user later will require extra steps to carefully change all permissions. This is not recommended, but possible (at very least, in addition to `chown` commands from before, permissions of `leo_*/etc` and `leo_*/snmp/*/db` will have to be changed recursively as well).

## Environment Config Files
### Overview
Starting from version 1.3.3, some environment variables used by launch scripts can be redefined in
"environment" config files. They have shell syntax and are read by launch scripts. Their names are:
```
leo_gateway/etc/leo_gateway.environment
leo_manager_0/etc/leo_manager.environment
leo_manager_1/etc/leo_manager.environment
leo_storage/etc/leo_storage.environment
```

Changing settings in these files is completely optional, but can be used to better organize directories
used by LeoFS nodes and simplify upgrades. Here is highly customized example of `.environment` and `.config` files that allow LeoFS to store all work information and logs outside of default installation tree (`/usr/local/leofs/<version>`).
As a result, upgrade process to newer version becomes as simple as placing `leo_*.environment` files in `etc` directory of new version, for example (for `leo_manager_0`):
```
$ /usr/local/leofs/<old_version>/leo_manager_0/bin/leo_manager stop
$ cp /usr/local/leofs/<old_version>/leo_manager_0/etc/leo_manager.environment /usr/local/leofs/<new_version>/leo_manager_0/etc/
$ /usr/local/leofs/<new_version>/leo_manager_0/bin/leo_manager start
```

With this, users can place actual config files (like `leo_manager.conf`) to directory of their choice and change them independently of version upgrades, and the `.environment` files that need to be placed into installation tree don't need to be changed between versions.  With the correct setup, since no work/temporary files will be kept in the installation tree, old version can be removed cleanly.

### Example Configuration
Contents of `/usr/local/leofs/<version>/leo_manager_0/etc/leo_manager.environment`:
```
# pick config file from fixed place
RUNNER_ETC_DIR=/etc/leofs/leo_manager_0
# store erlang.log.* and run_erl.log in this directory
RUNNER_LOG_DIR=/var/log/leofs/leo_manager_0
```

Directories defined in RUNNER_ETC_DIR and RUNNER_LOG_DIR (in this example, `/etc/leofs/leo_manager_0` and
`/var/log/leofs/leo_manager_0`) must be writable by `leofs` user, also `$RUNNER_LOG_DIR/sasl` (here
`/var/log/leofs/leo_manager_0/sasl`) must exist:
```
drwxr-xr-x. 2 leofs leofs 4096 Apr  4 20:40 /etc/leofs/leo_manager_0/
drwxr-xr-x. 4 leofs leofs 4096 Apr  5 20:00 /var/log/leofs/leo_manager_0/
drwxr-xr-x. 2 leofs leofs 4096 Apr  4 20:40 /var/log/leofs/leo_manager_0/sasl/
```

In `leo_manager.conf`, all options related to directories should point to external paths:
```
sasl.sasl_error_log = /var/log/leofs/leo_manager_0/sasl/sasl-error.log
sasl.error_logger_mf_dir = /var/log/leofs/leo_manager_0/sasl
mnesia.dir = /var/local/leofs/leo_manager_0/work/mnesia/127.0.0.1
queue_dir = /var/local/leofs/leo_manager_0/work/queue
log.erlang = /var/log/leofs/leo_manager_0/erlang
log.app = /var/log/leofs/leo_manager_0/app
log.member_dir = /var/log/leofs/leo_manager_0/ring
log.ring_dir = /var/log/leofs/leo_manager_0/ring
erlang.crash_dump = /var/log/leofs/leo_manager_0/erl_crash.dump
```

For `leo_storage.conf` it will be:
```
sasl.sasl_error_log = /var/log/leofs/leo_storage/sasl/sasl-error.log
sasl.error_logger_mf_dir = /var/log/leofs/leo_storage/sasl
obj_containers.path = [/mnt/avs]
log.erlang = /var/log/leofs/leo_storage/erlang
log.app = /var/log/leofs/leo_storage/app
log.member_dir = /var/log/leofs/leo_storage/ring
log.ring_dir = /var/log/leofs/leo_storage/ring
queue_dir  = /var/local/leofs/leo_storage/work/queue
leo_ordning_reda.temp_stacked_dir = /var/local/leofs/leo_storage/work/ord_reda/
erlang.crash_dump = /var/log/leofs/leo_storage/erl_crash.dump
```

For `leo_gateway.conf`:
```
sasl.sasl_error_log = /var/log/leofs/leo_gateway/sasl/sasl-error.log
sasl.error_logger_mf_dir = /var/log/leofs/leo_gateway/sasl
log.erlang = /var/log/leofs/leo_gateway/erlang
log.app = /var/log/leofs/leo_gateway/app
log.member_dir = /var/log/leofs/leo_gateway/ring
log.ring_dir = /var/log/leofs/leo_gateway/ring
cache.cache_disc_dir_data = /var/local/leofs/leo_gateway/cache/data
cache.cache_disc_dir_journal = /var/local/leofs/leo_gateway/cache/journal
queue_dir = /var/local/leofs/leo_gateway/work/queue
erlang.crash_dump = /var/log/leofs/leo_gateway/erl_crash.dump
```

Of course, all these directories must exist and have correct ownership/permissions (writable by `leofs` user, unless set up otherwise)

### Additional settings - SNMP config
When pursuing "pure" system which keeps all the data out of installation tree, one might also decide to move SNMP agent config and SNMP "db" directories to external paths, by setting (example for `leo_manager_0`) this in `leo_manager.config`:
```
snmp_conf = /etc/leofs/leo_manager_0/leo_manager_snmp
```
then copying `/usr/local/leofs/<version>/leo_manager_0/snmp/snmpa_manager_0/leo_manager_snmp.config` to
`/etc/leofs/leo_manager_0/leo_manager_snmp` and setting
```
{db_dir, "/var/local/leofs/leo_manager_0/snmp_db"},
```
in `/etc/leofs/leo_manager_0/leo_manager_snmp.config` to make sure that absolutely no temporary files are created in `/usr/local/leofs` tree. It shouldn't matter otherwise since there is no need to keep contents of SNMP `db` directory between upgrades. (Here, copy of leo_manager_snmp.config was made so that original config would be untouched; while it is possible to change `db_dir` in original `/usr/local/leofs/<version>/leo_manager_0/snmp/snmpa_manager_0/leo_manager_snmp.config` as well, doing so would mean that this file needs to be replaced after each upgrade, reducing benefit of only changing `.environment` file after upgrade)

### Notice
Please note that this configuration is just an example of how to use `.environment` config features to move all the log files and config files out of the tree so they reside at fixed paths, to simplify configuration changes and upgrades as much as possible. The resulting upgrade process can be less safe than original one suggested at [System Maintenance](http://leo-project.net/leofs/docs/admin_guide/admin_guide_10.html), because new version changes working mnesia and queue directories upon launch and going back to the older version might be not always possible. Users should consider making backups of work directories (`/var/local/leofs` in this example) before launching the newer version of a node.
