#!/bin/bash
set -eo pipefail

export CCACHE_DIR=/app/build/ccache
# wayland-protocols' .pc is a noarch data file, so meson installs it under
# datadir/pkgconfig instead of libdir/pkgconfig.
export PKG_CONFIG_PATH=/opt/install/lib/pkgconfig:/opt/install/share/pkgconfig
export PATH=/opt/install/bin:$PATH

# CMake takes CC/CXX as a literal compiler path, so cmake-based builds below
# use -DCMAKE_C_COMPILER_LAUNCHER=ccache instead. Meson and autotools accept
# a space-separated launcher in CC/CXX, so it's exported once cmake is done.

# zlib
git clone https://github.com/madler/zlib.git --depth=1 --branch=v1.3.2 /tmp/zlib

cd /tmp/zlib && rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_INSTALL_DATAROOTDIR=/tmp/zlib-data \
  -DZLIB_BUILD_TESTING=OFF \
  -DZLIB_BUILD_SHARED=OFF
cmake --build build -j$(nproc)
cmake --install build --strip

# libpng
git clone https://github.com/pnggroup/libpng.git --depth=1 --branch=v1.6.58 /tmp/libpng

cd /tmp/libpng && rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_PREFIX_PATH=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_INSTALL_DATAROOTDIR=/tmp/libpng-data \
  -DCMAKE_INSTALL_BINDIR=/tmp/libpng-data \
  -DPNG_TESTS=OFF \
  -DPNG_SHARED=OFF
cmake --build build -j$(nproc)
cmake --install build --strip

# pcre2
git clone --recursive https://github.com/PCRE2Project/pcre2.git --depth=1 --branch=pcre2-10.47 /tmp/pcre2

cd /tmp/pcre2 && rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_INSTALL_DATAROOTDIR=/tmp/pcre2-data \
  -DCMAKE_INSTALL_BINDIR=/tmp/pcre2-data \
  -DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=ON \
  -DPCRE2_BUILD_PCRE2_16=ON \
  -DPCRE2_BUILD_PCRE2_32=ON \
  -DPCRE2_SUPPORT_JIT=ON \
  -DPCRE2_STATIC_PIC=ON \
  -DPCRE2_BUILD_PCRE2GREP=OFF \
  -DPCRE2_BUILD_TESTS=OFF
cmake --build build -j$(nproc)
cmake --install build --strip

# FreeType
git clone https://github.com/freetype/freetype.git --depth=1 --branch=VER-2-14-3 /tmp/freetype

cd /tmp/freetype && rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_PREFIX_PATH=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DFT_DISABLE_HARFBUZZ=ON \
  -DFT_DISABLE_BZIP2=ON \
  -DFT_DISABLE_BROTLI=ON \
  -DFT_DISABLE_PNG=ON
cmake --build build -j$(nproc)
cmake --install build --strip

# Expat (fontconfig dependency)
git clone https://github.com/libexpat/libexpat.git --depth=1 --branch=R_2_8_2 /tmp/libexpat

cd /tmp/libexpat && rm -rf build
cmake -B build -S expat -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DEXPAT_SHARED_LIBS=OFF \
  -DEXPAT_BUILD_TOOLS=OFF \
  -DEXPAT_BUILD_EXAMPLES=OFF \
  -DEXPAT_BUILD_TESTS=OFF \
  -DEXPAT_BUILD_DOCS=OFF
cmake --build build -j$(nproc)
cmake --install build --strip

export CC="ccache gcc"
export CXX="ccache g++"
# util-macros (built further below) installs xorg-macros.m4 here; every
# autotools-based X11 library's autoreconf step needs it to find
# XORG_MACROS_VERSION.
export ACLOCAL_PATH=/opt/install/share/aclocal

# --- X11 client library stack -------------------------------------------
# All autotools-based (this is old-school X.org code, no meson). Static
# archives need --with-pic: libtool defaults to non-PIC objects for a
# static-only (--disable-shared) build, which breaks once linked into
# libgtk-4.so. Each --disable-shared/--enable-static build below installs
# only a .a, no .so, so it can't accidentally get picked up dynamically.

# util-macros: installs xorg-macros.m4 (see ACLOCAL_PATH above) - every
# other package here needs XORG_MACROS_VERSION from it during autoreconf.
git clone https://gitlab.freedesktop.org/xorg/util/macros.git --depth=1 --branch=util-macros-1.20.2 /tmp/util-macros

cd /tmp/util-macros
./autogen.sh --prefix=/opt/install
make install

