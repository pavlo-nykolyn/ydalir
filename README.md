# ydalir

A collection of bash scripts that I've written to solve various issues related to Linux machine
either at work or in my free time.

* [Remove arbitrary columns from a .csv file](veiði)
* [Check the availability of a remote samba share and mount it](share_pinger)
* [Create a partiton](create_partition)
* [Generate the checksum of a file and compare it with a "master" checksum](digest_chk)
* [Burn a an image for an OS supported by the RaspberryPi boards into an SD card](burn_raspberry_image)
* [Checks and, if commanded to do so, inhibits an active network connection](inhibit_network_connection)
* [Removes all files that result from the compilation of python source files](rm_compiled_python)

> [!IMPORTANT]
> _whenever a script uses other scripts, it is important to place them into the same directory of their caller_

> [!WARNING]
> _remember to enclose both the input arguments within either single or double quotes_

## veiði

this script removes a set of fields from a .csv file. Currently, the amount of
fields within the source file is not bounded.

### Synopsis

> veidi.bash \<source-file\> \<number-of-fields\> \<field-set\> \<separator\> \<target-dir\>

option | description
:---:  |    :---:
\<source-file\>      | it can a base name, a relative path or an absolute path
\<number-of-fields\> | indicates the amount of fields contained within a row
\<field-set\>        | indicates the set of fields that are to be removed. The field index starts from one. Indexes are separated by a single semi-colon. For example, a valid field set is 2;5;8
\<separator\>        | separator between any two fields of the input file. It will be used in the output file, too. Valid separators belong to the set {',', ';'}
\<target-dir\>       | the directory that will contain the output file

the name of the output file is derived from the input file name. In particular, _new.csv is
appended to the base name (devoid of its extension) of the latter. If the base name contains
multiple dots, only the token preceding the first one will appear in the output file name.

the script needs the execute privilege:

```bash
chmod +x veidi.bash
```

valid only for the current user

```bash
chmod u+x veidi.bash
```

## share_pinger

this script mounts a samba share after its host becomes reachable. This test is implemented through
the ping utility. In particular, every thirty seconds a shell instance will spawn and invoke ping.
This invocation limits the amount of dispatched packets to three and sets the wait time for a response
to four seconds. Once one of this invocations results in a successful response by the host, the
script will proceed to perform the mount.

Two files are needed: share\_pinger.sh and check\_ipv4.sh;

the former implements the main logic, while the latter is called by share_pinger.sh to perform a check
on the IPv4 address that identifies the host of the share.
Moreover, in order to run it, it is necessary to execute it as root. Usually, I run this script through
an initialization one after system boot so, there is no need to invoke mount through sudo.

Another feature of the script is the generation of log data within the file _/var/log/share\_pinger.log_.
Needless to say, this feature requires super-user privileges.

### Synopsis

> share_pinger.sh \<ipv4\> \<source\> \<target\> \<secret\> \<option-list\>

option | description
:---:  |    :---:
\<ipv4\>         | the IPv4 address of the share host
\<source\>       | the source directory of the share. This should not be an absolute path. The latter will be defined as **//\<ipv4\>/\<source\>**
\<target\>       | target directory
\<secret\>       | path to a file containing information needed for the authentication procedure requested by the samba server. See the documentation for the _credentials_ option of the mount.cifs man page. This file shall be manipulated only by the super user
\<option-list\>  | a comma-separated list of options valid for the share. The credentials one is inserted automatically by the script

before using it, make sure that both files have the executable bit set:

```bash
chmod +x share\_pinger.sh check\_ipv4.sh
```

valid only for the current user

```bash
chmod u+x share\_pinger.sh check\_ipv4.sh
```

## create_partition

this script creates an ext4 partition on a block device. If no partition table is detected on the storage device,
a GUID partition table will be created and the partition will become its first one.

Two files are needed: create\_partition.sh and analyze\_parted\_line.awk;

