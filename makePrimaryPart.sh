# Author: Pavlo Nykolyn
# can be used to create a primary partition and an ext-like file-system
# the latter will be created on the primary partition of the indicated
# device
# The following input parameters shall be supplied:
# 1) absolute path of the block device;
# 2) file-system type. Shall belong to the set {ext2, ext3, ext4};
# ATTENTION: the entire storage space will be used whenever the partition is created;
#            any existing partition will be removed from the partition table
# notice codes (returned by the script):
# 0 -> successful operation;
# 1 -> input error;
# 2 -> storage manipulation error;

impress ()
{
   # two input arguments are expected:
   # 1) a prefix;
   # 2) a message;
   # the prefix will always be preceded by a time-stamp
   echo "{$(date "+%d-%m-%Y %H:%M:%S")} ${1} ${2}"
}

find_bin ()
{
   # a single input argument is required: the binary name;
   # returns the directory containing the binary
   # currently, foour directories are searched for the purpose:
   # /bin
   # /sbin
   # /usr/bin
   # /usr/sbin
   dir=''
   if [ -n "$(ls -l /bin | sed -n /${1}\$/p)" ]
   then
      dir='/bin'
   elif [ -n "$(ls -l /sbin | sed -n /${1}\$/p)" ]
   then
      dir='/sbin'
   elif [ -n "$(ls -l /usr/bin | sed -n /${1}\$/p)" ]
   then
      dir='/usr/bin'
   elif [ -n "$(ls -l /usr/sbin | sed -n /${1}\$/p)" ]
   then
      dir='/usr/sbin'
   fi

   echo "${dir}"
}

if [ $# -ne 2 ]
then
   impress '[ERR]' 'the caller is expected to supply two arguments'
   exit 1
fi

target_path="${1}"
if [ ! -b "${target_path}" ]
then
   impress '[ERR]' "${target_path} either does not exists or is not a block device"
   exit 1
fi

fs_type="$(echo ${2} | sed -n '/^ext[2-4]$/p')"
if [ -z "${fs_type}" ]
then
   impress '[ERR]' 'only ext-like file systems are supported'
   exit 1
fi

# PARTITION
tool_dir="$(find_bin parted)"
if [ -n "${tool_dir}" ]
then
   impress '[INF]' "parted has been found within ${tool_dir}"
else
   impress '[ERR]' "parted has not been found"
fi
# removing any exisiting partition
partition_set="$(${tool_dir}/parted --script --machine ${target_path} print | tail --lines=+3 | cut '--delimiter=:' --fields=1 | sort --reverse | tr '\n' ' ')"
# I'm expecting that the first partition is the primary one (hence the --reverse option)
# whenever no partition does exist on the device (tail produces no lines at all), tr will result in a string containing a single space
if [ -z "$(echo ${partition_set} | sed -n '/^ $/p')" ]
then
   for partition_number in ${partition_set}
   do
      ${tool_dir}/parted --script --machine ${target_path} rm ${partition_number}
   done
fi
"${tool_dir}/parted" --script --machine "${target_path}" mkpart primary "${fs_type}" '0%' '100%'
if [ $? -ne 0 ]
then
   impress '[ERR]' 'something went wrong during partition creation'
   exit 2
fi
# FILE SYSTEM
tool_dir="$(find_bin mke2fs)"
if [ -n "${tool_dir}" ]
then
   impress '[INF]' "mke2fs has been found within ${tool_dir}"
else
   impress '[ERR]' "mke2fs has not been found"
fi
# I do prefer to perform a read/write check on a memory cell
echo "${tool_dir}/mke2fs" -v -q -cc -t "${fs_type}" "${target_path}1"
if [ $? -ne 0 ]
then
   impress '[ERR]' 'something went wrong during file system creation'
   exit 2
fi

exit 0