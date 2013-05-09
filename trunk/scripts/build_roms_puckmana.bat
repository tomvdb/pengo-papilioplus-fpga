@echo off

REM SHA1 sums of files required
REM 8d0268dee78e47c712202b0ec4f1f51109b1f2a5 82s123.7f
REM bbcec0570aeceb582ff8238a4bc8546a23430081 82s126.1m
REM 0c4d0bee858b97632411c440bea6948a74759746 82s126.3m
REM 19097b5f60d1030f8b82d9f1d3a241f93e5c75d6 82s126.4a
REM e87e059c5be45753f7e9f33dff851f16d6751181 pacman.6e
REM 674d3a7f00d8be5e38b1fdc208ebef5a92d38329 pacman.6f
REM 8e47e8c2c4d6117d174cdac150392042d3e0a881 pacman.6h
REM d249fa9cdde774d5fee7258147cd25fa3f4dc2b3 prg7
REM eb462de79f49b7aa8adb0cc6d31535b10550c0ce prg8
REM 6d4ccc27d6be185589e08aa9f18702b679e49a4a chg1
REM 79bb456be6c39c1ccd7d077fbe181523131fb300 chg2
REM 4a937ac02216ea8c96477d4a15522070507fb599 pacman.5f





set rom_path_src=..\roms\puckmana
set rom_path=..\build
set romgen_path=..\romgen_source

REM concatenate consecutive ROM regions
copy /b/y %rom_path_src%\chg1 + %rom_path_src%\chg2 + %rom_path_src%\pacman.5f %rom_path%\gfx1.bin > NUL
copy /b/y %rom_path_src%\pacman.6e + %rom_path_src%\pacman.6f + %rom_path_src%\pacman.6h + %rom_path_src%\prg7 + %rom_path_src%\prg8 %rom_path%\main.bin > NUL


REM generate RTL code for small PROMS
%romgen_path%\romgen %rom_path_src%\82s126.1m     PROM1_DST  8 a r e > %rom_path%\prom1_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s126.3m     PROM3_DST  7 a     > %rom_path%\prom3_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s126.4a     PROM4_DST 10 a     > %rom_path%\prom4_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s123.7f     PROM7_DST  5 a r e > %rom_path%\prom7_dst.vhd

REM generate RAMB structures for larger ROMS
%romgen_path%\romgen %rom_path%\gfx1.bin          GFX1      14 l r e > %rom_path%\gfx1.vhd
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_0 14 l r e > %rom_path%\rom0.vhd

REM this ROM area is not used but is required for synthesis
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_1 14 l r e > %rom_path%\rom1.vhd

echo done
pause
