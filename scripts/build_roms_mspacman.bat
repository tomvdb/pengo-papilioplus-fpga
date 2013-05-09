@echo off

REM SHA1 sums of files required
REM 8d0268dee78e47c712202b0ec4f1f51109b1f2a5 82s123.7f
REM bbcec0570aeceb582ff8238a4bc8546a23430081 82s126.1m
REM 0c4d0bee858b97632411c440bea6948a74759746 82s126.3m
REM 19097b5f60d1030f8b82d9f1d3a241f93e5c75d6 82s126.4a
REM e87e059c5be45753f7e9f33dff851f16d6751181 pacman.6e
REM 674d3a7f00d8be5e38b1fdc208ebef5a92d38329 pacman.6f
REM 8e47e8c2c4d6117d174cdac150392042d3e0a881 pacman.6h
REM d4a70d56bb01d27d094d73db8667ffb00ca69cb9 pacman.6j
REM b26cc1c8ee18e9b1daa97956d2159b954703a0ec u5
REM e4df96f1db753533f7d770aa62ae1973349ea4cf u6
REM 1d8ac7ad03db2dc4c8c18ade466e12032673f874 u7
REM 5e8b472b615f12efca3fe792410c23619f067845 5e
REM fd6a1dde780b39aea76bf1c4befa5882573c2ef4 5f




set rom_path_src=..\roms\mspacman
set rom_path=..\build
set romgen_path=..\romgen_source

REM concatenate consecutive ROM regions
copy /b/y %rom_path_src%\5e + %rom_path_src%\5f %rom_path%\gfx1.bin > NUL
copy /b/y %rom_path_src%\pacman.6e + %rom_path_src%\pacman.6f + %rom_path_src%\pacman.6h + %rom_path_src%\pacman.6j %rom_path%\main1.bin > NUL
copy /b/y %rom_path_src%\u5 + %rom_path_src%\u5 + %rom_path_src%\u6 + %rom_path_src%\u7 %rom_path%\main2.bin > NUL

REM generate RTL code for small PROMS
%romgen_path%\romgen %rom_path_src%\82s126.1m     PROM1_DST  8 a r e > %rom_path%\prom1_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s126.3m     PROM3_DST  7 a     > %rom_path%\prom3_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s126.4a     PROM4_DST 10 a     > %rom_path%\prom4_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s123.7f     PROM7_DST  5 a r e > %rom_path%\prom7_dst.vhd

REM generate RAMB structures for larger ROMS
%romgen_path%\romgen %rom_path%\gfx1.bin          GFX1      14 l r e > %rom_path%\gfx1.vhd
%romgen_path%\romgen %rom_path%\main1.bin         ROM_PGM_0 14 l r e > %rom_path%\rom0.vhd


%romgen_path%\romgen %rom_path%\main2.bin         ROM_PGM_1 14 l r e > %rom_path%\rom1.vhd

echo done
pause
