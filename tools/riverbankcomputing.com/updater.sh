die() {
	printf -- '\n%s\n' "$*"
	exit 1
}


REPO_TOP="$(realpath "${PWD}")"
RBC_UD_TOOL_DIR="${REPO_TOP}/tools/riverbankcomputing.com"
RBC_UD_SWLIST="${RBC_UD_TOOL_DIR}/swlist"

if ! [ -f "${RBC_UD_SWLIST}" ] ; then
	die '\nPlease run this tool from the top level of the Qt repository containing the riverbankcomputing.com updater and ebuilds.'
fi

RBC_UD_TMP_DIR="/tmp/rbc_updater"
mkdir -p "${RBC_UD_TMP_DIR}" || die 'Can not make directory ' "${RBC_UD_TMP_DIR}"

UPDATE_STR=""

# Using our tmp dir for working in, fetch updated upstream packages for all software in swlist
pushd "${RBC_UD_TMP_DIR}" > /dev/null || die
	# swlist format is tab delimited
	while read -r catpkg pkg fileprefix url; do
		# Skip comments
		[[ "${catpkg}" == "#"* ]] && continue

		# Grab download page html after removing any stale versions.
		printf -- "\nUpdating ${pkg}:\n"
		tmpfile="${RBC_UD_TMP_DIR}/${pkg}.html"
		rm "${tmpfile}"
		curl -s -L "${url}" > "${tmpfile}"

		# Detect release package links and extract version details
		pkgrel="$(cat "${tmpfile}" | sed -ne '/<a href="/,/"/ { s:\([^/]*"\)\(http[^"]*/'"${fileprefix}"'[^"]*.tar.gz\)\(.*\):\2:p}')"
		pkgrelfn="${pkgrel##*/}"
		pkgrelver="${pkgrelfn#${fileprefix}-}" && pkgrelver="${pkgrelver%.tar.gz}"
		pkgrelportver="${pkgrelver}"
		printf -- "Release version: ${pkgrelver}\n"
		# Fetch release tarball if it exists
		[ -n "${pkgrel}" ] && ! [ -f "${pkgrelfn}" ] && wget "${pkgrel}"

		# Detect dev package links and extract version details
		pkgdev="$(cat "${tmpfile}" | sed -ne '/<a href="/,/"/ { s:\([^/]*"\)\(/[^"]*/'"${fileprefix}"'[^"]*.dev[^"]*.tar.gz\)\(.*\):\2:p}')"
		pkgdevfn="${pkgdev##*/}"
		pkgdevver="${pkgdevfn#${fileprefix}-}" && pkgdevver="${pkgdevver%.tar.gz}"
		pkgdevportver="${pkgdevver/.dev/_pre}"
		printf -- "Dev version: ${pkgdevver}\n"
		# Fetch dev tarball if it exists
		[ -n "${pkgdev}" ] && ! [ -f "${pkgdevfn}" ]  && wget "https://www.riverbankcomputing.com${pkgdev}"

		# If the cat pkg dir exists, change to it, handle ebuild updates.
		if [ -d "${REPO_TOP}/${catpkg}" ] ; then
			pushd "${REPO_TOP}/${catpkg}" > /dev/null || die 'Can not change to directory ' "${REPO_TOP}/${catpkg}"

				# Handle release versions, if they exist
				if [ -n "${pkgrelver}" ] ; then
					# Detect existing release ebuild
					reloldebuild="$( set +f; echo "${catpkg#*/}-"*.ebuild | tr ' ' '\n' | grep -v -e "\*" -e "_pre" -e "9999" | sort -V | tail -1 )"
					if [ -n "$reloldebuild" ] ; then
						printf -- '\nOld release ebuild: %s\n' "${reloldebuild}"
					else
						printf -- '\nNo existing release ebuild found.'
					fi
					# Determine new release ebuild information
					relnewebuild="${catpkg#*/}-${pkgrelportver}.ebuild"
					printf -- 'New release ebuild: %s\n' "${relnewebuild}"
					if [ "${reloldebuild}" = "${relnewebuild}" ] ; then
						printf -- 'Match, no update needed.\n'
					else
						printf -- 'Mismatch, update needed.\n'
						cpstring="cp \"${REPO_TOP}/${catpkg}/${devoldebuild}\" \"${REPO_TOP}/${catpkg}/${devnewebuild}\""
						UPDATE_STR="$(printf -- '%s\n%s' "${UPDATE_STR}" "${cpstring}")"
						cpstring=""
					fi
				fi

				# Handle dev versions, if they exist
				if [ -n "${pkgdevver}" ] ; then
					# Detect existing dev ebuild
					devoldebuild="$( set +f; echo "${catpkg#*/}-${pkgdevver%.dev*}_pre"*.ebuild | tr ' ' '\n' | grep -v -e "\*" | sort -V | tail -1 )"
					if [ -n "$devoldebuild" ] ; then
						printf -- '\nOld dev ebuild: %s\n' "${catpkg}/${devoldebuild}"
					else
						printf -- '\nNo existing dev ebuild found.'
					fi
					# Determine new dev ebuild information
					devnewebuild="${catpkg#*/}-${pkgdevportver}.ebuild"
					printf -- 'New dev ebuild: %s\n' "${catpkg}/${devnewebuild}"
					if [ "${devoldebuild}" = "${devnewebuild}" ] ; then
						printf -- 'Match, no update needed.\n'
					else
						printf -- 'Mismatch, update needed.\n'
						mvstring="mv \"${REPO_TOP}/${catpkg}/${devoldebuild}\" \"${REPO_TOP}/${catpkg}/${devnewebuild}\""
						UPDATE_STR="$(printf -- '%s\n%s' "${UPDATE_STR}" "${mvstring}")"
						mvstring=""
					fi
				fi
			popd > /dev/null || die
		else
			printf -- "\nNOTE: catpkg directory '${catpkg}' not found under repo at '${REPO_TOP}'.\n"
		fi

	done < "${RBC_UD_SWLIST}"
popd > /dev/null || die

printf -- '%s\n' "${UPDATE_STR}"
