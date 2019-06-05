# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )
inherit multibuild python-r1 qmake-utils

DESCRIPTION="Python bindings for the Qt framework"
HOMEPAGE="https://www.riverbankcomputing.com/software/pyqt/intro"

MY_P="${PN}_gpl-${PV/_pre/.dev}"
if [[ "${PV}" == *_pre* ]]; then
	SRC_URI="https://www.riverbankcomputing.com/static/Downloads/${PN}/${MY_P}.tar.gz"
else
	SRC_URI="https://www.riverbankcomputing.com/static/Downloads/${PN}/${PV}/${MY_P}.tar.gz"
	#SRC_URI="mirror://sourceforge/pyqt/${MY_P}.tar.gz"
fi

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ~ppc64 x86"

IUSE="bluetooth dbus designer gui help location
	multimedia network networkauth nfc opengl positioning printsupport declarative remoteobjects sensors serialport sql svg
	testlib webchannel webkit websockets widgets x11extras xmlpatterns"
# Note: USE="gles2" disables Desktop OpenGL functionality and is mutually exclusive!
IUSE="${IUSE} debug examples gles2"

# The requirements below were extracted from configure.py
# and from the output of 'grep -r "%Import " "${S}"/sip'
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	bluetooth? ( gui )
	designer? ( gui )
	help? ( gui widgets )
	location? ( positioning )
	multimedia? ( gui network )
	networkauth? ( network )
	opengl? ( gui )
	positioning? ( gui )
	printsupport? ( gui )
	declarative? ( gui )
	sensors? ( gui )
	serialport? ( gui )
	sql? ( gui widgets )
	svg? ( gui )
	testlib? ( gui widgets )
	webchannel? ( network )
	webkit? ( gui network widgets? ( printsupport ) )
	widgets? ( gui )
	x11extras? ( gui )
	xmlpatterns? ( network )
"

# Minimal supported version of Qt.
QT_PV="5.9.4:5"

RDEPEND="
	${PYTHON_DEPS}
	>=dev-python/PyQt5_sip-4.19.14_pre1901251320:=[${PYTHON_USEDEP}]
	>=dev-qt/qtcore-${QT_PV}
	>=dev-qt/qtxml-${QT_PV}
	bluetooth? ( >=dev-qt/qtbluetooth-${QT_PV} )
	dbus? (
		dev-python/dbus-python[${PYTHON_USEDEP}]
		>=dev-qt/qtdbus-${QT_PV}
	)
	declarative? ( >=dev-qt/qtdeclarative-${QT_PV}[widgets?] )
	designer? ( >=dev-qt/designer-${QT_PV} )
	gui? ( >=dev-qt/qtgui-${QT_PV}[gles2=] )
	help? ( >=dev-qt/qthelp-${QT_PV} )
	location? ( >=dev-qt/qtlocation-${QT_PV} )
	multimedia? ( >=dev-qt/qtmultimedia-${QT_PV}[widgets?] )
	network? ( >=dev-qt/qtnetwork-${QT_PV} )
	networkauth? ( >=dev-qt/qtnetworkauth-${QT_PV} )
	opengl? ( >=dev-qt/qtopengl-${QT_PV} )
	positioning? ( >=dev-qt/qtpositioning-${QT_PV} )
	printsupport? ( >=dev-qt/qtprintsupport-${QT_PV} )
	sensors? ( >=dev-qt/qtsensors-${QT_PV} )
	serialport? ( >=dev-qt/qtserialport-${QT_PV} )
	sql? ( >=dev-qt/qtsql-${QT_PV} )
	svg? ( >=dev-qt/qtsvg-${QT_PV} )
	testlib? ( >=dev-qt/qttest-${QT_PV} )
	webchannel? ( >=dev-qt/qtwebchannel-${QT_PV} )
	webkit? ( >=dev-qt/qtwebkit-5.9:5[printsupport] )
	websockets? ( >=dev-qt/qtwebsockets-${QT_PV} )
	widgets? ( >=dev-qt/qtwidgets-${QT_PV} )
	x11extras? ( >=dev-qt/qtx11extras-${QT_PV} )
	xmlpatterns? ( >=dev-qt/qtxmlpatterns-${QT_PV} )
"
DEPEND="${RDEPEND}
	dbus? ( virtual/pkgconfig )
"
#dev-python/${PN}_sip

S="${WORKDIR}/${MY_P}"

DOCS=( "${S}"/{ChangeLog,NEWS} )

