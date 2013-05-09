@echo off

REM SHA1 sums of files required
REM 448845cab63800a05fcb106897503d994377f78f glob.7f    
REM bbcec0570aeceb582ff8238a4bc8546a23430081 82s126.1m  
REM 0c4d0bee858b97632411c440bea6948a74759746 82s126.3m  
REM 7588889f3102d4e0ca7918f536556209b2490ea1 glob.4a    
REM ddc8606512d7ab7555b84146b9d793f65ad0a75f 5e_2532.dat
REM fb17632e2665c3cebc1865ef25fa310cc52725c4 5f_2532.dat
REM 89f52b459a03fb40b9bbd97ac8a292f7ead6faba glob.u2    
REM 35a47dcf34efd74b5b2fda137e06a3dcabd74854 glob.u3    









set rom_path_src=..\roms\sprglobp
set rom_path=..\build
set romgen_path=..\romgen_source

REM concatenate consecutive ROM regions
copy /b/y %rom_path_src%\5e_2532.dat + %rom_path_src%\5f_2532.dat %rom_path%\gfx1.bin > NUL
copy /b/y %rom_path_src%\glob.u2 + %rom_path_src%\glob.u3 %rom_path%\main.bin > NUL


REM generate RTL code for small PROMS
%romgen_path%\romgen %rom_path_src%\82s126.1m     PROM1_DST  8 a r e > %rom_path%\prom1_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s126.3m     PROM3_DST  7 a     > %rom_path%\prom3_dst.vhd
%romgen_path%\romgen %rom_path_src%\glob.4a       PROM4_DST 10 a     > %rom_path%\prom4_dst.vhd
%romgen_path%\romgen %rom_path_src%\glob.7f       PROM7_DST  5 a r e > %rom_path%\prom7_dst.vhd

REM generate RAMB structures for larger ROMS
%romgen_path%\romgen %rom_path%\gfx1.bin          GFX1      14 l r e > %rom_path%\gfx1.vhd
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_0 14 l r e > %rom_path%\rom0.vhd

REM this ROM area is not used but is required for synthesis
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_1 14 l r e > %rom_path%\rom1.vhd

echo done
pause
