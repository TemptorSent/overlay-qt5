# Distributed under the terms of the GNU General Public License v2

EAPI=6

CMAKE_IN_SOURCE_BUILD="1"
PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

inherit cmake-utils python-r1 virtualx eapi7-ver
TARBALL="pyside-setup-everywhere-src-${PV}"
DESCRIPTION="PySide development tools (lupdate, rcc, uic)"
HOMEPAGE="https://wiki.qt.io/PySide2"
SRC_URI="http://download.qt.io/official_releases/QtForPython/pyside2/PySide2-${PV}-src/${TARBALL}.tar.xz"

# Although "LICENSE-uic" suggests the "pyside2uic" directory to be dual-licensed
# under the BSD 3-clause and GPL v2 licenses, this appears to be an oversight;
# all files in this (and every) directory are licensed only under the GPL v2.
LICENSE="GPL-2"
SLOT="2/2.0.0"
KEYWORDS="*"
IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# The "pyside2uic" package imports both the "PySide2.QtGui" and
# "PySide2.QtWidgets" C extensions and hence requires "gui" and "widgets".
RDEPEND="
	${PYTHON_DEPS}
	=dev-python/pyside2-${PV}:$(ver_cut 1-2)[gui,widgets,${PYTHON_USEDEP}]
	=dev-python/shiboken2-${PV}:$(ver_cut 1-2)[${PYTHON_USEDEP}]
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtwidgets:5
"
DEPEND="${RDEPEND}
	test? ( virtual/pkgconfig )
"
S="${WORKDIR}/${TARBALL}/sources/${PN}"

src_prepare() {
	cmake-utils_src_prepare

	python_copy_sources

	preparation() {
		pushd "${BUILD_DIR}" >/dev/null || die

		if python_is_python3; then
			# Remove Python 2-specific paths.
			rm -rf pyside2uic/port_v2 || die

			# Generate proper Python 3 test interfaces with the "-py3" option.
			sed -i -e 's:${PYSIDERCC_EXECUTABLE}:"${PYSIDERCC_EXECUTABLE} -py3":' \
				tests/rcc/CMakeLists.txt || die
		else
			# Remove Python 3-specific paths.
			rm -rf pyside2uic/port_v3 || die
		fi

		# Force testing against the current Python version.
		sed -i -e "/pkg-config/ s:shiboken2:&-${EPYTHON}:" \
			tests/rcc/run_test.sh || die

		popd >/dev/null || die
	}
	python_foreach_impl preparation
}

src_configure() {
	configuration() {
		local mycmakeargs=(
			# Broken cfgs from shiboken2, fix before slotting: -DENABLE_VERSION_SUFFIX=TRUE
			-DBUILD_TESTS=$(usex test)
			-DPYTHON_EXECUTABLE="${PYTHON}"
			-DPYTHON_SITE_PACKAGES="$(python_get_sitedir)"
		)

		# Find the previously installed "Shiboken2Config.*.cmake" and
		# "PySide2Config.*.cmake" files specific to this Python version.
		if python_is_python3; then
			# Extension tag unique to the current Python 3.x version (e.g.,
			# ".cpython-34m" for CPython 3.4).
			local EXTENSION_TAG="$("$(python_get_PYTHON_CONFIG)" --extension-suffix)"
			EXTENSION_TAG="${EXTENSION_TAG%.so}"

			mycmakeargs+=( -DPYTHON_CONFIG_SUFFIX="${EXTENSION_TAG}" )
		else
			mycmakeargs+=( -DPYTHON_CONFIG_SUFFIX="-python2.7" )
		fi

		CMAKE_USE_DIR="${BUILD_DIR}" cmake-utils_src_configure
	}
	python_foreach_impl configuration
}

src_compile() {
	compilation() {
		CMAKE_USE_DIR="${BUILD_DIR}" cmake-utils_src_compile
	}
	python_foreach_impl compilation
}

#src_test() {
#	local -x PYTHONDONTWRITEBYTECODE
#	
#	testing() {
#		CMAKE_USE_DIR="${BUILD_DIR}" virtx cmake-utils_src_test
#	}
#	python_foreach_impl testing
#}

src_install() {
	installation() {
		CMAKE_USE_DIR="${BUILD_DIR}" cmake-utils_src_install
	}
	python_foreach_impl installation
}
