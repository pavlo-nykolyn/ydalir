# Author: Pavlo Nykolyn
# removes the compiled python files and the associated __pycache__ directory(ies)

function impress
{
   # the first positional argument should be a prefix, indicating the message type
   # the second positional argument is the message itself
   echo "--- $(date) --- ${1} ${2}"
}

if [ $# -ne 1 ]
then
   impress '[ERR]' 'a single input argument is required to launch the script'
fi

project_root=${1}
if [ ! -d "${project_root}" ]
then
   impress '[ERR]' "${1} either does not exist or is not a directory"
   exit 1
fi

# removing the compiled files
find ${project_root} -regextype 'posix-awk' -a -regex '.*\.pyc' -a exec rm \{\} \;
# removing the __pycache__ directories
find ${project_root} -regextype 'posix-awk' -a -type 'd' -a -regex '.*__pycache__' -a exec rmdir \{\} \;
