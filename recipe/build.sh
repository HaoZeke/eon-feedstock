#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# All deps from conda packages. Prefer system/pkg-config readcon-core
# (libreadcon-core host dep). Do not fetch subproject wraps for these.
rm -f subprojects/xtb.wrap
rm -f subprojects/vesin.wrap
rm -f subprojects/rgpot.wrap
rm -f subprojects/readcon-core.wrap

export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
if [[ $(uname) == "Linux" ]]; then
    export LDFLAGS="${LDFLAGS} -Wl,--no-as-needed,${PREFIX}/lib/libtorch.so -Wl,--as-needed"
fi

export PYTHONPATH="${SP_DIR}:${PYTHONPATH:-}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LIBRARY_PATH="${PREFIX}/lib:${LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export CPATH="${PREFIX}/include:${CPATH:-}"
export CPLUS_INCLUDE_PATH="${PREFIX}/include:${CPLUS_INCLUDE_PATH:-}"

tee native.ini <<EOFN
[binaries]
python = '${PREFIX}/bin/python'
EOFN

meson setup -Dpython.install_env=prefix \
    --native-file native.ini \
    --pkg-config-path="${PREFIX}/lib/pkgconfig" \
    -Dwith_metatomic=True \
    -Dwith_xtb=True \
    -Dwith_serve=True \
    -Dpip_metatomic=False \
    -Dtorch_path="${PREFIX}" \
    -Dcpp_link_args="${LDFLAGS}" \
    ${MESON_ARGS} build
meson compile -C build -v
meson install -C build
