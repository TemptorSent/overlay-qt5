# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

CMAKE_MAKEFILE_GENERATOR=ninja

inherit llvm flag-o-matic python-r1 virtualx cmake-utils eapi7-ver


DESCRIPTION="Qt for Python - Python bindings for the Qt framework"
HOMEPAGE="https://wiki.qt.io/PySide2"
TARBALL="pyside-setup-everywhere-src-${PV}"
# See "sources/pyside2/PySide2/licensecomment.txt" for licensing details.
LICENSE="|| ( GPL-2 GPL-3+ LGPL-3 )"
SRC_URI="http://download.qt.io/official_releases/QtForPython/pyside2/PySide2-${PV}-src/${TARBALL}.tar.xz"
SLOT="$(ver_cut 1-2)/${PV}"
KEYWORDS="*"

IUSE="3d charts +concurrent datavis3d declarative designer +gui help location multimedia
	+network opengl positioning +printsupport script scripttools scxml sensors speech +sql svg
	+testlib webchannel webengine websockets +widgets +x11extras xmlpatterns"
# Excluded until webkit support is fixed: webkit

# Note: 'testlib' for qttest used above due to name conflict with 'test' for running tests.
IUSE="${IUSE} test"

# The requirements below were extracted from the output of
# 'grep "set(.*_deps" "${S}"/PySide2/Qt*/CMakeLists.txt'
REQUIRED_USE="
	gui
	widgets
	printsupport
	sql
	network
	testlib
	concurrent
	x11extras
	${PYTHON_REQUIRED_USE}
	3d? ( concurrent )
	charts? ( widgets )
	datavis3d? ( gui 3d )
	declarative? ( gui network )
	designer? ( widgets )
	help? ( widgets )
	multimedia? ( gui network )
	opengl? ( x11extras widgets )
	printsupport? ( widgets )
	scripttools? ( gui script widgets )
	speech? ( multimedia )
	sql? ( widgets )
	svg? ( widgets )
	testlib? ( widgets )
	webengine? ( gui network webchannel widgets )
	websockets? ( network )
	widgets? ( gui )
	x11extras? ( gui )
"
# Excluded until webkit support is fixed: webkit? ( gui network printsupport widgets )

# Minimum version of Qt required, derived from the CMakeLists.txt line:
#   find_package(Qt5 ${QT_PV} REQUIRED COMPONENTS Core)
QT_PV="${PV}:5"

CLANG_DEPS=">=sys-devel/clang-6"

DEPEND="
	${PYTHON_DEPS}
	${CLANG_DEPS}
	=dev-python/shiboken2-${PV}:${SLOT}[${PYTHON_USEDEP}]
	>=dev-qt/qtcore-${QT_PV}
	>=dev-qt/qtxml-${QT_PV}
	3d? ( >=dev-qt/qt3d-${QT_PV} )
	charts? ( >=dev-qt/qtcharts-${QT_PV} )
	concurrent? ( >=dev-qt/qtconcurrent-${QT_PV} )
	datavis3d? ( >=dev-qt/qtdatavis3d-${QT_PV} )
	declarative? ( >=dev-qt/qtdeclarative-${QT_PV}[widgets?] )
	designer? ( >=dev-qt/designer-${QT_PV} )
	gui? ( >=dev-qt/qtgui-${QT_PV} )
	help? ( >=dev-qt/qthelp-${QT_PV} )
	location? ( >=dev-qt/qtlocation-${QT_PV} )
	multimedia? ( >=dev-qt/qtmultimedia-${QT_PV}[widgets?] )
	network? ( >=dev-qt/qtnetwork-${QT_PV} )
	opengl? ( >=dev-qt/qtopengl-${QT_PV} )
	positioning? ( >=dev-qt/qtpositioning-${QT_PV} )
	printsupport? ( >=dev-qt/qtprintsupport-${QT_PV} )
	script? ( >=dev-qt/qtscript-${QT_PV} )
	scxml? ( >=dev-qt/qtscxml-${QT_PV} )
	sensors? ( >=dev-qt/qtsensors-${QT_PV} )
	speech? ( >=dev-qt/qtspeech-${QT_PV} )
	sql? ( >=dev-qt/qtsql-${QT_PV} )
	svg? ( >=dev-qt/qtsvg-${QT_PV} )
	testlib? ( >=dev-qt/qttest-${QT_PV} )
	webchannel? ( >=dev-qt/qtwebchannel-${QT_PV} )
	webengine? ( >=dev-qt/qtwebengine-${QT_PV}[widgets] )
	websockets? ( >=dev-qt/qtwebsockets-${QT_PV} )
	widgets? ( >=dev-qt/qtwidgets-${QT_PV} )
	x11extras? ( >=dev-qt/qtx11extras-${QT_PV} )
	xmlpatterns? ( >=dev-qt/qtxmlpatterns-${QT_PV} )
	test? (
		x11-base/xorg-server[xvfb]
		x11-apps/xhost
	)
"
# Excluded until webkit support is fixed: webkit? ( >=dev-qt/qtwebkit-${QT_PV}[printsupport] )

RDEPEND="${DEPEND}"

#PATCHES=( "${FILESDIR}/pyside2-5.11.1-qtgui-make-gl-time-classes-optional.patch" )