I've created the awk script to analyze the machine-readable output of the print command defined by the parted utility.
In particular, I've considered two cases:

- no partition exists: the nominal size of the block device and its physical block size will be extracted;
- one or multiple partitions exist: both the start and the end offset of the partition will be extracted;

how these values are employed:

- the nominal size is used to check the partition size provided by the caller. If the latter is greater than the
  former, no new partition will be created;
- the physical block size is used to compute the alignment offset (only when no partition exists on the device);
- both the start and the end offset are set to find the position of the last partition;

The initial offset of the new partition is adjusted with respect to the alignment offset (if no partition exists on the device) or the end offset of the last partition;

### Synopsis

> create_partition.sh \<block-device\> \<partition-size\> \<alignment-scaler\>

option | description
:---:  |    :---:
\<block-device\>     | shall be an absolute path
\<partition-size\>   | shall be expressed in bytes (there is no need to append the unit B at the end of the value)
\<alignment-scaler\> | a value belonging to the \[1, 65535\] interval. Used to compute the start offset of the first partition

if the alignment scaler is not specified, its value will be set to 65535;
there is no need to invoke the script with super user privileges, as all invocation to the parted utility do so.

## digest_chk

this script computes the checksum (the argument can be specified at call time) of a file and compares it to a master "checksum"
If the comparison is not successful, the result of the cmp command will be printed on the terminal.

### Synopsis

> digest_chk.sh \<target-path\> \<reference-checksum-path\> \<algorithm\>

option | description
:---:  |    :---:
\<target-path\>             | can be either a relative or an absolute path (has to both exist and reference a regular file)
\<reference-checksum-path\> | can be either a relative or an absolute path (has to both exist and reference a regular file)
\<algorithm\>               | can be one of the following values: md5, sha1, sha224, sha256, sha384, sha512

## burn_raspberry_image

a very simple script that burns an OS image for a RaspberryPi board through dd; given that the official OS for these boards
usually comes as a compressed file, the script employs a pipe to decompress it and source the content to dd;
it is advisable to turn off the auto-mount feature of the host operating system.

### Synopsis

> burn\_raspberry\_image.sh \<block-device\> \<image-path\>

option | description
:---:  |    :---:
\<block-device\> | has to be an absolute path (the latter has to both exist and reference a block device)
\<image-path\> | can be either a relative or an absolute path to an image file (the latter has to both exist and reference a regular file)

## inhibit_network_connection

this script uses nmcli to find a connection and, if the latter is active and the caller indicated its inhibition, the connection will
be pulled down. It is possible to indicate either the user-friendly name or the unique identifier of the network connection. The caller
SHALL provide at least one identifier (why one would choose to not provide an identifier is beyond me...). It is possible to use
the script only to ascertain that a network connection is active.

> [!IMPORTANT]
> when both the user-friendly and the unique identifier are specified, the latter is given a higher priority

The script is implemented through two files:

- inhibit\_network\_connection.sh
- get\_identifier.awk

the former uses nmcli to verify the status of the connection and, eventually, to pull it down. The latter, analyzes the result of
a call to nmcli that uses the connection command. The first occurrence of an active connection that matches the specified identifier
will be used as the inhibition target. This is why I've given the possibility to indicate a unique identifier in order to distinguish
connections that bear the same user-friendly name.

### Synopsis

> inhibit\_network\_connection.sh \[-p\] -n \<connection-name\> \[-u \<connection-uuid\>\]

option | description
:---:  |    :---:
-p | the connection inhibition will be performed
-n \<connection-name\> | user-friendly name of the connection
-u \<connection-uuid\> | unique identifier of the connection

## rm_compiled_python

a very simple script that analyzes a directory and its sub-directories in order to find and delete compiled python files and the
\_\_pycache\_\_ sub-directories. It requires a single input parameter: the root directory where the search will take place

> rm\_compiled\_python.sh \<root-dir\>
