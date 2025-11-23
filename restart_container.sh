# Author: Pavlo Nykolyn
# restarting a container
# the only input parameter is the name of the container

if [ $# -ne 1 ]
then
   echo "[ERR] the program requires one input argument"
   exit 1
fi

container_name="${1}"
# checking whether the current corresponds to a running container
container_test=$(docker ps --filter "name=^${container_name}$" --filter 'status=running' | wc --lines)
if [ ${container_test} -eq 2 ]
then
   # performing the restart
   docker stop "${container_name}"
   sleep 2s
   docker start "${container_name}"
else
   echo "[ERR] ${container_name} either is not running or does not exist"
fi