# xorgproto: the *proto headers (xproto, kbproto, inputproto, renderproto,
# fixesproto, damageproto, randrproto, xineramaproto, ...), meson-based,
# headers/pkgconfig only, no compiled code.
git clone https://gitlab.freedesktop.org/xorg/proto/xorgproto.git --depth=1 --branch=xorgproto-2025.1 /tmp/xorgproto

cd /tmp/xorgproto && rm -rf build
meson setup build --prefix=/opt/install --libdir=lib
meson install -C build

# xtrans: header-only (X11's transport-layer abstraction).
git clone https://gitlab.freedesktop.org/xorg/lib/libxtrans.git --depth=1 --branch=xtrans-1.6.0 /tmp/xtrans

cd /tmp/xtrans
./autogen.sh --prefix=/opt/install
make install

# libXau, libXdmcp: only need xproto.
git clone https://gitlab.freedesktop.org/xorg/lib/libXau.git --depth=1 --branch=libXau-1.0.12 /tmp/libXau

cd /tmp/libXau
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

git clone https://gitlab.freedesktop.org/xorg/lib/libXdmcp.git --depth=1 --branch=libXdmcp-1.1.5 /tmp/libXdmcp

cd /tmp/libXdmcp
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

# xcbproto: XCB's XML protocol descriptions + Python codegen, needed to
# build libxcb; PYTHON=python3 since Ubuntu has no bare "python" binary.
git clone https://gitlab.freedesktop.org/xorg/proto/xcbproto.git --depth=1 --branch=xcb-proto-1.17.0 /tmp/xcbproto

cd /tmp/xcbproto
./autogen.sh --prefix=/opt/install PYTHON=python3
make install

# libxcb: needs xcbproto + libXau (xdmcp is optional, already built so it
# gets picked up too). pthread-stubs isn't needed on Linux (glibc already
# has real pthread symbols).
git clone https://gitlab.freedesktop.org/xorg/lib/libxcb.git --depth=1 --branch=libxcb-1.17.0 /tmp/libxcb

cd /tmp/libxcb
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic PYTHON=python3
make -j$(nproc) install

# libX11: needs xproto, xextproto, xtrans, xcb.
git clone https://gitlab.freedesktop.org/xorg/lib/libX11.git --depth=1 --branch=libX11-1.8.13 /tmp/libX11

cd /tmp/libX11
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

# libXext, libXrender, libXfixes: each only needs libX11 + their own proto.
git clone https://gitlab.freedesktop.org/xorg/lib/libXext.git --depth=1 --branch=libXext-1.3.7 /tmp/libXext

cd /tmp/libXext
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

git clone https://gitlab.freedesktop.org/xorg/lib/libXrender.git --depth=1 --branch=libXrender-0.9.12 /tmp/libXrender

cd /tmp/libXrender
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

git clone https://gitlab.freedesktop.org/xorg/lib/libXfixes.git --depth=1 --branch=libXfixes-6.0.2 /tmp/libXfixes

cd /tmp/libXfixes
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

# libXi (needs libX11, libXext, libXfixes), libXcursor (needs libX11,
# libXrender, libXfixes), libXdamage (needs libX11, libXfixes).
git clone https://gitlab.freedesktop.org/xorg/lib/libXi.git --depth=1 --branch=libXi-1.8.3 /tmp/libXi

cd /tmp/libXi
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

git clone https://gitlab.freedesktop.org/xorg/lib/libXcursor.git --depth=1 --branch=libXcursor-1.2.3 /tmp/libXcursor

cd /tmp/libXcursor
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

git clone https://gitlab.freedesktop.org/xorg/lib/libXdamage.git --depth=1 --branch=libXdamage-1.1.7 /tmp/libXdamage

cd /tmp/libXdamage
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

# libXrandr (needs libX11, libXext, libXrender), libXinerama (needs libX11,
# libXext).
git clone https://gitlab.freedesktop.org/xorg/lib/libXrandr.git --depth=1 --branch=libXrandr-1.5.5 /tmp/libXrandr

cd /tmp/libXrandr
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

git clone https://gitlab.freedesktop.org/xorg/lib/libXinerama.git --depth=1 --branch=libXinerama-1.1.6 /tmp/libXinerama

cd /tmp/libXinerama
./autogen.sh --prefix=/opt/install --disable-shared --enable-static --with-pic
make -j$(nproc) install

# fontconfig
git clone https://gitlab.freedesktop.org/fontconfig/fontconfig.git --depth=1 --branch=2.18.2 /tmp/fontconfig

