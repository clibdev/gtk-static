#!/bin/bash
set -eo pipefail

export CCACHE_DIR=/app/build/ccache
export PKG_CONFIG_PATH=/opt/install/lib/pkgconfig

# zlib
git clone https://github.com/madler/zlib.git --depth=1 --branch=v1.3.2 /tmp/zlib

cd /tmp/zlib && rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
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
  -DCMAKE_INSTALL_PREFIX=/opt/install \
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
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DFT_DISABLE_HARFBUZZ=ON \
  -DFT_DISABLE_BZIP2=ON \
  -DFT_DISABLE_BROTLI=ON
cmake --build build -j$(nproc)
cmake --install build --strip

# Expat
git clone https://github.com/libexpat/libexpat.git --depth=1 --branch=R_2_8_2 /tmp/libexpat

cd /tmp/libexpat/expat && rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/install \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_INSTALL_DATAROOTDIR=/tmp/expat-data \
  -DBUILD_SHARED_LIBS=OFF \
  -DEXPAT_BUILD_EXAMPLES=OFF \
  -DEXPAT_BUILD_TESTS=OFF \
  -DEXPAT_BUILD_TOOLS=OFF
cmake --build build -j$(nproc)
cmake --install build --strip

# Fontconfig
git clone https://gitlab.freedesktop.org/fontconfig/fontconfig.git --depth=1 --branch=2.17.1 /tmp/fontconfig

cd /tmp/fontconfig && rm -rf build
meson setup build --buildtype=release \
  --prefix=/opt/install \
  --default-library=static \
  --libdir=lib \
  --sysconfdir=/etc \
  --datadir=/usr/share \
  --localstatedir=/var \
  -Dtests=disabled \
  -Dtools=disabled
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
meson setup build --buildtype=release \
  --default-library=static \
  --libdir=lib \
  -Dtests=disabled \
  -Dxlib=enabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# Pango
git clone https://gitlab.gnome.org/GNOME/pango.git --depth=1 --branch=1.58.0 /tmp/pango
cd /tmp/pango

meson setup build --buildtype=release \
  --default-library=static \
  --libdir=lib \
  -Dbuild-testsuite=false \
  -Dbuild-examples=false
meson compile -C build -j$(nproc)
meson install -C build --strip

# gdk-pixbuf
git clone https://gitlab.gnome.org/GNOME/gdk-pixbuf.git --depth=1 --branch=2.44.7 /tmp/gdk-pixbuf
cd /tmp/gdk-pixbuf

meson setup build --buildtype=release \
  --default-library=static \
  --libdir=lib -Dman=false \
  -Dtests=false \
  -Dinstalled_tests=false \
  -Djpeg=disabled \
  -Dgif=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# gobject-introspection
git clone https://gitlab.gnome.org/GNOME/gobject-introspection.git --depth=1 --branch=1.86.0 /tmp/gobject-introspection
cd /tmp/gobject-introspection

meson setup build --buildtype=release \
  --default-library=static \
  --libdir=lib

# GTK
git clone https://gitlab.gnome.org/GNOME/gtk.git --depth=1 --branch=4.23.2 /tmp/gtk
cd /tmp/gtk

meson setup build --buildtype=release \
  -Ddemos=false \
  -Dexamples=false \
  -Dtests=false \
  -Dwayland_backend=false
