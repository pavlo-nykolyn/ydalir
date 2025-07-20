# Author: Pavlo Nykolyn
# checks the connections managed by network-manager
# each line returned by the connection sub-command shall contain the following fields:
# NAME;
# UUID;
# STATE
# the caller SHALL define the following variables:
# identifier_type -> SHALL BE an element of {"id", "uuid"}
# target -> the identifier itself
BEGIN { type_idx = index(identifier_type, "id")
        type_id = -1 # should never occur
        if (type_idx == 1)
           type_id = 0 # using the connection name
        else {
           type_idx = index(identifier_type, "uuid")
           if (type_idx == 1)
              type_id = 1 # using the connection UUID
        }
      }
# all input records will be analyzed
{ source = ""
  status = $3 
  if (type_id == 0)
     source = $1
  else if (type_id == 1)
     source = $2
  current_index = index(source, target)
  status_index = index(status, "activated")
  if (current_index > 0 &&
      status_index == 1)
     # the use of a user-friendly name may result in multiple matches. The STATE field
     # is used to differentiate between different connection instances that share the
     # same user-friendly name
     print source
}
