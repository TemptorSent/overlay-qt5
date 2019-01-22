RBC_UD_DIR="/tmp/rbc_updater"
mkdir -p "${RBC_UD_DIR}"
pushd "${RBC_UD_DIR}"
	while read -r pkg fileprefix url; do
		printf -- "\nUpdating ${pkg}:\n"
		tmpfile="${RBC_UD_DIR}/${pkg}.html"
		rm "${tmpfile}"
		curl "${url}" > "${tmpfile}"
		pkgrel="$(cat "${tmpfile}" | sed -ne '/<a href="/,/"/ { s:\([^/]*"\)\(http[^"]*/'"${fileprefix}"'[^"]*.tar.gz\)\(.*\):\2:p}')"
		[ -n "${pkgrel}" ] && ! [ -f "${pkgrel##*/}" ] && wget "${pkgrel}"

		pkgdev="$(cat "${tmpfile}" | sed -ne '/<a href="/,/"/ { s:\([^/]*"\)\(/[^"]*/'"${fileprefix}"'[^"]*.dev[^"]*.tar.gz\)\(.*\):\2:p}')"
		[ -n "${pkgdev}" ] && ! [ -f "${pkgdev##*/}" ]  && wget "https://www.riverbankcomputing.com${pkgdev}"
	done
popd