pyqt_use_enable() {
	local mode="disable"
	use "$1" && mode="enable"
	shift
	while [ $# -gt 0 ] ; do
		printf -- ' --%s=%s' "${mode}" "${1}"
		shift
	done
}

src_prepare() {
	default
	python_copy_sources
}

src_configure() {
	configuration() {
		local myconf=(
			"${PYTHON}"
			"${S}"/configure.py
			CFLAGS="${CFLAGS}$(python_is_python3 || printf -- " -fno-strict-aliasing")"
			$(usex debug '--debug --qml-debug --trace' '')
			--verbose
			--confirm-license
			--qmake="$(qt5_get_bindir)"/qmake
		#	--bindir="${EPREFIX}/usr/bin"
		#	--destdir="$(python_get_sitedir)"
		#	--sip-incdir="$(python_get_includedir)"
			--qsci-api
			--no-dist-info
			$(pyqt_use_enable bluetooth QtBluetooth)
			--enable=QtCore
			$(pyqt_use_enable dbus QtDBus)
			$(usex dbus '' --no-python-dbus)
			$(pyqt_use_enable designer QtDesigner)
			$(usex designer '' --no-designer-plugin)
			$(pyqt_use_enable gui QtGui)
			$(pyqt_use_enable gui $(use gles2 && echo _QOpenGLFunctions_ES2 || echo _QOpenGLFunctions_{2_{0,1},4_1_Core}))
			$(pyqt_use_enable help QtHelp)
			$(pyqt_use_enable location QtLocation)
			$(pyqt_use_enable multimedia QtMultimedia $(usex widgets QtMultimediaWidgets ''))
			$(pyqt_use_enable network QtNetwork $(usex networkauth QtNetworkAuth ''))
			$(pyqt_use_enable nfc QtNfc)
			$(pyqt_use_enable opengl QtOpenGL)
			$(pyqt_use_enable positioning QtPositioning)
			$(pyqt_use_enable printsupport QtPrintSupport)
			$(pyqt_use_enable declarative QtQml QtQuick $(usex widgets QtQuickWidgets ''))
			$(usex declarative '' --no-qml-plugin)
			$(pyqt_use_enable remoteobjects QtRemoteObjects)
			$(pyqt_use_enable sensors QtSensors)
			$(pyqt_use_enable serialport QtSerialPort)
			$(pyqt_use_enable sql QtSql)
			$(pyqt_use_enable svg QtSvg)
			$(pyqt_use_enable testlib QtTest)
			$(pyqt_use_enable webchannel QtWebChannel)
			$(pyqt_use_enable webkit QtWebKit QtWebKitWidgets)
			$(pyqt_use_enable websockets QtWebSockets)
			$(pyqt_use_enable widgets QtWidgets)
			$(pyqt_use_enable x11extras QtX11Extras)
			--enable=QtXml
			$(pyqt_use_enable xmlpatterns QtXmlPatterns)
		)
		echo "${myconf[@]}"
		"${myconf[@]}" || die

		#	MAKEOPTS="-j1" eqmake5 -recursive ${PN}.pro
		#emake
	}
	python_foreach_impl run_in_build_dir configuration
}

src_compile() {
	python_foreach_impl run_in_build_dir default
}

src_install() {
	installation() {
		#local tmp_root=${D%/}/tmp
		#emake INSTALL_ROOT="${tmp_root}" install
		#
		#local bin_dir=${tmp_root}${EPREFIX}/usr/bin
		MAKOPTS="-j1" emake install INSTALL_ROOT="${ED}" DESTDIR="${ED}"

		local myroot="${WORKDIR}/${P}-${EPYTHON}-imagetmp"
		mkdir -p "${myroot}"
		( set +f ; mv "${D}"/* "${myroot}" )
		local exe
		for exe in pylupdate5 pyrcc5 pyuic5; do
			python_doexe "${myroot}${EPREFIX}/usr/bin/${exe}"
			rm "${myroot}${EPREFIX}/usr/bin/${exe}" || die
		done

		local uic_dir="${myroot}$(python_get_sitedir)/${PN}/uic"
		if python_is_python3; then
			rm -r "${uic_dir}"/port_v2 || die
		else
			rm -r "${uic_dir}"/port_v3 || die
		fi

		multibuild_merge_root "${myroot}" "${D}"
		python_optimize
	}
	python_foreach_impl run_in_build_dir installation

	einstalldocs

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi
}
