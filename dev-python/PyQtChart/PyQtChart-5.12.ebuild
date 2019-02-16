# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )
inherit multibuild python-r1 qmake-utils

DESCRIPTION="Python bindings for the Qt3D under the Qt framework"
HOMEPAGE="https://www.riverbankcomputing.com/software/pyqt3d/intro"

MY_P=${PN}_gpl-${PV/_pre/.dev}
if [[ ${PV} == *_pre* ]]; then
	SRC_URI="https://www.riverbankcomputing.com/static/Downloads/${PN}/${MY_P}.tar.gz"
else
	SRC_URI="mirror://sourceforge/pyqt/${MY_P}.tar.gz"
fi

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ~ppc64 x86"

IUSE="${IUSE} debug"

# The requirements below were extracted from configure.py
# and from the output of 'grep -r "%Import " "${S}"/sip'
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
"

# Minimal supported version of Qt.
QT_PV="5.9.4:5"

RDEPEND="
	${PYTHON_DEPS}
	>=dev-python/sip-4.19.4:=[${PYTHON_USEDEP}]
	>=dev-python/PyQt5-${PV/_pre*/_pre}
	>=dev-qt/qtcharts-${QT_PV}
"

S="${WORKDIR}/${MY_P}"

DOCS=( "${S}"/{ChangeLog,NEWS} )

src_prepare() {
	default
	python_copy_sources
}

src_configure() {
	configuration() {
		local myconf=(
			"${PYTHON}"
			"${S}"/configure.py
			$(usex debug '--debug --qml-debug --trace' '')
			--verbose
			--qmake="$(qt5_get_bindir)"/qmake
			--no-dist-info
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
		MAKOPTS="-j1" emake install INSTALL_ROOT="${ED}" DESTDIR="${ED}"
		local myroot="${WORKDIR}/${P}-${EPYTHON}-imagetmp"
		mkdir -p "${myroot}"
		( set +f ; mv "${D}"/* "${myroot}" )
		multibuild_merge_root "${myroot}" "${D}"
		python_optimize
	}
	python_foreach_impl run_in_build_dir installation

	einstalldocs
}
