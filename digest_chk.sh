# Author: Pavlo Nykolyn
# a little script that generates a checksum of a file and compares it to a reference checksum.
# Four input parameters are required:
# 1) target file;
# 2) file holding a reference checksum;
# 3) checksum algorithm;

function impress
{
   # the first positional argument should be a prefix, indicating the message type
   # the second positional argument is the message itself
   echo "--- $(date) --- ${1} ${2}"
}

if [ $# -ne 3 ]
then
   impress '[ERR]' 'three arguments are expected'
   exit 1
fi

# both files shall exist and have to be regular files
target="${1}"
if [ ! -e "${target}" -o ! -f "${target}" ]
then
   impress '[ERR]' "${target} either does not exists or is not a regular file"
   exit 1
fi

reference_holder="${2}"
if [ ! -e "${reference_holder}"  -o ! -f "${reference_holder}" ]
then
   impress '[ERR]' "${reference_holder} either does not exists or is not a regular file"
   exit 1
fi

# choosing the appropriate command based on the algorithm indicated by the caller
algorithm_command=sum
algorithm="${3}"
case "${algorithm}"
in
      md5) algorithm_command="md5${algorithm_command}" ;;
     sha1) algorithm_command="sha1${algorithm_command}" ;;
   sha224) algorithm_command="sha224${algorithm_command}" ;;
   sha256) algorithm_command="sha256${algorithm_command}" ;;
   sha384) algorithm_command="sha384${algorithm_command}" ;;
   sha512) algorithm_command="sha512${algorithm_command}" ;;
esac

if [ "${algorithm_command}" == 'sum' ]
then
   impress '[ERR]' "${algorithm} is not a valid algorithm"
   exit 1
fi

computed=$("${algorithm_command}" "${target}" | cut --delimiter=' ' --fields=1) # computed checkusm retrieval
impress '[INF]' "computed ${algorithm} digest: ${computed}"
comparison=$(echo "${computed}" | cmp "${reference_holder}")
if [ -z "${comparison}" ]
then
   impress '[INF]' 'the computed checksum equals the original one'
else
   echo "${comparison}"
fi
