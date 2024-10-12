# Deploy bootc image on beaker and run beaker test

The bootc image can be deployed into beaker server with custom kickstart in [beaker job xml](beaker-job.xml) and [custom bootc image](Containerfile). And beaker test can be run with [`restraint`](https://restraint.readthedocs.io/en/latest/index.html).

## Custom bootc image

To work with beaker system, `anamon` and `restraint` need to be built into bootc image.

Do not use `restraint-rhts` due to buiding image failed on `RUN dnf install -y restraint-rhts`

```
libsemanage.semanage_rename: WARNING: rename(/etc/selinux/targeted/active, /etc/selinux/targeted/previous) failed: Invalid cross-device link, fall back to non-atomic semanage_copy_dir_flags()

  Installing    : restraint-rhts-0.4.4-1.fc40eng.x86_64                 5/5
  error: failed to open dir mnt of /mnt/: File exists

  Error unpacking rpm package restraint-rhts-0.4.4-1.fc40eng.x86_64
  Running scriptlet: restraint-rhts-0.4.4-1.fc40eng.x86_64                5/5
  error: unpacking of archive failed on file /mnt/scratchspace: cpio: open failed - No such file or directory
  error: restraint-rhts-0.4.4-1.fc40eng.x86_64: install failed
```
Use [`restraint`](https://restraint.readthedocs.io/en/latest/index.html) to run the beaker test instead of legacy RHTS package or `restraint-rhts`.

Package `audit` is required by restraint `10_avc_check` and `97_audit_rotate` plugins.

```
use_pty:FALSE /usr/share/restraint/plugins/run_task_plugins /usr/share/restraint/plugins/run_plugins
Uploading dmesg.log .done
./10_avc_check: line 31: ausearch: command not found
Uploading avc.log .done
use_pty:FALSE /usr/share/restraint/plugins/run_task_plugins /usr/share/restraint/plugins/run_plugins
Skipping Multihost sync .. SERVERS/CLIENTS roles not set
./97_audit_rotate: line 15: /var/log/audit/*: No such file or directory
```

## Custom kickstart

To deploy bootc image on beaker, `<kickstart>` must be used instead of `<ks_appends>` in beaker job xml. Beaker will append `%packages` to install packages if `<ks_appends>` is configured. `%packages` does not work with bootc image anaconda installation.

If `<kickstart>` used, the `%packages` will not have any package installed.

```
%packages --ignoremissing
# Task requirements will be installed by the harness
%end
```

## Reserving

`<task name="/distribution/reservesys" role="STANDALONE">` does not work with bootc image because the [`reservsys code`](https://github.com/beaker-project/beaker-core-tasks/blob/master/reservesys/runtest.sh) still uses `restraint-rhts`.

Please use `<reservsys/>` or `<reservesys duration="3600"/>` instead. xref https://beaker-project.org/docs/user-guide/system-reservation.html
