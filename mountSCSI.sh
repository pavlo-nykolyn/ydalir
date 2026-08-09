# Author: Pavlo Nykolyn
# attempts to mount the file-system hierarchy of an SCSI device, given the serial number of the
# underlying hardware. Three input parameters can be specified at most:
# 1) [MANDATORY] the target mount-point;
# 2) [MANDATORY] the hardware serial number;
# 3) [OPTIONAL] a list of mount options (the value of the --options option of the mount utility). If not set,
#    the mount procedure will use the default ones

# the output of the impress function will be stored into this file
# I'm assuming that the script will be run as root so, no permission
# manipulation is performed
log_file='/var/log/mountSCSI.log'

impress ()
{
   # appends a message to an output stream. Two input parameters are required:
   # first -> the message itself;
   # second -> the message prefix;
   # either of the two parameters can be an empty string
   echo "${1}:${2}" >> "${log_file}"
}

if [ $# -gt 3 -o $# -lt 3 -a $# -ne 2 ]
then
   impress 'ERR' 'at most three but, no less than two input parameters can be specified'
   exit 1
fi

target="${1}"
if [ ! -d "${target}" ]
then
   impress 'ERR' "${1} does not exist as a directory on this host"
   exit 1
fi

# only the major number is matched against, so that partitions do not appear within the output;
# I'm assuming that no two devices share the same serial number
match=$(lsblk --raw --output 'NAME,MAJ:MIN,SERIAL' | tail --lines=+2 | sed -n '/^sd.*:0.*/p' | sed -n "/.*${2}.*/p")
if [ -z "${match}" ]
then
   impress 'ERR' "${2} does not correspond to a valid serial number"
   exit 1
fi
d_name="$(echo ${match} | cut '--delimiter= ' --fields=1)" # needed to retrieve the file-system type of a partition, if the disk has any

# assuming a single partition
partition=$(lsblk --raw --output 'NAME,FSTYPE,PATH' | tail --lines=+2 | sed -n "/^${d_name}1.*/p")
fs="$(echo ${partition} | cut '--delimiter= ' --fields=2)"
p_path="$(echo ${partition} | cut '--delimiter= ' --fields=3)"

bin_path="$(which mount)"
if [ -z ${bin_path} ]
then
   impress 'ERR' "unable to find the absolute path of mount"
   exit 1
fi

options=
if [ -n ${3} ]
then
   options="--options ${3}"
fi

"${bin_path}" --source "${p_path}" --target "${target}" --type "${fs}" ${options}
