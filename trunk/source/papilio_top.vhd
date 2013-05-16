--
-- Top level module for Pacman hardware on the Papilio board
--
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity papilio_top is
	port (
		CLK_IN                : in    std_logic;
		I_RESET               : in    std_logic;
		--
		O_VIDEO_R             : out   std_logic_vector(3 downto 0);
		O_VIDEO_G             : out   std_logic_vector(3 downto 0);
		O_VIDEO_B             : out   std_logic_vector(3 downto 0);
		O_HSYNC               : out   std_logic;
		O_VSYNC               : out   std_logic;
		-- audio
		O_AUDIO_L             : out   std_logic;
		O_AUDIO_R             : out   std_logic;
		-- controls
		PS2CLK1               : inout	std_logic;
		PS2DAT1               : inout	std_logic
	);
	end;

architecture RTL of papilio_top is
	--	only set one of these
	constant PENGO          : std_logic := '0'; -- set to 1 when using Pengo ROMs, 0 otherwise
	constant PACMAN         : std_logic := '1'; -- set to 1 for all other Pacman hardware games

	-- only set one of these when PACMAN is set
	constant MRTNT          : std_logic := '0'; -- set to 1 when using Mr TNT ROMs, 0 otherwise
	constant LIZWIZ         : std_logic := '0'; -- set to 1 when using Lizard Wizard ROMs, 0 otherwise
	constant MSPACMAN       : std_logic := '0'; -- set to 1 when using Ms Pacman ROMs, 0 otherwise

	constant dipsw1_pengo   : std_logic_vector( 7 downto 0) := "11100000";
--																					||||||||
--																					|||||||0 = bonus at 30K
--																					|||||||1 = bonus at 50K
--																					||||||0 = attract sound on
--																					||||||1 = attract sound off
--																					|||||0 = upright
--																					|||||1 = cocktail
--																					|||00 = 5 pengos
--																					|||01 = 4 pengos
--																					|||10 = 3 pengos
--																					|||11 = 2 pengos
--																					||0 = continuous play
--																					||1 = normal play
--																					00 = hardest
--																					01 = hard
--																					10 = medium
--																					11 = easy
	constant dipsw2_pengo   : std_logic_vector( 7 downto 0) := "11001100"; -- 1 coin/1 play

	constant dipsw1_pacman  : std_logic_vector( 7 downto 0) := "11001001";
--																					||||||||
--																					||||||00 = free play
--																					||||||01 = 1 coin / 1 play
--																					||||||10 = 1 coin / 2 play
--																					||||||11 = 2 coin / 1 play
--																					||||00 = 1 lives
--																					||||01 = 2 lives
--																					||||10 = 3 lives
--																					||||11 = 5 lives
--																					||00 = bonus pacman at 10K
--																					||01 = bonus pacman at 15K
--																					||10 = bonus pacman at 20K
--																					||11 = no bonus
--																					|0 = rack test
--																					|1 = play mode
--																					0 = freeze picture 
--																					1 = unfreeze picture 

	-- input registers
	signal in0_reg          : std_logic_vector( 7 downto 0) := (others => '1');
	signal in1_reg          : std_logic_vector( 7 downto 0) := (others => '1');
	signal dipsw1_reg       : std_logic_vector( 7 downto 0);
	signal dipsw2_reg       : std_logic_vector( 7 downto 0);
	signal decoder_ena_l    : std_logic;

	signal reset            : std_logic;
	signal clk              : std_logic;
	signal ena_6            : std_logic;
	signal ena_12           : std_logic;

	-- timing
	signal hcnt             : std_logic_vector( 8 downto 0) := "010000000"; -- 80
	signal vcnt             : std_logic_vector( 8 downto 0) := "011111000"; -- 0F8

	signal do_hsync         : boolean := true;
	signal hsync_o          : std_logic := '1';
	signal vsync_o          : std_logic := '1';
	signal hsync_i          : std_logic := '1';
	signal vsync_i          : std_logic := '1';
	signal comp_blank       : std_logic;

	-- scan doubler signals
	signal video_out        : std_logic_vector(15 downto 0) := (others => '0');
	signal dummy            : std_logic_vector( 3 downto 0) := (others => '0');

	--
	signal audio            : std_logic_vector( 7 downto 0);
	signal audio_pwm        : std_logic;

	signal ps2_codeready		: std_logic := '1';                                 
	signal ps2_scancode		: std_logic_vector( 9 downto 0) := (others => '0'); 

