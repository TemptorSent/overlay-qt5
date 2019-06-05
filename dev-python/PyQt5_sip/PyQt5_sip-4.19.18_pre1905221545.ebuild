# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

inherit python-r1 toolchain-funcs

DESCRIPTION="Private sip for PyQt5 - Python extension module generator for C and C++ libraries"
HOMEPAGE="https://www.riverbankcomputing.com/software/sip/intro"

LICENSE="|| ( GPL-2 GPL-3 SIP )"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"

SIP_PN="sip"
MY_MOD="${PN%_${SIP_PN}}"
SIP_P="${SIP_PN}-${PV}"
if [[ ${PV} == *9999 ]]; then
	KEYWORDS=""
	SRC_URI=""
	inherit mercurial
	EHG_REPO_URI="https://www.riverbankcomputing.com/hg/sip"
elif [[ ${PV} == *_pre* ]]; then
	SIP_P="${SIP_P/_pre/.dev}"
	SRC_URI="https://www.riverbankcomputing.com/static/Downloads/sip/${SIP_P}.tar.gz"
else
	SRC_URI="https://www.riverbankcomputing.com/static/Downloads/sip/${PV}/${SIP_P}.tar.gz"
	#SRC_URI="mirror://sourceforge/pyqt/${SIP_P}.tar.gz"
fi

S="${WORKDIR}/${SIP_P}"

# Sub-slot based on SIP_API_MAJOR_NR from siplib/sip.h
SLOT="0/12"

IUSE="debug doc"

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	>=dev-python/${SIP_PN}-${PV}:=[${PYTHON_USEDEP}]
"
if [[ ${PV} == *9999 ]]; then
	DEPEND+="
		sys-devel/bison
		sys-devel/flex
		doc? ( dev-python/sphinx[$(python_gen_usedep 'python2*')] )"
fi

REQUIRED_USE="${PYTHON_REQUIRED_USE}"
if [[ ${PV} == *9999 ]]; then
	REQUIRED_USE+=" || ( $(python_gen_useflags 'python2*') )"
fi

PATCHES=( "${FILESDIR}"/${SIP_PN}-4.18-darwin.patch )

src_prepare() {
	if [[ ${PV} == *9999 ]]; then
		python_setup 'python2*'
		"${PYTHON}" build.py prepare || die
	fi

	# Sub-slot sanity check
	local sub_slot=${SLOT#*/}
	local sip_api_major_nr=$(sed -nre 's:^#define SIP_API_MAJOR_NR\s+([0-9]+):\1:p' siplib/sip.h || die)
	if [[ ${sub_slot} != ${sip_api_major_nr} ]]; then
		eerror
		eerror "Ebuild sub-slot (${sub_slot}) does not match SIP_API_MAJOR_NR (${sip_api_major_nr})"
		eerror "Please update SLOT variable as follows:"
		eerror "    SLOT=\"${SLOT%%/*}/${sip_api_major_nr}\""
		eerror
		die "sub-slot sanity check failed"
	fi

	default

	# Fix failure on python2 due to utf-8 encoded characters with no encoding set.
	grep -q "coding=utf-8" "${S}/configure.py"	|| sed -e '1i# coding=utf-8' -i "${S}/configure.py"
}

src_configure() {
	configuration() {
		if python_is_python3 ; then
			ADD_FLAGS=""
		else
			ADD_FLAGS=" -fno-strict-aliasing"
		fi

		local myconf=(
			"${PYTHON}"
			"${S}"/configure.py
			AR="$(tc-getAR) cqs"
			CC="$(tc-getCC)"
			CFLAGS="${CFLAGS}${ADD_FLAGS}"
			CFLAGS_RELEASE=
			CXX="$(tc-getCXX)"
			CXXFLAGS="${CXXFLAGS}${ADD_FLAGS}"
		#	CXXFLAGS_RELEASE=
			LINK="$(tc-getCXX)"
			LINK_SHLIB="$(tc-getCXX)"
			LFLAGS="${LDFLAGS}"
			LFLAGS_RELEASE=
			RANLIB=
			STRIP=
			$(usex debug --debug '')
			--sip-module=PyQt5.sip
			--no-tools
		)
		echo "${myconf[@]}"

		"${myconf[@]}" || die
	}
	python_foreach_impl run_in_build_dir configuration
}

src_compile() {
	python_foreach_impl run_in_build_dir default
}

src_install() {
	installation() {
		emake DESTDIR="${D}" install
		python_optimize
	}
	python_foreach_impl run_in_build_dir installation

}
