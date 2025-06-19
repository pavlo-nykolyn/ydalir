# Author: Pavlo Nykolyn
# a simple script that creates a partition on a disk and, subsequently mounts an ext4 file system on both of them
# the input parameters are:
# 1) the block device absolute path;
# 2) the partition size (expressed in bytes);
# 3) the alignment scaler. Shall be belong to the interval [1, 65535]. The default value is 65535

impress ()
{
   # the first positional argument should be a prefix, indicating the message type
   # the second positional argument is the message itself
   echo "--- $(date) --- ${1} ${2}"
}

device="${1}"
if [ ! -b "${device}" ]
then
   impress '[ERR]' "{device} is not a block device"
   exit 1
fi

part_size="$(echo ${2} | sed -n '/^[1-9][[:digit:]]*$/p')"
if [ -z "${part_size}" ]
then
   impress '[ERR]' "${2} shall be a positive non-zero integer"
   exit 1
fi

al_scaler=65535
if [ -n "${3}" ]
then
   al_scaler="$(echo ${3} | sed -n '/^[1-9][[:digit:]]*$/p')"
   if [ -z "${al_scaler}" -o ${al_scaler} -gt 65535 ]
   then
      impress '[ERR]' "${3} either is not a positive non-zero integer or exceeds 65535"
      exit 1
   fi
fi

impress '[INF]' "the partition size is ${part_size} bytes"

# only a record separator is to be converted into a single white-space character
dev_inf=$(sudo parted --machine --script "${device}" unit B print | sed 's/; /;/g' | tr ' ' '_' | tr ';' ' ')
max_size= # the maximum size of the block device
phy_blk_size= # physical block size
# partition
# ------------------------------------------------------------
offset= # offset of the starting byte belonging to the first partition
start= # first byte position belonging to a partition
end= # last byte position belonging to a partition
# ------------------------------------------------------------
for line in ${dev_inf}
do
   impress '[INF]' "analyzing ${line} ..."
   result=$(echo ${line} | awk -v 'FS=:' -f 'analyze_parted_line.awk') # parted delimits the machine readable fields with a colon character
   num_fields=$(echo "${result}" | cut '--delimiter= ' '--fields=3')
   if [ ${num_fields} -gt 1 ]
   then
      first_token=$(echo "${result}" | cut '--delimiter= ' '--fields=1')
      if [ ${first_token} -eq 0 ]
      then
         impress '[INF]' "something when wrong during the extraction from the ${line} line"
         exit 1
      fi
      second_token=$(echo "${result}" | cut '--delimiter= ' '--fields=2')
      if [ ${second_token} -eq 0 ]
      then
         impress '[INF]' "something when wrong during the extraction from the ${line} line"
         exit 1
      fi
      if [ ${first_token} -lt ${second_token} ]
      then
         # set in order to find the end offset of the last partition
         start=${first_token}
         end=${second_token}
      else
         # no partition exists on the disk
         # --------------------------------------------------------------------------------
         max_size=${first_token}
         impress '[INF]' "the maximum storage size is ${max_size} bytes"
         phy_blk_size=${second_token}
         impress '[INF]' "the physical block size is ${phy_blk_size} bytes"
         offset=$((${phy_blk_size} * ${al_scaler}))
         # a new partition table will be created only if does not exist
         partition_table=$(echo ${line} | cut '--delimiter=:' '--fields=6')
         if [ "${partition_table}" = 'unknown' ]
         then
            impress '[INF]' "no partitions have been found. A new GUID partition table is about to be created on ${device} ..."
            sudo parted --script ${device} mklabel gpt
         fi
         # --------------------------------------------------------------------------------
      fi
   fi
done

if [ -n "${end}" ]
then
   rem_size=$((${max_size} - ${end}))
   if [ ${rem_size} -gt ${part_size} ]
   then
      offset=$((${end} + 1))
   else
      impress '[ERR]' "the partition size ${part_size} is greater than the remaining size at the end of the storage device"
      exit 2
   fi
fi

impress '[INF]' "the first byte of the new partition will be placed at position ${offset}"
impress '[INF]' "creating the first partition of size ${part_size} bytes ..."
sudo parted --script ${device} unit B mkpart primary ext4 "${offset}" "$((${part_size} + ${offset}))"
