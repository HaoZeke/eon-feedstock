@echo on

:: conda-forge/eon-feedstock#15: enable IN-TREE Fortran on win-64 (not skip it).
:: Strategy (see https://rgoswami.me/posts/windows-compat-sci-cpp/):
::   - C++/Python/torch/metatomic: MSVC (conda-forge default win-64 compilers)
::   - In-tree Fortran pots: compiler('fortran') (llvm-flang on conda-forge win)
::   - Archiver: MUST be MSVC lib.exe (not llvm-ar from flang)
:: readcon-core: host package libreadcon-core via pkg-config — no vendor tar/zip.

:: Remove wraps so meson does not fetch subprojects offline.
if exist subprojects\xtb.wrap del /f /q subprojects\xtb.wrap
if exist subprojects\vesin.wrap del /f /q subprojects\vesin.wrap
if exist subprojects\rgpot.wrap del /f /q subprojects\rgpot.wrap
if exist subprojects\readcon-core.wrap del /f /q subprojects\readcon-core.wrap

:: MSVC archiver for static libs when flang is on PATH.
set "CC=cl.exe"
set "CXX=cl.exe"
set "AR=lib"
set "ARFLAGS="
set "NM=dumpbin"
set "RANLIB=:"
where link >nul 2>&1
if errorlevel 1 (
    echo ERROR: MSVC link.exe not on PATH; vsenv/activation missing
    exit 1
)

:: flang_rt import libs for MSVC link
set "FLANG_RT_DIR="
for /f "delims=" %%R in ('flang -print-resource-dir 2^>nul') do set "FLANG_RT_DIR=%%R\lib\x86_64-pc-windows-msvc"
if defined FLANG_RT_DIR (
    if exist "%FLANG_RT_DIR%\flang_rt.runtime.dynamic.lib" (
        set "LIB=%FLANG_RT_DIR%;%LIB%"
        echo Using flang_rt LIBPATH: %FLANG_RT_DIR%
    )
)
if not defined FLANG_RT_DIR (
    for /d %%D in ("%LIBRARY_PREFIX%\lib\clang\*") do (
        if exist "%%D\lib\x86_64-pc-windows-msvc\flang_rt.runtime.dynamic.lib" (
            set "LIB=%%D\lib\x86_64-pc-windows-msvc;%LIB%"
            echo Using flang_rt LIBPATH: %%D\lib\x86_64-pc-windows-msvc
        )
    )
)

meson setup -Dpython.install_env=prefix ^
    --prefix="%PREFIX%" ^
    --default-library=static ^
    -Dwith_metatomic=True ^
    -Dwith_xtb=True ^
    -Dwith_serve=True ^
    -Dwith_fortran=true ^
    -Dwith_cuh2=true ^
    -Dpip_metatomic=False ^
    -Dtorch_path="%LIBRARY_PREFIX%" ^
    --pkg-config-path="%LIBRARY_LIB%\pkgconfig" ^
    --cmake-prefix-path="%LIBRARY_PREFIX%" ^
    --buildtype=release ^
    build
if errorlevel 1 exit 1

meson compile -C build -v
if errorlevel 1 exit 1

meson install -C build
if errorlevel 1 exit 1
