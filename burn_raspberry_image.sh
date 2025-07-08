# Author: Pavlo Nykolyn
# a simple script that burns an OS image onto a block device (a microSD in this case).
# It uses dd for the purpose;
# I've made it mainly for raspberry images but, it can be modified to suit different requirements;
# it needs two input parameters:
# - the block device (its absolute path);
# - the path to the image file;

function impress
{
   # the first positional argument should be a prefix, indicating the message type
   # the second positional argument is the message itself
   echo "--- $(date) --- ${1} ${2}"
}

if [ $# -ne 2 ]
then
   impress '[ERR]' 'two input argument are required to launch the script'
fi

block_device=${1}
if [ ! -b "${block_device}" ]
then
   impress '[ERR]' "${1} either does not exist or is not a block device"
   exit 1
fi

image_path=${2}
if [ ! -f "${image_path}" ]
then
   impress '[ERR]' "${2} either does not exist or is not an image file"
   exit 1
fi

# disabling the udev daemon in order to inhibit auto-mount;
# sockets that may reactivate the service are also brought down
sudo systemctl stop systemd-udevd-kernel.socket
sudo systemctl stop systemd-udevd-control.socket
sudo systemctl stop systemd-udevd.service

# I've not added options to dd that manage the amount of bytes that are transferred during the operation, as the default values employed by dd seems to do just fine on a microSD
xz --to-stdout --decompress "${image_path}" | sudo dd status=progress "of=${block_device}"

# reactivating the udev daemon and its associated sockets
sudo systemctl start systemd-udevd-kernel.socket
sudo systemctl start systemd-udevd-control.socket
sudo systemctl start systemd-udevd.service
