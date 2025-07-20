# Author: Pavlo Nykolyn
# checks, through nmcli, whether a connection has been established. If the
# check succeeds and the command has been invoked with the right flag, it
# will be pulled down;
# no more than three input options can be provided (each one SHALL indicate
# a value):
# 1) indicator used to enable the deactivation. The option is -p;
# 2) connection name, the value is to be specified through the -n option;
# 3) connection UUID, the value is to be specified through the -u option;
# if both are provided, the connection name takes precedence
# the status codes that can be returned by the scripts are:
# 0 -> the operation has been performed successfully;
# 1 -> an input parameter is not correct;
# 2 -> the specified connection cannot be found

impress ()
{
   # the first positional argument should be a prefix, indicating the message type
   # the second positional argument is the message itself
   echo "--- $(date) --- ${1} ${2}"
}

connection_name=
connection_uuid=
perform=0 # the default behaviour is to perform only the check
while getopts 'pn:u:' parameter
do
   case ${parameter}
   in
      p) perform=1 ;;
      n) connection_name="${OPTARG}" ;;
      u) connection_uuid="${OPTARG}" ;;
      ?) impress '[ERR]' 'the option identifier is not supported'
         exit 1 ;;
   esac
done

if [ ${OPTIND} -gt 6 ]
then
   impress '[ERR]' 'no more than three input parameters (together with their values) can be provided'
   exit 1
fi
# if there is no way to identify a connection, there is no need for this script...
if [ -z "${connection_name}" -a -z "${connection_uuid}" ]
then
   impress '[ERR]' 'the caller is expected to provide at least one identifier for the network connection'
   exit 1
fi

connection_identifier="${connection_name}"
# identifier type is set to the same value as the one used by nmcli
identifier_type='id'
if [ -n "${connection_uuid}" ]
then
   connection_identifier="${connection_uuid}"
   identifier_type='uuid'
fi

connections=$(nmcli --terse --fields NAME,UUID,STATE connection)
active_connection_identifier=$(echo "${connections}" | awk -v 'FS=:' -v "identifier_type=${identifier_type}" -v "target=${connection_identifier}" -f 'get_identifier.awk')
if [ -n "${active_connection_identifier}" ]
then
   impress '[INF]' "an active connection identified by ${active_connection_identifier} has been found."
   if [ ${perform} -eq 1 ]
   then
      impress '[INF] Attempting to pull it down ...'
      # only if the connection is active, it can be pulled down
      nmcli --terse connection down "${identifier_type}" "${active_connection_identifier}"
   fi
else
   impress '[INF]' "no active connection, identified by ${connection_identifier}, could be found"
   exit 2
fi

exit 0
