# a simple awk script that analyzes a machine-readable line extracted from the output of the print command
# implemented by the parted utility;
# if the first field identifies a linux block device, both its nominal size  and its physical block size will be extracted;
# if the first field identifies a partition, both its start and end offsets will be extracted;
# a third value will be returned: the number of fields contained within the input record;
# if the values cannot be extracted, 0 will be set for both of them
BEGIN {first_value = "0"
       second_value = "0"
      }
$1 ~ /^\/dev/  { first_value = $2
                 second_value = $5
               }
$1 ~/^[1-9][[:digit:]]*$/ { first_value = $2
                            second_value = $3
                          }
END { if (match(first_value, /^[[:digit:]]+/)) {
         first_value = substr(first_value, RSTART, RLENGTH)
      }
      if (match(second_value, /^[[:digit:]]+/)) {
         second_value = substr(second_value, RSTART, RLENGTH)
      }
      print first_value, second_value, NF
    }
