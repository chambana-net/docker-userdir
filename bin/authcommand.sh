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

USERFILE=./users.yml
USER="$1"
HOMEDIR=/home
CREATEHOME=no
ARGS=" -U -b $HOMEDIR "


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

[[ -d "${HOMEDIR}/${USER}" ]] || CREATEHOME=yes

getent passwd "$USER" 2&>1
if [[ $? -ne 0 ]]; then
	gecosvar="users_${USER}_gecos"
	[[ -v "$gecosvar" ]] && ARGS+=" -c ${!gecosvar} "
	uidvar="users_${USER}_uid"
	[[ -v "$uidvar" ]] && ARGS+=" -u ${!uidvar} "
	gidvar="users_${USER}_gid"
	[[ -v "$gidvar" ]] && ARGS+=" -g ${!gidvar} "
	shellvar="users_${USER}_shell"
	[[ -v "$shellvar" ]] && ARGS+=" -g ${!shellvar} "
	[[ "$CREATEHOME" == yes ]] && ARGS+=" -m "

	#Add user, then print key and exit.
	useradd "$ARGS" "$USER" 2&>1
	#Exit if couldn't create user.
	[[ $? -eq 0 ]] || exit 1 
	echo "${!keyvar}"
	exit 0
fi

#User exists but there's no home directory.
[[ "$CREATEHOME" == yes ]] && { mkdir -p "${HOMEDIR}/${USER}" 2&>1; chown -R "${USER}:${USER}" "${HOMEDIR}/${USER}" 2&>1; } 
echo "${!keyvar}"
exit 0