#S="${WORKDIR}/${TARBALL}"
S="${WORKDIR}/${TARBALL}/sources/${PN}"

PYSIDE2_QT_PKGS_USE_ESSENTIAL="
QtCore
QtGui gui
QtWidgets widgets
QtPrintSupport printsupport
QtSql sql
QtNetwork network
QtTest testlib
QtConcurrent concurrent
QtX11Extras x11extras
"
# Exclude until webkit support is fixed
#PYSIDE2_QT_PKGS_USE_WEBKIT="
#QtWebKit webkit
#QtWebKitWidgets webkit widgets
#"

PYSIDE2_QT_PKGS_USE_OPTIONAL="
QtXml
QtXmlPatterns xmlpatterns
QtHelp help
QtMultimedia multimedia
QtMultimediaWidgets multimedia widgets
QtOpenGL opengl
QtPositioning positioning
QtLocation location
QtQml declarative
QtQuick declarative
QtQuickWidgets declarative widgets
QtScxml scxml
QtScript script
QtScriptTools scripttools
QtSensors sensors
QtTextToSpeech speech
QtCharts charts
QtSvg svg
QtDataVisualization datavis3d
QtUiTools designer
QtWebChannel webchannel
QtWebEngineCore webengine
QtWebEngine webengine
QtWebEngineWidgets webengine widgets
${PYSIDE2_QT_PKGS_USE_WEBKIT}
QtWebSockets websockets
Qt3DCore 3d
Qt3DRender 3d
Qt3DInput 3d
Qt3DLogic 3d
Qt3DAnimation 3d
Qt3DExtras 3d
"


PYSIDE2_QT_PKGS_USE="
${PYSIDE2_QT_PKGS_USE_ESSENTIAL}
${PYSIDE2_QT_PKGS_USE_OPTIONAL}
"

src_prepare() {
	llvm_pkg_setup
	export LLVM_INSTALL_DIR="$(get_llvm_prefix)"
	export PATH="$(get_llvm_prefix):${PATH}"

	if use prefix; then
		cp "${FILESDIR}"/rpath.cmake . || die
		sed -i -e '1iinclude(rpath.cmake)' CMakeLists.txt || die
	fi

	# Exclude until webkit support is fixed (appears to be bit-rot)
	#if use webkit ; then
	if false ; then
		# Reenabled WebKit and WebKitWidgets modules
		sed -e '/list(APPEND ALL_OPTIONAL_MODULES/ s/WebSockets/WebKit WebKitWidgets &/' \
			-i CMakeLists.txt || die
		# Fix typesystem errors.
		sed -e '/value-type name="QWebDatabase"/ s/value-/object-/' \
			-e '/value-type name="QWebHistoryItem"/ s/value-/object-/' \
			-i PySide2/QtWebKitWidgets/typesystem_webkitwidgets.xml || die
		# Fix typos(?) in ingested glue file
		sed -e '/for (auto it = %0.lowerBound(key), end = %0.upperBound(key); it ! = end; ++it) {/ { s/key/_&/g; s/! =/!=/ }' \
			-e '/Shiboken::AutoDecRef _pyValue(%CONVERTTOPYTHON\[QString\](it.value));/ { s/it.value/it/; }' \
			-i PySide2/glue/qtwebkitwidgets.cpp || die
	fi

	cmake-utils_src_prepare
}


src_configure() {
	configuration() {
		local mycmakeargs=(
			# Broken cfgs from shiboken2, fix before slotting: -DENABLE_VERSION_SUFFIX=TRUE
			-DBUILD_TESTS=$(usex test)
			-DUSE_XVFB=$(usex test)
			-DPYTHON_EXECUTABLE="${PYTHON}"
			-DPYTHON_SITE_PACKAGES="$(python_get_sitedir)"
			-DMODULES="$(pyside2_build_modules_list)"
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

		cmake-utils_src_configure
	}
	python_foreach_impl configuration
}

pyside2_build_modules_list() {
	local mod deps dep
	local str=""
	local sep=";"
	while read -r mod deps ; do
		local met=1
		[ -n "${mod}" ] || continue
		if [ -n "${deps}" ] ; then
			for dep in ${deps} ; do use ${dep} || met=0 ; done
		fi
		[ $met -eq 1 ] && str="${str:+"${str}${sep}"}${mod#Qt}"
	done <<-EOF
		${PYSIDE2_QT_PKGS_USE}
	EOF
	printf -- '%s' "${str}"
}

src_compile() {
	do_compile() {
		cmake-utils_src_compile
	}
	python_foreach_impl do_compile
}

src_test() {
	local -x PYTHONDONTWRITEBYTECODE
	if [ -z "${DISPLAY}" ] ; then
		ewarn "Running tests requires a running X server, selected by the DISPLAY variable, for Xvfb to connect to."
		elog "${P} tests not run without running X server and DISPLAY variable set!"
		elog "(But we're returning success anyway, since this is expected behavior.)"
		return 0
	fi
	_do_test() {
		virtx cmake-utils_src_test
	}
	python_foreach_impl _do_test
}

src_install() {
	installation() {
		CMAKE_USE_DIR="${BUILD_DIR}" cmake-utils_src_install
		mv "${ED}"usr/$(get_libdir)/pkgconfig/${PN}{,-${EPYTHON}}.pc || die
	}
	python_foreach_impl installation
}
