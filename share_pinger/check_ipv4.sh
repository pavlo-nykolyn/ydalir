# Author: Pavlo Nykolyn
# a simple script that checks whether the input argument is an IPv4 address;
# the only input parameter is the check target.
# The following error codes are returned by the script
# 1 -> an octet does not represent a positive integer;
# 2 -> the value of an octet exceeds 255;
# 3 -> the number of octets is not equal to four

target="${1}"

octets=$(echo "${target}" | tr '.' ' ')

is_digit_sequence ()
{
   # checks whether the input character sequence contains only Arab digits
   # the first input parameter is the check target
   # returns the checked sequence
   # assuming that the value belong to the [0,2+] interval (the + indicates a sequence of one or more Arab digits)
   sequence="${1}"
   error_code=0 # any value greater than zero is an error code
   result="$(echo "${sequence}" | sed -n /^[[:digit:]][[:digit:]]*$/p)"
   if [ -z "${result}" ]
   then
      echo "[ERR] ${sequence} is not a positive integer"
      error_code=1
   fi
   return ${error_code}
}

current_octet=1 # indicates the position (starting from 1) of the current octet
for octet in ${octets}
do
   is_digit_sequence "${octet}"
   status_code=$?
   if [ ${status_code} -gt 0 ]
   then
      exit ${status_code}
   else
      if [ ${octet} -gt 255 ]
      then
         echo "[ERR] octet ${current_octet} exceeds 255"
         exit 2
      fi
      current_octet=$((${current_octet} + 1))
   fi
done

if [ ${current_octet} -ne 5 ]
then
   echo "[ERR] ${target} does not contain exactly four octets"
   exit 3
fi

exit 0
