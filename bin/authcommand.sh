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

set -o nounset # Treat unset variables as an error

#Check to make sure argument is provided
#[[ -v "1" ]] || exit 1

USERFILE=/etc/ssh/auth/users.yml
USER="$1"

# Improved parse_yaml from https://github.com/jasperes/bash-yaml, credit to Jonathan Peres
parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @ | tr @ '\034')"

    (
        sed -e '/- [^\“]'"[^\']"'.*: /s|\([ ]*\)- \([[:space:]]*\)|\1-\'$'\n''  \1\2|g' |
            sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/[[:space:]]*$//g;' \
                -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
                -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
                -e "s|^\($s\)\($w\)${s}[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
            awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |
            sed -e 's/_=/+=/g' |
            awk 'BEGIN {
                FS="=";
                OFS="="
            }
            /(-|\.).*=/ {
                gsub("-|\\.", "_", $1)
            }
            { print }'
    ) <"$yaml_file"
}

create_variables() {
    local yaml_file="$1"
    local prefix="$2"
    eval "$(parse_yaml "$yaml_file" "$prefix")"
}

create_variables "$USERFILE" "users_"

declare -n keyvar="users_${USER}_keys"

# Echo key and exit.
for k in "${keyvar[@]}"; do
    echo "$k"
done
exit 0