begin
	vsync_i <= not vsync_o;
	hsync_i <= not hsync_o;

	--
	-- clocks
	--
	u_clocks : entity work.PACMAN_CLOCKS
	port map (
		I_CLK_REF  => CLK_IN,
		I_RESET    => I_RESET,
		--
		O_CLK_REF  => open,
		--
		O_ENA_12   => ena_12,
		O_ENA_6    => ena_6,
		O_CLK      => clk,
		O_RESET    => reset
	);

	u_pacman : entity work.PACMAN_MACHINE
	generic map (
		PACMAN		=> PACMAN,
		PENGO       => PENGO,
		MRTNT 		=> MRTNT,
		LIZWIZ 		=> LIZWIZ,
		MSPACMAN		=> MSPACMAN
	)
	port map (
		clk        => clk,
		ena_6      => ena_6,
		reset		  => reset,
		video_r    => video_out(11 downto 9), -- 3 bits
		video_g    => video_out( 7 downto 5), -- 3 bits
		video_b    => video_out( 3 downto 2), -- 2 bits
		hsync      => hsync_o,
		vsync      => vsync_o,
		comp_blank => comp_blank,
		audio      => audio,

		in0_reg    => in0_reg,
		in1_reg    => in1_reg,
		dipsw1_reg => dipsw1_reg,
		dipsw2_reg => dipsw2_reg
	);

	-- Pacman resolution 224x288
	u_scanconv : entity work.VGA_SCANCONV
	generic map (
		hA				=>  16,	-- h front porch
		hB				=>  92,	-- h sync
		hC				=>  46,	-- h back porch
		hres			=> 578,	-- visible video
		hpad			=>  18,	-- padding either side to reach standard VGA resolution (hres + 2*hpad = hD)

		vB				=>   2,	-- v sync
		vC				=>  32,	-- v back porch
		vres			=> 448,	-- visible video
		vpad			=>  16,	-- padding either side to reach standard VGA resolution (vres + vpad = vD)

		cstart      =>  38,  -- composite sync start
		clength     => 288   -- composite sync length
	)
	port map (
		I_VIDEO                => video_out,
		I_HSYNC                => hsync_i,
		I_VSYNC                => vsync_i,

		O_VIDEO(15 downto 12)  => dummy,
		O_VIDEO(11 downto  8)  => O_VIDEO_R,
		O_VIDEO( 7 downto  4)  => O_VIDEO_G,
		O_VIDEO( 3 downto  0)  => O_VIDEO_B,
		O_HSYNC                => O_HSYNC,
		O_VSYNC                => O_VSYNC,
		O_CMPBLK_N             => open,
		--
		CLK                    => ena_6,
		CLK_X4                 => clk
	);

	--
	-- Audio DAC
	--
	u_dac : entity work.dac
	generic map(
		msbi_g => 7
	)
	port  map(
		clk_i   => clk,
		res_i   => reset,
		dac_i   => audio,
		dac_o   => audio_pwm
	);

	O_AUDIO_L <= audio_pwm;
	O_AUDIO_R <= audio_pwm;

	-----------------------------------------------------------------------------
	-- Keyboard - active low buttons
	-----------------------------------------------------------------------------
	kbd_inst : entity work.Keyboard
	port map (
		Reset     => reset,
		Clock     => ena_6,
		PS2Clock  => PS2CLK1,
		PS2Data   => PS2DAT1,
		CodeReady => ps2_codeready,
		ScanCode  => ps2_scancode
	);

