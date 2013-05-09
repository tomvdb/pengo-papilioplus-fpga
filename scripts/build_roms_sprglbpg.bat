@echo off

REM SHA1 sums of files required
REM 448845cab63800a05fcb106897503d994377f78f ic78.prm
REM 563c9770028fe39188e62630711589d6ed242a66 ic51.prm
REM 0c4d0bee858b97632411c440bea6948a74759746 ic70.prm
REM 7588889f3102d4e0ca7918f536556209b2490ea1 ic88.prm
REM 583999280623f02dcc318a6c7af5ee6fc46144b8 ic14.4
REM 9fadbb098b86ee98e1a81da938316b833fc26912 ic15.3
REM 2f1d27e49850f904d1f2256bfcf00557ed88bb16 ic7.2
REM 14c55186053b080de06cc3691111ede8b2ead231 ic8.1
REM 4feb9ec917c2467a5ac531283cb00fe308be7775 ic92.5








set rom_path_src=..\roms\sprglbpg
set rom_path=..\build
set romgen_path=..\romgen_source

REM concatenate consecutive ROM regions
copy /b/y %rom_path_src%\ic92.5 %rom_path%\gfx1.bin > NUL
copy /b/y %rom_path_src%\ic8.1 + %rom_path_src%\ic7.2  + %rom_path_src%\ic15.3 + %rom_path_src%\ic14.4 %rom_path%\main.bin > NUL


REM generate RTL code for small PROMS
%romgen_path%\romgen %rom_path_src%\ic51.prm      PROM1_DST  8 a r e > %rom_path%\prom1_dst.vhd
%romgen_path%\romgen %rom_path_src%\ic70.prm      PROM3_DST  7 a     > %rom_path%\prom3_dst.vhd
%romgen_path%\romgen %rom_path_src%\ic88.prm      PROM4_DST 10 a     > %rom_path%\prom4_dst.vhd
%romgen_path%\romgen %rom_path_src%\ic78.prm      PROM7_DST  5 a r e > %rom_path%\prom7_dst.vhd

REM generate RAMB structures for larger ROMS
%romgen_path%\romgen %rom_path%\gfx1.bin          GFX1      14 l r e > %rom_path%\gfx1.vhd
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_0 14 l r e > %rom_path%\rom0.vhd

REM this ROM area is not used but is required for synthesis
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_1 14 l r e > %rom_path%\rom1.vhd

echo done
pause
