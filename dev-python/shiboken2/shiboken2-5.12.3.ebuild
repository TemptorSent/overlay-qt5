# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

inherit cmake-utils llvm python-r1 eapi7-ver
TARBALL_VER=pyside-setup-everywhere-src-${PV}
DESCRIPTION="Tool for creating Python bindings for C++ libraries"
HOMEPAGE="https://wiki.qt.io/PySide2"
SRC_URI="http://download.qt.io/official_releases/QtForPython/pyside2/PySide2-${PV}-src/${TARBALL_VER}.tar.xz"

# The "sources/shiboken2/libshiboken" directory is triple-licensed under the GPL
# v2, v3+, and LGPL v3. All remaining files are licensed under the GPL v3 with
# version 1.0 of a Qt-specific exception enabling shiboken2 output to be
# arbitrarily relicensed. (TODO)
LICENSE="|| ( GPL-2 GPL-3+ LGPL-3 ) GPL-3"
SLOT="$(ver_cut 1-2)/${PV}"
KEYWORDS="*"
IUSE=" test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# Minimum version of Qt required.
QT_PV="5.11.1:5"

DEPEND="
	${PYTHON_DEPS}
	dev-libs/libxml2
	dev-libs/libxslt
	>=dev-qt/qtcore-${QT_PV}
	>=dev-qt/qtxml-${QT_PV}
	>=dev-qt/qtxmlpatterns-${QT_PV}
	>=sys-devel/clang-3.9
	dev-python/numpy
"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${TARBALL_VER}/sources/shiboken2

DOCS=( AUTHORS )

# Ensure the path returned by get_llvm_prefix() contains clang as well.
llvm_check_deps() {
	has_version "sys-devel/clang:${LLVM_SLOT}"
}

src_prepare() {
	if use prefix; then
		cp "${FILESDIR}"/rpath.cmake . || die
		sed -i -e '1iinclude(rpath.cmake)' CMakeLists.txt || die
	fi

	# Fix Shiboken2Targets* to respect PYTHON_CONFIG_SUFFIX
	sed -e 's/Shiboken2Targets/&${PYTHON_CONFIG_SUFFIX}/' -i data/Shiboken2Config-spec.cmake.in || die
	sed -e '/install(EXPORT Shiboken2Targets/,/)/ { s/^[[:space:]]*DESTINATION/\tFILE "Shiboken2Targets${PYTHON_CONFIG_SUFFIX}.cmake"\n&/ }' -i libshiboken/CMakeLists.txt || die

	cmake-utils_src_prepare
}

src_configure() {
	if ! tc-is-clang; then
		# Force clang since gcc is pretty broken at the moment.
		CC=${CHOST}-clang
		CXX=${CHOST}-clang++
		strip-unsupported-flags
	fi
	configuration() {
		local mycmakeargs=(
			# Build system fixes needed before enabling this for slotting -DENABLE_VERSION_SUFFIX=TRUE
			-DBUILD_TESTS=$(usex test)
			-DPYTHON_EXECUTABLE="${PYTHON}"
			-DPYTHON_SITE_PACKAGES="$(python_get_sitedir)"
		)
		# CMakeLists.txt expects LLVM_INSTALL_DIR as an environment variable.
		LLVM_INSTALL_DIR="$(get_llvm_prefix)" cmake-utils_src_configure
	}
	python_foreach_impl configuration
}

src_compile() {
	python_foreach_impl cmake-utils_src_compile
}

src_test() {
	python_foreach_impl cmake-utils_src_test
}

src_install() {
	installation() {
		cmake-utils_src_install
		mv "${ED%/}/usr/$(get_libdir)/pkgconfig"/${PN}{,-${EPYTHON}}.pc || die
	}
	python_foreach_impl installation
}