cd /tmp/fontconfig && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dxml-backend=expat \
  -Dnls=disabled \
  -Ddoc=disabled \
  -Dtests=disabled \
  -Dtools=disabled \
  -Dcache-build=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# libffi
git clone https://github.com/libffi/libffi.git --depth=1 --branch=v3.7.1 /tmp/libffi

cd /tmp/libffi && rm -rf build && mkdir build
./autogen.sh
cd build
../configure --prefix=/opt/install \
  --disable-docs \
  --disable-shared \
  --without-gcc-arch
make -j$(nproc) CFLAGS='-static -fPIC -O3 -DNDEBUG'
make install-strip

# GLib
git clone --recursive https://github.com/GNOME/glib.git --depth=1 --branch=2.89.1 /tmp/glib

cd /tmp/glib && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dtests=false \
  -Dglib_debug=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# Pixman
git clone https://gitlab.freedesktop.org/pixman/pixman.git --depth=1 --branch=pixman-0.46.4 /tmp/pixman

cd /tmp/pixman && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dtests=disabled \
  -Ddemos=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# Cairo
git clone https://gitlab.freedesktop.org/cairo/cairo.git --depth=1 --branch=1.18.4 /tmp/cairo

cd /tmp/cairo && rm -rf build
# -Dprefer_static=true: cairo's own configure does cc.has_function() link
# checks against X11/Xrender (e.g. XRenderCreateLinearGradient) to decide
# whether to use its own bundled fallback structs. Those checks link a test
# program against x11/xrender alone; without --static, libX11's private
# xcb requirement never gets pulled in, the test program fails to link,
# and cairo wrongly concludes the function is missing - then defines its
# own conflicting copies of structs that our newer Xrender.h already has.
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dprefer_static=true \
  -Dtests=disabled \
  -Dxlib=enabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# HarfBuzz
git clone https://github.com/harfbuzz/harfbuzz.git --depth=1 --branch=14.3.0 /tmp/harfbuzz

cd /tmp/harfbuzz && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dfreetype=enabled \
  -Dglib=enabled \
  -Dgobject=disabled \
  -Dcairo=disabled \
  -Dchafa=disabled \
  -Dicu=disabled \
  -Dpng=disabled \
  -Dzlib=disabled \
  -Dgraphite2=disabled \
  -Dfontations=disabled \
  -Dgpu=disabled \
  -Dutilities=disabled \
  -Dbenchmark=disabled \
  -Dtests=disabled \
  -Ddocs=disabled \
  -Dintrospection=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# Fribidi
git clone https://github.com/fribidi/fribidi.git --depth=1 --branch=v1.0.16 /tmp/fribidi

cd /tmp/fribidi && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dbin=false \
  -Ddocs=false \
  -Dtests=false
meson compile -C build -j$(nproc)
meson install -C build --strip

# Pango
git clone https://gitlab.gnome.org/GNOME/pango.git --depth=1 --branch=1.58.0 /tmp/pango
cd /tmp/pango && rm -rf build

meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dbuild-testsuite=false \
  -Dbuild-examples=false
meson compile -C build -j$(nproc)
meson install -C build --strip

# gdk-pixbuf
git clone https://gitlab.gnome.org/GNOME/gdk-pixbuf.git --depth=1 --branch=2.44.7 /tmp/gdk-pixbuf
cd /tmp/gdk-pixbuf && rm -rf build

meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dman=false \
  -Dtests=false \
  -Dinstalled_tests=false \
  -Djpeg=disabled \
  -Dtiff=disabled \
  -Dgif=disabled \
  -Dglycin=disabled \
  -Dthumbnailer=disabled \
  -Dintrospection=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# Graphene
git clone https://github.com/ebassi/graphene.git --depth=1 --branch=1.10.8 /tmp/graphene
cd /tmp/graphene && rm -rf build

meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dtests=false \
  -Dinstalled_tests=false \
  -Dintrospection=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# libepoxy
git clone https://github.com/anholt/libepoxy.git --depth=1 --branch=1.5.10 /tmp/libepoxy
cd /tmp/libepoxy && rm -rf build

# -Dprefer_static=true: epoxy also optionally probes x11 (for GLX headers);
# same Requires.private: xcb issue as cairo above.
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dprefer_static=true \
  -Dtests=false
meson compile -C build -j$(nproc)
meson install -C build --strip

# libjpeg-turbo (GTK's own tools require it directly, separate from gdk-pixbuf's
# loader; the SIMD asm in an un-PIC static build breaks linking into libgtk-4.so,
# so SIMD is left off here rather than fighting the TLS model of the wrap build)
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git --depth=1 --branch=3.1.4 /tmp/libjpeg-turbo

