--
-- A simulation model of Pacman hardware
-- Copyright (c) MikeJ - January 2006
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email pacman@fpgaarcade.com
--
-- Revision list
--
-- version 003 Jan 2006 release, general tidy up
-- version 002 added volume multiplier
-- version 001 initial release
--
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library UNISIM;
	use UNISIM.Vcomponents.all;

entity PACMAN_AUDIO is
port (
	I_HCNT            : in    std_logic_vector(8 downto 0);
	--
	I_AB              : in    std_logic_vector(11 downto 0);
	I_DB              : in    std_logic_vector( 7 downto 0);
	--
	I_WR1_L           : in    std_logic;
	I_WR0_L           : in    std_logic;
	I_SOUND_ON        : in    std_logic;
	--
	O_AUDIO           : out   std_logic_vector(7 downto 0);
	ENA_6             : in    std_logic;
	CLK               : in    std_logic
);
end;

architecture RTL of PACMAN_AUDIO is
	signal vol_ram_wen   : std_logic;
	signal frq_ram_wen   : std_logic;
	signal vol_ram_dout  : std_logic_vector(3 downto 0);
	signal frq_ram_dout  : std_logic_vector(3 downto 0);
	signal addr          : std_logic_vector(3 downto 0);
	signal data          : std_logic_vector(3 downto 0);

	signal sum           : std_logic_vector(5 downto 0);
	signal accum_reg     : std_logic_vector(5 downto 0);
	signal rom3m         : std_logic_vector(7 downto 0);
	signal rom1m         : std_logic_vector(7 downto 0);
begin
	addr <= I_AB(3 downto 0) when I_HCNT(1) = '0' else I_HCNT(5 downto 2)   ;
	data <= I_DB(3 downto 0) when I_HCNT(1) = '0' else accum_reg(4 downto 1);

--	p_sel_com : process(I_HCNT, I_AB, I_DB, accum_reg)
--	begin
--		if (I_HCNT(1) = '0') then -- 2h,
--			addr <= I_AB(3 downto 0);
--			data <= I_DB(3 downto 0); -- removed invert
--		else
--			addr <= I_HCNT(5 downto 2);
--			data <= accum_reg(4 downto 1);
--		end if;
--	end process;

	vol_ram_wen <= (not I_WR1_L  ) and ENA_6;
	frq_ram_wen <= (not rom3m(1) ) and ENA_6;

--	p_ram_comb : process(I_WR1_L, rom3m, ENA_6)
--	begin
--		vol_ram_wen <= '0';
--		if (I_WR1_L = '0') and (ENA_6 = '1') then
--			vol_ram_wen <= '1';
--		end if;

--		frq_ram_wen <= '0';
--		if (rom3m(1) = '1') and (ENA_6 = '1') then
--			frq_ram_wen <= '1';
--		end if;
--	end process;

	vol_ram : for i in 0 to 3 generate
	-- should be a latch, but we are using a clock
	begin
		inst: RAM16X1D
		port map (
			a0    => addr(0),
			a1    => addr(1),
			a2    => addr(2),
			a3    => addr(3),
			dpra0 => addr(0),
			dpra1 => addr(1),
			dpra2 => addr(2),
			dpra3 => addr(3),
			wclk  => CLK,
			we    => vol_ram_wen,
			d     => data(i),
			dpo   => vol_ram_dout(i)
		);
	end generate;

	frq_ram : for i in 0 to 3 generate
	-- should be a latch, but we are using a clock
	begin
		inst: RAM16X1D
		port map (
			a0    => addr(0),
			a1    => addr(1),
			a2    => addr(2),
			a3    => addr(3),
			dpra0 => addr(0),
			dpra1 => addr(1),
			dpra2 => addr(2),
			dpra3 => addr(3),
			wclk  => CLK,
			we    => frq_ram_wen,
			d     => data(i),
			dpo   => frq_ram_dout(i)
		);
	end generate;

	audio_rom_1m : entity work.PROM1_DST
	port map(
		CLK              => CLK,
		ENA              => ENA_6,
		ADDR(7 downto 5) => frq_ram_dout(2 downto 0),
		ADDR(4 downto 0) => accum_reg(4 downto 0),
		DATA             => rom1m
	);

	-- schema has chip select on /6M*
	audio_rom_3m : entity work.PROM3_DST
	port map(
--		CLK              => CLK,
--		ENA              => ENA_6,
		ADDR(6)          => I_WR0_L,
		ADDR(5 downto 0) => I_HCNT(5 downto 0),
		DATA             => rom3m
	);

	-- 1K 4 bit adder
	sum <= ('0' & vol_ram_dout & '1') + ('0' & frq_ram_dout & accum_reg(5));

	p_accum_reg : process
	begin
		-- 1L
		wait until rising_edge(CLK);
		if (ENA_6 = '1') then
			if (rom3m(3) = '0') then -- clear
				accum_reg <= (others=>'0');
			elsif (rom3m(0) = '0') then -- rising edge clk
				accum_reg <= sum(5 downto 1) & accum_reg(4);
			end if;
		end if;
	end process;

	p_original_output_reg : process
	begin
		-- 2m used to use async clear
		wait until rising_edge(CLK);
		if (ENA_6 = '1') then
			if (I_SOUND_ON = '0') then
				O_AUDIO <= (others=>'0');
			elsif (rom3m(2) = '0') then
				O_AUDIO <= vol_ram_dout(3 downto 0) * rom1m(3 downto 0);
			end if;
		end if;
	end process;
end architecture RTL;
