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
		rm -f "${tmpfile}"
		curl -s -L "${url}" > "${tmpfile}"

		# Create list of URLs found matching our fileprefix
		myurls="$(cat "${tmpfile}" | sed -n -e '/<a href="/,/"/ { s:\([^/]*"\)\([^"]*/'"${fileprefix}"'[^"]*.tar.gz\)\(.*\):\2:p}' | sed  -e 's|^/|https://riverbankcomputing.com/|' )"
		



		# Detect release package links and extract version details
		#pkgrel="$(cat "${tmpfile}" | sed -n -e '/<a href="/,/"/ { s:\([^/]*"\)\(/[^"]*/'"${fileprefix}"'[^"]*.tar.gz\)\(.*\):https\://riverbankcomputing.com\2:p}' | grep -v '.dev')"
		#[ -n "${pkgrel}" ] || pkgrel="$(cat "${tmpfile}" | sed -ne '/<a href="/,/"/ { s:\([^/]*"\)\(http[^"]*/'"${fileprefix}"'[^"]*.tar.gz\)\(.*\):\2:p}')"
		pkgrel="$(echo "${myurls}" | grep -v '\.dev.*\.tar\.gz')"
		pkgrelfn="${pkgrel##*/}"
		pkgrelver="${pkgrelfn#${fileprefix}-}" && pkgrelver="${pkgrelver%.tar.gz}"
		pkgrelportver="${pkgrelver}"
		printf -- "Release version: ${pkgrelver}\n"
		# Fetch release tarball if it exists
		[ -n "${pkgrel}" ] && ! [ -f "${pkgrelfn}" ] && wget "${pkgrel}"

		# Detect dev package links and extract version details
		#pkgdev="$(cat "${tmpfile}" | sed -ne '/<a href="/,/"/ { s:\([^/]*"\)\(/[^"]*/'"${fileprefix}"'[^"]*.dev[^"]*.tar.gz\)\(.*\):\2:p}')"
		pkgdev="$(echo "${myurls}" | grep  '\.dev.*\.tar\.gz')"
		pkgdevfn="${pkgdev##*/}"
		pkgdevver="${pkgdevfn#${fileprefix}-}" && pkgdevver="${pkgdevver%.tar.gz}"
		pkgdevportver="${pkgdevver/.dev/_pre}"
		printf -- "Dev version: ${pkgdevver}\n"
		# Fetch dev tarball if it exists
		#[ -n "${pkgdev}" ] && ! [ -f "${pkgdevfn}" ]  && wget "https://www.riverbankcomputing.com${pkgdev}"
		[ -n "${pkgdev}" ] && ! [ -f "${pkgdevfn}" ]  && wget "${pkgdev}"


		# If the cat pkg dir exists, change to it, handle ebuild updates.
		if [ -d "${REPO_TOP}/${catpkg}" ] ; then
			pushd "${REPO_TOP}/${catpkg}" > /dev/null || die 'Can not change to directory ' "${REPO_TOP}/${catpkg}"

				# Detect existing release ebuild
				reloldebuild="$( set +f; echo "${catpkg#*/}-"*.ebuild | tr ' ' '\n' | grep -v -e "\*" -e "_pre" -e "9999" | sort -V | tail -1 )"
				if [ -n "${reloldebuild}" ] ; then
					reloldebuildver="${reloldebuild%.ebuild}" && reloldebuildver="${reloldebuildver#${catpkg#*/}-}"
					printf -- '\nOld release ebuild: %s\n' "${catpkg}/${reloldebuild}"
				else
					reloldebuildver=""
					printf -- '\nNo existing release ebuild found.'
				fi

				# Detect existing dev ebuild
				devoldebuild="$( set +f; echo "${catpkg#*/}"-*_pre*.ebuild | tr ' ' '\n' | grep -v -e "\*" -e "9999" | sort -V | tail -1 )"
				if [ -n "${devoldebuild}" ] ; then
					devoldebuildver="${devoldebuild%.ebuild}" && devoldebuildver="${devoldebuildver#${catpkg#*/}-}"
					printf -- '\nOld dev ebuild: %s\n' "${catpkg}/${devoldebuild}"
				else
					devoldebuildver=""
					printf -- '\nNo existing dev ebuild found.'
				fi

				# Handle release versions, if they exist
				myupdatestr=""
				mycleanupstr=""
				if [ -n "${pkgrelver}" ] ; then
					# Determine new release ebuild information
					relnewebuild="${catpkg#*/}-${pkgrelportver}.ebuild"
					printf -- 'New release ebuild: %s\n' "${catpkg}/${relnewebuild}"
					if [ "${reloldebuild}" = "${relnewebuild}" ] ; then
						printf -- 'Match, no update needed.\n'
					else
						printf -- 'Mismatch, update needed.\n'
						# If this is the stabilization of our previous prerelease, copy and remove old.
						if [ "${devoldebuildver%_pre*}" == "${pkgrelportver}" ] ; then
							myupdatestr="cp \"${REPO_TOP}/${catpkg}/${devoldebuild}\" \"${REPO_TOP}/${catpkg}/${relnewebuild}\""
							mycleanupstr="rm \"${REPO_TOP}/${catpkg}/${devoldebuild}\""
						# otherwise, if we have one, copy over our previous release ebuild.
						elif [ -n "${reloldebuild}" ] ; then
							myupdatestr="cp \"${REPO_TOP}/${catpkg}/${reloldebuild}\" \"${REPO_TOP}/${catpkg}/${relnewebuild}\""
						# othewise, if there is an old dev ebuild with a different version, grab that.
						elif [ -n "${devoldebuild}" ] ; then
							myupdatestr="cp \"${REPO_TOP}/${catpkg}/${devoldebuild}\" \"${REPO_TOP}/${catpkg}/${relnewebuild}\""
						else
						# Failing all of that, print message that manual intervention is required.
							printf -- 'NOTICE: No viable source ebuild found to update "%s" to "%s", please create "%s"!\n' "${catpkg}" "${pkgrelportver}" "${relnewebuild}"
						fi
					fi
				fi
				[ -n "${myupdatestr}" ] && UPDATE_STR="$(printf -- '%s\n%s' "${UPDATE_STR}" "${myupdatestr}")"
				[ -n "${mycleanupstr}" ] && CLEANUP_STR="$(printf -- '%s\n%s' "${CLEANUP_STR}" "${mycleanupstr}")"

				# Handle dev versions, if they exist
				myupdatestr=""
				mycleanupstr=""
				if [ -n "${pkgdevver}" ] ; then
					# Determine new dev ebuild information
					devnewebuild="${catpkg#*/}-${pkgdevportver}.ebuild"
					printf -- 'New dev ebuild: %s\n' "${catpkg}/${devnewebuild}"
					# If versions match, we're done
					if [ "${devoldebuild}" = "${devnewebuild}" ] ; then
						printf -- 'Match, no update needed.\n'
					# If they don't, 
					else
						printf -- 'Mismatch, update needed.\n'
						# If we are already following the dev branch, just bump version with a move.
						if [ -n "${devoldebuild}" ] ; then
							myupdatestr="cp \"${REPO_TOP}/${catpkg}/${devoldebuild}\" \"${REPO_TOP}/${catpkg}/${devnewebuild}\""
							mycleanupstr="rm \"${REPO_TOP}/${catpkg}/${devoldebuild}\""
						# Othewise, if there is a previous release ebuild, copy that over.
						elif [ -n "${reloldebuild}" ] ; then
							myupdatestr="cp \"${REPO_TOP}/${catpkg}/${reloldebuild}\" \"${REPO_TOP}/${catpkg}/${devnewebuild}\""
							mycleanupstr="rm \"${REPO_TOP}/${catpkg}/${devoldebuild}\""
						# Failing that, print message that manual intervention is required.
							printf -- 'NOTICE: No viable source ebuild found to update "%s" to "%s", please create "%s"!\n' "${catpkg}" "${pkgdevportver}" "${devnewebuild}"
						fi
					fi
				# Clean up previous dev ebuild if we don't have any dev release.
				elif [ -n "${devoldebuild}" ] ; then
							mycleanupstr="rm \"${REPO_TOP}/${catpkg}/${devoldebuild}\""
				fi

				[ -n "${myupdatestr}" ] && UPDATE_STR="$(printf -- '%s\n%s' "${UPDATE_STR}" "${myupdatestr}")" ; myupdatestr=""
				[ -n "${mycleanupstr}" ] && CLEANUP_STR="$(printf -- '%s\n%s' "${CLEANUP_STR}" "${mycleanupstr}")" ; mycleanupstr=""

			popd > /dev/null || die
		else
			printf -- "\nNOTE: catpkg directory '${catpkg}' not found under repo at '${REPO_TOP}'.\n"
		fi

	done < "${RBC_UD_SWLIST}"
popd > /dev/null || die
printf -- '\n\n# Run the following commands to update all rbc ebuilds:\n'
printf -- '%s\n' "${UPDATE_STR}" | sort -u
printf -- '%s\n' "${CLEANUP_STR}" | sort -u
printf -- '\ncd "%s"\n' "${REPO_TOP}"
printf -- '\ngit add %s\n' "$(printf -- '%s\n%s\n' "${UPDATE_STR}" "${CLEANUP_STR}" | sort -u | sed -e 's/^cp //' -e 's/^rm //' -e 's|"'"${REPO_TOP}"'/|"|g' | tr '\n' ' ')"
printf -- '\ngit commit -m "PyQt/qscintilla: All RBC packages updated using tools/riverbankcomputing.com/updater.sh"\n'
printf -- '\ncd -\n'

