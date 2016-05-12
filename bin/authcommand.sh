#!/bin/bash - 
#===============================================================================
#
#          FILE: authcommand.sh
# 
#         USAGE: ./authcommand.sh <username>
# 
#   DESCRIPTION: User creation script to be run by OpenSSH AuthorizedKeysCommand
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Josh King (jking@chambana.net) 
#  ORGANIZATION: 
#       CREATED: 05/10/2016 10:41
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#Check to make sure argument is provided
#[[ -v "1" ]] || exit 1

USERFILE=/etc/ssh/auth/users.yml
USER="$1"

parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml "$USERFILE" "users_")

keyvar="users_${USER}_key"
# Exit if key is not defined for this user.
[[ -v "$keyvar" ]] || exit 1

# Echo key and exit.
echo "${!keyvar}"
exit 0
