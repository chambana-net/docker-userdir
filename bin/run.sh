#!/bin/bash -

. /app/lib/common.sh

CHECK_BIN "jekyll"
CHECK_BIN "git"
CHECK_BIN "bundle"
CHECK_BIN "a2ensite"
CHECK_BIN "a2enmod"
CHECK_VAR JEKYLL_GITHUB_USER
CHECK_VAR JEKYLL_GITHUB_REPO

MSG "Cloning repository..."
git clone -b ${JEKYLL_GITHUB_BRANCH} --single-branch https://github.com/${JEKYLL_GITHUB_USER}/${JEKYLL_GITHUB_REPO} /tmp/www
[[ $? -eq 0 ]] || {
	ERR "Failed to clone repository, aborting."
	exit 1
}
[[ -d /tmp/www/${JEKYLL_GITHUB_SUBDIR} ]] || {
	ERR "Subdirectory $JEKYLL_GITHUB_SUBDIR does not exist, aborting."
	exit 1
}

MSG "Installing site..."
cd /tmp/www/${JEKYLL_GITHUB_SUBDIR}
[[ -e /tmp/www/${JEKYLL_GITHUB_SUBDIR}/Gemfile ]] && bundle install
jekyll build -d /var/www/html
chown -R www-data:www-data /var/www/html
cd /
rm -rf /tmp/www

MSG "Cleaning Apache logs..."
rm -rf /var/log/apache2/*
ln -sf /var/log/apache2/access.log /dev/stdout
ln -sf /var/log/apache2/error.log /dev/stderr

MSG "Configuring Apache..."
a2ensite 000-default.conf
a2enmod userdir

MSG "Create sshd run directory..."
mkdir /var/run/sshd

MSG "Creating users..."
USERFILE=/etc/ssh/auth/users.yml
HOMEDIR=/home

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

for USER in $(compgen -v | grep ^users_.*_keys | cut -d _ -f 2); do
	ARGS=" -U -b $HOMEDIR "
	CREATEHOME=no
	[[ -d "${HOMEDIR}/${USER}" ]] || CREATEHOME=yes

	getent passwd "$USER" 2 &>1
	if [[ $? -ne 0 ]]; then
		#If user doesn't exist
		MSG "Creating user: $USER"
		gecosvar="users_${USER}_gecos"
		[[ -v "$gecosvar" ]] && ARGS+=" -c ${!gecosvar} "
		uidvar="users_${USER}_uid"
		[[ -v "$uidvar" ]] && ARGS+=" -u ${!uidvar} "
		gidvar="users_${USER}_gid"
		[[ -v "$gidvar" ]] && ARGS+=" -g ${!gidvar} "
		shellvar="users_${USER}_shell"
		[[ -v "$shellvar" ]] && ARGS+=" -s ${!shellvar} "
		[[ "$CREATEHOME" == yes ]] && ARGS+=" -m "

		#Add user, then print key and exit.
		/usr/sbin/useradd $ARGS $USER
	fi
done

MSG "Starting services..."

exec "$@"