-- ScanCode(9)          : 1 = Extended  0 = Regular
-- ScanCode(8)          : 1 = Break     0 = Make
-- ScanCode(7 downto 0) : Key Code

	dipsw1_reg <= dipsw1_pengo when PENGO = '1' else dipsw1_pacman ;
	dipsw2_reg <= dipsw2_pengo when PENGO = '1' else (others=>'1') ;

	process(ena_6)
	begin
		if rising_edge(ena_6) then
			if reset = '1' then
				in0_reg <= (others=>'1');
				in1_reg <=(others=>'1');
			elsif (ps2_codeready = '1') then
				if PENGO = '1' then
					case (ps2_scancode(7 downto 0)) is
											-- pengo closed is low
--											in0_reg(6) <= '1';                 -- service
--											in1_reg(4) <= '1';                 -- test
						when x"05" =>	in0_reg(4) <= ps2_scancode(8);     -- P1 coin "F1"
						when x"04" =>	in0_reg(5) <= ps2_scancode(8);     -- P2 coin "F3"

						when x"06" =>	in1_reg(5) <= ps2_scancode(8);     -- P1 start "F2"
						when x"0c" =>	in1_reg(6) <= ps2_scancode(8);     -- P2 start "F4"

						when x"43" =>	in0_reg(7) <= ps2_scancode(8);     -- P1 jump "I"
											in1_reg(7) <= ps2_scancode(8);     -- P2 jump "I"

						when x"75" =>	in0_reg(0) <= ps2_scancode(8);     -- P1 up arrow
											in1_reg(0) <= ps2_scancode(8);     -- P2 up arrow

						when x"72" =>	in0_reg(1) <= ps2_scancode(8);     -- P1 down arrow
											in1_reg(1) <= ps2_scancode(8);     -- P2 down arrow

						when x"6b" =>	in0_reg(2) <= ps2_scancode(8);     -- P1 left arrow
											in1_reg(2) <= ps2_scancode(8);     -- P2 left arrow

						when x"74" =>	in0_reg(3) <= ps2_scancode(8);     -- P1 right arrow
											in1_reg(3) <= ps2_scancode(8);     -- P2 right arrow

						when others => null;
					end case;
				elsif PACMAN = '1' then
					case (ps2_scancode(7 downto 0)) is
											-- pacman on is low
--											in0_reg(7) <= '1';                 -- coin
--											in0_reg(4) <= '1';                 -- test_l dipswitch (rack advance)
--											in1_reg(7) <= '1';                 -- table
--											in1_reg(4) <= '1';                 -- test
						when x"05" =>	in0_reg(5) <= ps2_scancode(8);     -- P1 coin "F1"
						when x"04" =>	in0_reg(6) <= ps2_scancode(8);     -- P2 coin "F3"

						when x"06" =>	in1_reg(5) <= ps2_scancode(8);     -- P1 start "F2"
						when x"0c" =>	in1_reg(6) <= ps2_scancode(8);     -- P2 start "F4"

--						when x"43" =>	p1_jump  <= ps2_scancode(8);       -- P1 jump "I"
--											p2_jump  <= ps2_scancode(8);       -- P2 jump "I"

						when x"75" =>	in0_reg(0) <= ps2_scancode(8);     -- P1 up arrow
											in1_reg(0) <= ps2_scancode(8);     -- P2 up arrow

						when x"72" =>	in0_reg(3) <= ps2_scancode(8);     -- P1 down arrow
											in1_reg(3) <= ps2_scancode(8);     -- P2 down arrow

						when x"6b" =>	in0_reg(1) <= ps2_scancode(8);     -- P1 left arrow
											in1_reg(1) <= ps2_scancode(8);     -- P2 left arrow

						when x"74" =>	in0_reg(2) <= ps2_scancode(8);     -- P1 right arrow
											in1_reg(2) <= ps2_scancode(8);     -- P2 right arrow

						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;

end RTL;
