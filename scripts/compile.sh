#!/bin/bash
set -eo pipefail

export CCACHE_DIR=/app/build/ccache

# Pixman
git clone https://gitlab.freedesktop.org/pixman/pixman.git --depth=1 --branch=pixman-0.46.4 /tmp/pixman
cd /tmp/pixman

meson setup build --buildtype=release \
  --default-library=static \
  --libdir=lib \
  -Dtests=disabled \
  -Ddemos=disabled
meson compile -C build -j$(nproc)
meson install -C build --strip

# Cairo
git clone https://gitlab.freedesktop.org/cairo/cairo.git --depth=1 --branch=1.18.4 /tmp/cairo
cd /tmp/cairo

meson setup build --buildtype=release \
  --default-library=static \
  --libdir=lib \
  -Dtests=disabled \
  -Dxlib=enabled \
  -Dfontconfig=disabled
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
