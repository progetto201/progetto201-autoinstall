# colors
GREEN='\033[0;32m' # Green
RED='\033[0;31m'   # Red
NC='\033[0m'       # No Color


logger(){
    # Logs and echoes debug messages.
    #
    # The software name $1 is echoed in green if $3 is true,
    # if $3 is false the software name is echoed in a red color.
    #
    # The message is also echoed and the timestamp, software name and message are 
    # logged inside the $4 file.
    #
    # If $3 is false the message also contains the exit code ($5) of the last executed command
    # and is echoed and written to the log file.
    # > the $5 param is not required
    # 
    # Params:
    # * software = "$1"  : software name related to the message
    # * message = "$2"   : debug message
    # * success = "$3"   : true if previous action was successful, false otherwise
    # * output = "$4"    : path of the log file 
    # * error = "${5:-}" : exit code of the previous command

    # save the parameters
    local software="$1"
    local message="$2"
    local success="$3"
    local output="$4"
    local error="${5:-}"

    # get the current timestamp
    currenttime=$(date +%s)

    # choose the color of the software name depending on the success of the previous command exec
    if $success ; then
        printf "${GREEN}"
    else
        printf "${RED}"
    fi

    # echo the software and the message to the terminal
    printf "\n[${software}]${NC} ${message}"
    
    # save a record to the log file with timestamp, software and message
    printf "${currenttime} [${software}] ${message}" >> ${output}

    # if the command exec wasn't successful, echo and write the error code
    if ! $success ; then
        printf " - error ${error}"
        printf " - error ${error}" >> ${output}
    fi

    # print and echo the next line char
    printf " \n\n"
    printf " \n" >> ${output}
}