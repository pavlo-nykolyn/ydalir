# Author: Pavlo Nykolyn
# this script removes fields from a .csv file;
# the first input parameter is a file name (could be a base name, a relative path or an absolute path);
# the second input parameter is the maximum number of fields of a row belonging to the .csv file;
# the third input parameter is semi-colon separated sequence of unsigned non-zero integers. The values
# indicates fields that are to be ignored;
# the fourth input parameter is the field separator used by the .csv file;
# the fifth input parameter is the directory where the output file will be stored;
# the output file name is built from the input one by extracting the base name and appending _new just
# before the extension. The file will be generated in the current working directory.

function impress
{
   # the first positional argument should be a prefix, indicating the message type
   # the second positional argument is the message itself
   echo "--- $(date) --- ${1} ${2}"
}

if [ $# != 5 ]
then
   impress '[ERR]' 'five arguments are expected'
   exit 1
fi

file="${1}"
if [ ! -e "${file}" ]
then
   impress '[ERR]' "${file} does not exists"
   exit 1
fi

# both the maximum number of fields and the inhibition sequence shall contain only Arab digits;
# the first digit cannot be zero
max_num_fields=${2}
status=$(echo "${max_num_fields}" | sed -n '/^[123456789][[:digit:]]*$/p')
if [ -z "${status}" ]
then
   impress '[ERR]' 'the maximum number of fields contains forbidden characters'
   exit 1
fi

seq=$(echo "${3}" | tr ';' ' ')
for val in ${seq}
do
   status=$(echo "${val}" | sed -n '/^[123456789][[:digit:]]*$/p')
   if [ -z "${status}" ]
   then
      impress '[ERR]' 'an element of the inhibition sequence contains forbidden characters'
      exit 1
   fi
done

separator=${4}
status=$(echo "${separator}" | sed -n '/^[,;]$/p')
if [ -z ${status} ]
then
   impress '[ERR]' 'the field separator has to be either a comma or a semi-colon'
   exit 1
fi

target_dir="${5}"
if [ ! -d "${target_dir}" ]
then
   impress '[ERR]' "${target_dir} either does not exists or is not a directory"
   exit 1
fi

# generating the parameter string that is to be fed to the Awk action
i=1
par_str=
while [ ${i} -le ${max_num_fields} ]
do
   flag=0 # used to inhibit specific fields
   for val in ${seq}
   do
      if [ ${i} -eq ${val} ]
      then
         flag=1
      fi
   done
   if [ ${flag} -eq 0 ]
   then
      if [ ${i} -ne ${max_num_fields} ]
      then
         par_str="${par_str}\$${i}, "
      else
         par_str="${par_str}\$${i}"
      fi
   fi
   i=$((${i} + 1))
done

# creating the name of the output file
out_basename=$(echo "${file}" | awk -v 'FS=/' '{ print $NF }' | cut '--delimiter=.' '--fields=1')
out_filename="${out_basename}_new.csv"

action="{ print ${par_str} }"
impress '[INF]' "what will be performed -> ${action}"
# skipping the first three lines (header lines) of the input file
cat "${file}" | awk -v "FS=${separator}" -v "OFS=${separator}" -v 'RS=\n' -v 'ORS=\n' "${action}" > "${target_dir}/${out_filename}"
