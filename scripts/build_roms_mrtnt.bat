@echo off

REM SHA1 sums of files required
REM 8d0268dee78e47c712202b0ec4f1f51109b1f2a5 82s123.7f
REM bbcec0570aeceb582ff8238a4bc8546a23430081 82s126.1m
REM 0c4d0bee858b97632411c440bea6948a74759746 82s126.3m
REM 19097b5f60d1030f8b82d9f1d3a241f93e5c75d6 82s126.4a
REM 5037b7c618f05bc3d6a33694729ae575b9aa7dbb tnt.1
REM 5ecac4f5b64b306c73d8f57d5260b586789b3055 tnt.2
REM e5729e4e42a5b9b3a26de8a44b3a78b49c8b1d8e tnt.3
REM 689746653b1e19fbcddd0d71db2b86d1019235aa tnt.4
REM f8f5927ea4cbfda8fa7546abd766ba2e8b020004 tnt.5
REM 4c0fa4bc44bbb4b4614b5cc05e811c469c0e78e8 tnt.6







set rom_path_src=..\roms\mrtnt
set rom_path=..\build
set romgen_path=..\romgen_source

REM concatenate consecutive ROM regions
copy /b/y %rom_path_src%\tnt.5 + %rom_path_src%\tnt.6 %rom_path%\gfx1.bin > NUL
copy /b/y %rom_path_src%\tnt.1 + %rom_path_src%\tnt.2 + %rom_path_src%\tnt.3 + %rom_path_src%\tnt.4 %rom_path%\main.bin > NUL


REM generate RTL code for small PROMS
%romgen_path%\romgen %rom_path_src%\82s126.1m     PROM1_DST  8 a r e > %rom_path%\prom1_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s126.3m     PROM3_DST  7 a     > %rom_path%\prom3_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s126.4a     PROM4_DST 10 a     > %rom_path%\prom4_dst.vhd
%romgen_path%\romgen %rom_path_src%\82s123.7f     PROM7_DST  5 a r e > %rom_path%\prom7_dst.vhd

REM generate RAMB structures for larger ROMS
%romgen_path%\romgen %rom_path%\gfx1.bin          GFX1      14 l r e > %rom_path%\gfx1.vhd
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_0 14 l r e > %rom_path%\rom0.vhd

REM this ROM area is not used but is required for synthesys
%romgen_path%\romgen %rom_path%\main.bin          ROM_PGM_1 14 l r e > %rom_path%\rom1.vhd

echo done
pause