cd /tmp/libjpeg-turbo && rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DENABLE_SHARED=OFF \
  -DENABLE_STATIC=ON \
  -DWITH_SIMD=OFF \
  -DWITH_TURBOJPEG=OFF \
  -DWITH_JPEG8=ON \
  -DWITH_TOOLS=OFF \
  -DWITH_TESTS=OFF
cmake --build build -j$(nproc)
cmake --install build --strip

# libtiff
git clone https://gitlab.com/libtiff/libtiff.git --depth=1 --branch=v4.7.2 /tmp/libtiff

# libtiff's source tree already has its own "build" subdirectory (used to
# generate tif_config.h), so the build output goes to "_build" instead to
# avoid colliding with (and deleting) it.
cd /tmp/libtiff && rm -rf _build
cmake -B _build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_PREFIX_PATH=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -Dtiff-tools=OFF \
  -Dtiff-tests=OFF \
  -Dtiff-contrib=OFF \
  -Dtiff-docs=OFF
cmake --build _build -j$(nproc)
cmake --install _build --strip

# libwayland (wayland-client, wayland-server, wayland-egl, wayland-cursor,
# and the wayland-scanner tool all live in this one repo). Its only real
# deps are expat (wayland-scanner's XML parser) and libffi, both already
# built above; -Ddtd_validation=false drops the libxml2 dependency that
# would otherwise pull in (XML schema validation, not needed to build).
git clone https://gitlab.freedesktop.org/wayland/wayland.git --depth=1 --branch=1.24.0 /tmp/wayland

cd /tmp/wayland && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dtests=false \
  -Ddocumentation=false \
  -Ddtd_validation=false
meson compile -C build -j$(nproc)
meson install -C build --strip

# libxkbcommon: the core library has no external dependencies at all; only
# its optional add-ons need extras (xkbcommon-x11 needs xcb, xkbregistry
# needs libxml2), and GTK only needs the core, so those are disabled.
git clone https://github.com/xkbcommon/libxkbcommon.git --depth=1 --branch=xkbcommon-1.13.2 /tmp/libxkbcommon

cd /tmp/libxkbcommon && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Denable-x11=false \
  -Denable-tools=false \
  -Denable-wayland=false \
  -Denable-xkbregistry=false \
  -Denable-docs=false \
  -Denable-bash-completion=false
meson compile -C build -j$(nproc)
meson install -C build --strip

# wayland-protocols (GTK's wayland backend needs >= 1.48; apt only has 1.47).
# 1.49+ needs wayland-scanner >= 1.25.0 for its "tests" feature detection,
# but our own wayland-scanner above is 1.24.0, so -Dtests=false is required
# to keep the scanner version check satisfied; 1.48 is the newest tag that
# still validates cleanly against that scanner's built-in protocol DTD.
git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git --depth=1 --branch=1.48 /tmp/wayland-protocols

cd /tmp/wayland-protocols && rm -rf build
meson setup build --prefix=/opt/install -Dtests=false
meson compile -C build -j$(nproc)
meson install -C build

# libdrm: GTK only wants drm_fourcc.h (it never actually links against
# libdrm - see gtk/meson.build's libdrm_dep.partial_dependency(includes:
# true, compile_args: true)), so every vendor-specific KMS backend
# (intel/radeon/amdgpu/nouveau/...) is disabled; the core library needs
# nothing beyond libc/pthread.
git clone https://gitlab.freedesktop.org/mesa/drm.git --depth=1 --branch=libdrm-2.4.134 /tmp/libdrm

cd /tmp/libdrm && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dintel=disabled \
  -Dradeon=disabled \
  -Damdgpu=disabled \
  -Dnouveau=disabled \
  -Dvmwgfx=disabled \
  -Domap=disabled \
  -Dexynos=disabled \
  -Dfreedreno=disabled \
  -Dtegra=disabled \
  -Dvc4=disabled \
  -Detnaviv=disabled \
  -Dcairo-tests=disabled \
  -Dman-pages=disabled \
  -Dvalgrind=disabled \
  -Dinstall-test-programs=false \
  -Dudev=false \
  -Dtests=false
meson compile -C build -j$(nproc)
meson install -C build --strip

# GTK
git clone https://gitlab.gnome.org/GNOME/gtk.git --depth=1 --branch=4.23.2 /tmp/gtk
cd /tmp/gtk && rm -rf build

