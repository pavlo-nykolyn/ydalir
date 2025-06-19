# Author: Pavlo Nykolyn
# This script attempts to mount a Samba share, hosted by a different host.
# The mount is attempted if, and only if, the remote host is reachable.
# While this condition is not satisfied, the script will continue
# to wait till the host becomes reachable.
# The input parameters are (their order shall be followed by a caller):
# - IPv4 address of the host;
# - source directory (its initial character shall not be /);
# - target directory;
# - secret path (the file indicates the credentials used for source authentication);
# - a comma separated list of mount options implemented for the CIFS file system. The
#   list shall not include the authentication information, as the previous parameter
#   is expected to store it.

logfile="/var/log/share_pinger.log"

myLogger ()
{
   # the first positional argument should be a prefix, indicating the message type
   # the second positional argument is the message itself
   echo "--- $(date) --- ${1} ${2}"
} >> "${logfile}"

check_ipv4.sh "${1}"
if [ $? -gt 0 ]
then
   exit
fi
ipv4_host="${1}"
timeout=4 # wait time for a response by the ping utility
packet_cnt=3 # how many packets will be dispatched by each ping instance

myLogger "[INF]" "checking ${ipv4_host} (is it reachable?) ..."
until ping -c "${packet_cnt}" -W "${timeout}" "${ipv4_host}" >> "${logfile}"
do
   sleep 30s
done
myLogger "[INF]" "the host ${ipv4_host} has become reachable ..."

source="//${ipv4_host}/${2}"
target="${3}"

secret_path="${4}"
if [ ! -f "${secret_path}" ]
then
   myLogger '[ERR]' "${secret_path} either does not exist or is not a regular file"
   exit
fi

# if the target directory does not exists, it will be created
if [ ! -d "${target}" ]
then
   myLogger "[INF]" "Creating ${target} ..."
   mkdir "${target}"
   error_ind=$?
   if [ ${error_ind} -ne 0 ]
   then
      myLogger "[ERR]" "${target} has not been created due to a mkdir error (code -> ${error_ind})."
      exit
   fi
else
   myLogger "[INF]" "${target} already exists."
   num_files=$(ls "${target}" | wc --lines)
   if [ ${num_files} -gt 0 ]
   then
      myLogger "[INF]" "${target} is not empty."
      exit
   fi
fi
myLogger "[INF]" "Mounting ${source} ..."
mount --source "${source}" --target "${target}" -t cifs -o "credentials=${secret_path},${5}"
error_ind=$?
if [ ${error_ind} -eq 0 ]
then
   myLogger "[INF]" "${source} mounted."
else
   myLogger "[ERR]" "${source} has not been mounted due to a mount error (code -> ${error_ind})."
fi