# -Dprefer_static=true matters here specifically because of the X11 stack:
# libX11.pc correctly marks xcb as Requires.private (it's an internal
# implementation detail, invisible to Xlib's public API) - proper
# autotools/pkg-config semantics, unlike our own meson-built libraries
# (glib, cairo, pango, ...) which flatten everything into public Requires
# for a static-only build. A shared .so resolves that privately via its own
# embedded NEEDED entries, but a .a carries no such metadata, so GTK's own
# configure-time checks (e.g. XkbQueryExtension) fail to link without this.
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  -Dprefer_static=true \
  -Dbuild-demos=false \
  -Dbuild-examples=false \
  -Dbuild-tests=false \
  -Dbuild-testsuite=false \
  -Dintrospection=disabled \
  -Dvulkan=disabled \
  -Dmedia-gstreamer=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# GTK's own meson.build builds static archives for libgtk/libgdk/libgsk (and
# a few small partials) alongside the shared libgtk-4.so, but only ever
# installs the shared one. Those archives are also "thin" (they just
# reference .o files still sitting in the build tree), so the real object
# data has to be extracted before merging them into one self-contained,
# installable libgtk-4.a.
rm -rf /tmp/gtk-static-merge
mkdir -p /tmp/gtk-static-merge
for pair in \
  "gtk/libgtk.a:gtk" \
  "gtk/css/libgtk_css.a:gtk_css" \
  "gtk/svg/libgtk_svg.a:gtk_svg" \
  "gdk/libgdk.a:gdk" \
  "gsk/libgsk.a:gsk" \
  "gsk/libgsk_f16c.a:gsk_f16c"; do
  archive=${pair%%:*}
  name=${pair##*:}
  dir="/tmp/gtk/build/$(dirname "$archive")"
  stage="/tmp/gtk-static-merge/$name"
  mkdir -p "$stage"
  ( cd "$dir" && ar t "$(basename "$archive")" ) | while read -r obj; do
    mkdir -p "$stage/$(dirname "$obj")"
    cp "$dir/$obj" "$stage/$obj"
  done
done
find /tmp/gtk-static-merge -name "*.o" > /tmp/gtk-static-objs.list
ar rcs /opt/install/lib/libgtk-4.a @/tmp/gtk-static-objs.list
ranlib /opt/install/lib/libgtk-4.a

# gtk4.pc's Requires: (pango, cairo, gdk-pixbuf-2.0, ...) covers everything
# GTK exposes through those libraries' own public APIs, but a few things GTK
# links directly and never re-exposes (epoxy, the extra Xi/Xfixes/Xcursor/
# Xdamage/Xrandr/Xinerama X11 extensions, wayland-client/wayland-egl/
# xkbcommon for the wayland backend, its bundled jpeg/tiff loaders,
# harfbuzz-subset, cairo-script-interpreter) aren't declared anywhere and
# have to be listed explicitly for static linking. xcb/Xau/Xdmcp are libX11's
# own Requires.private, and pkg-config also dedupes repeated -l flags down
# to their *last* position - so cairo's own (later) "-lX11" ends up placed
# after our explicit "-lxcb -lXau -lXdmcp" here, breaking left-to-right
# resolution. -Wl,--start-group sidesteps needing exact ordering entirely by
# letting the linker re-scan the whole set until everything resolves; ld
# tolerates the missing matching --end-group by implicitly closing it at
# the very end of the command line (just a harmless warning). libgtk-4.a
# needs --whole-archive: GObject type registration relies on constructor
# functions with no external caller, so the linker would otherwise drop
# those object files as "unused".
cat > /opt/install/lib/pkgconfig/gtk4-static.pc <<EOF
prefix=/opt/install
includedir=\${prefix}/include
libdir=\${prefix}/lib

Name: GTK (static)
Description: GTK Graphical UI Library (static linking)
Version: 4.23.2
Requires: pango >=  1.58, pangocairo >=  1.58, gdk-pixbuf-2.0 >=  2.30.0, cairo >=  1.18.2, cairo-gobject >=  1.18.2, graphene-gobject-1.0 >=  1.10.0, gio-2.0 >=  2.84
Libs: -Wl,--whole-archive \${libdir}/libgtk-4.a -Wl,--no-whole-archive -Wl,--start-group -lepoxy -lGL -lEGL -lcairo-script-interpreter -lharfbuzz-subset -ltiff -ljpeg -lXi -lXfixes -lXcursor -lXdamage -lXrandr -lXinerama -lxcb -lXau -lXdmcp -lxkbcommon -lwayland-client -lwayland-egl -lz
Cflags: -I\${includedir}/gtk-4.0
EOF
