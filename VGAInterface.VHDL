----------------------------------------------------------------------------------
-- ENGR 378 San Francisco State University
-- VGA Lab 6
-- This code was written for a computer monitor with a 1280 by 1024 resolution (60 fps)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity VGAInterface is
    Port ( CLOCK_50: in  STD_LOGIC;
           VGA_R : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_G : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_B : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_HS : out  STD_LOGIC;
           VGA_VS : out  STD_LOGIC;
			  VGA_BLANK_N : out  STD_LOGIC;
			  VGA_CLK : out  STD_LOGIC;
			  VGA_SYNC_N : out  STD_LOGIC;
           KEY : in  STD_LOGIC_VECTOR (3 downto 0);
           SW : in  STD_LOGIC_VECTOR (17 downto 0);
           HEX0 : out  STD_LOGIC_VECTOR (6 downto 0);
           HEX1 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX2 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX3 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX4 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX5 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX6 : out  STD_LOGIC_VECTOR (6 downto 0);
			  HEX7 : out  STD_LOGIC_VECTOR (6 downto 0);
			  LEDR : out  STD_LOGIC_VECTOR (17 downto 0);
			  LEDG : out  STD_LOGIC_VECTOR (8 downto 0));
end VGAInterface;

architecture Behavioral of VGAInterface is
	
	component VGAFrequency is -- Altera PLL used to generate 108Mhz clock 
	PORT ( areset		: IN STD_LOGIC;
			 inclk0		: IN STD_LOGIC;
			 c0		: OUT STD_LOGIC ;
			 locked		: OUT STD_LOGIC);
	end component;
	
	component VGAController is -- Module declaration for the VGA controller
     Port ( PixelClock : in  STD_LOGIC;
           inRed : in STD_LOGIC_VECTOR (7 downto 0);
			  inGreen : in STD_LOGIC_VECTOR (7 downto 0);
			  inBlue : in STD_LOGIC_VECTOR (7 downto 0);
			  outRed : out STD_LOGIC_VECTOR (7 downto 0);
			  outGreen : out STD_LOGIC_VECTOR (7 downto 0);
			  outBlue : out STD_LOGIC_VECTOR (7 downto 0);
           VertSynchOut : out  STD_LOGIC;
           HorSynchOut : out  STD_LOGIC;
           XPosition : out  STD_LOGIC_VECTOR (10 downto 0);
           YPosition : out  STD_LOGIC_VECTOR (10 downto 0));
	end component;

	-- Variables for screen resolution 1280 x 1024
	signal XPixelPosition : STD_LOGIC_VECTOR (10 downto 0);
	signal YPixelPosition : STD_LOGIC_VECTOR (10 downto 0);
	
	signal redValue : STD_LOGIC_VECTOR (7 downto 0) := "00000000";
	signal greenValue :STD_LOGIC_VECTOR (7 downto 0) := "00000000";
	signal blueValue : STD_LOGIC_VECTOR (7 downto 0) := "00000000";
	
	-- Freq Mul/Div signals (PLL I/O variables used to generate 108MHz clock)
	constant resetFreq : STD_LOGIC := '0';
	signal PixelClock: STD_LOGIC;
	signal lockedPLL : STD_LOGIC; -- dummy variable

	-- Variables used for displaying the white dot to screen for demo
	signal XDotPosition : STD_LOGIC_VECTOR (10 downto 0) := "01000000000";
	signal YDotPosition : STD_LOGIC_VECTOR (10 downto 0) := "01000000000";
	signal displayPosition : STD_LOGIC_VECTOR (10 downto 0) := "01000000000";
	signal XBall1: integer := 640;
	signal Yball1: integer:= 520;
	
	-- Variables used for displaying the paddles to screen for demo
	signal YLPPosition1 : STD_LOGIC_VECTOR (10 downto 0) := "00110110010"; 
	signal YLPPosition2 : STD_LOGIC_VECTOR (10 downto 0) := "01001011010"; 
	signal YRPPosition1 : STD_LOGIC_VECTOR (10 downto 0) := "00110110010";
	signal YRPPosition2 : STD_LOGIC_VECTOR (10 downto 0) := "01001011010";
	
	-- Variables for slow clock counter to generate a slower clock
	signal slowClockCounter : STD_LOGIC_VECTOR (20 downto 0) := "000000000000000000000";
	signal slowClock : STD_LOGIC;
	
	-- Vertical and Horizontal Synch Signals
	signal HS : STD_LOGIC; -- horizontal synch
	signal VS : STD_LOGIC; -- vertical synch
	
	-- Variables for ball movement
	signal State: integer := 2;
	signal playerL, playerR: integer := 9;
	
	
begin

	process (CLOCK_50)-- control process for a large counter to generate a slow clock
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			slowClockCounter <= slowClockCounter + 1;
		end if;
	end process;

	slowClock <= slowClockCounter(20); -- slow clock signal
	
-- Right paddle position 
	process (slowClock)-- move right paddle Y position
	begin
		if slowClock'event and slowClock= '1' then
			if KEY(0) = '0' then -- detect that button 0 is pressed
				if (YRPPosition1 <= 128) then
					YRPPosition1 <= YRPPosition1;
					YRPPosition2 <= "00100101000";
				else				
					YRPPosition1 <= YRPPosition1 - 10;
					YRPPosition2 <= YRPPosition2 - 10;
				end if;
			elsif KEY(1) = '0' then -- detect that button 1 is pressed
				if (YRPPosition2 >= 896) then
					YRPPosition1 <= "01011011000";
					YRPPosition2 <= YRPPosition2;
				else
					YRPPosition1 <= YRPPosition1 + 10;
					YRPPosition2 <= YRPPosition2 + 10;
				end if;
			end if;
		end if;
	end process;
	
	--Left paddle position		
	process (slowClock)-- 
	begin
		if slowClock'event and slowClock = '1' then
			if KEY(2) = '0' then -- detect that button 2 is pressed
				if (YLPPosition1 <= 128) then
					YLPPosition1 <= YLPPosition1;
					YLPPosition2 <= YLPPosition2;
				else				
					YLPPosition1 <= YLPPosition1 - 10;
					YLPPosition2 <= YLPPosition2 - 10;
				end if;
			elsif KEY(3) = '0' then-- detect that button 3 is pressed
				if (YLPPosition2 >= 896) then
					YLPPosition1 <= YLPPosition1;
					YLPPosition2 <= YLPPosition2;
				else
					YLPPosition1 <= YLPPosition1 + 10;
					YLPPosition2 <= YLPPosition2 + 10;		
				end if;
			end if;
		end if;
	end process;
	
	PROCESS(SLOWCLOCK)
	begin
	if slowclock'event and slowclock = '1' then
	if (State = 0) then
		  XBall1<=XBall1+20;
		  Yball1<=Yball1+20;
		  elsif(State=1) then
		  XBall1<=XBall1+20;
		  Yball1<=Yball1-20;
		  elsif(State =2) then
		  XBall1<=XBall1-20;
		  Yball1<=Yball1+20;
		  elsif(state=3) then
		  XBall1<=XBall1-20;
		  Yball1<=Yball1-20;
		  end if;
	end if;
	end process;
		
	
process(slowClock) -- move ball position
			begin
			if slowClock'event and slowClock = '1' then
if (((XBall1+20) >= 1019) and (XBall1-20) <=1041 and ((YBall1-20)<YRPPosition2 and (YBall1+20)>YRPPosition1)) then --BALL HITS RIGHT PADDLE
				if (State=1) then
					State<=3;
				elsif(State = 0) then
					State<=2;
				end if;
elsif((XBall1-20) <= 282 and (XBall1+20) >=259 and (YBall1-20) < YLPPosition2 and (YBall1+20) > YLPPosition1) then --BALL HITS LEFT PADDLE
			 if (State=3)then
			 State<=1;
			 elsif(state = 2) then
				State <= 0;
			 end if;
elsif((XBall1-20) <= 161) then -- WHEN BALL HITS LEFT BORDER
	playerR <= playerR+1;
if (State=3)then
			 State<=1;
			 elsif(state = 2) then
				State <= 0;
			 end if;
elsif((XBall1+20) >=1120) then -- WHEN BALL HITS RIGHT BORDER
playerL <= playerL+1;
if (State=1) then
					State<=3;
				elsif(state = 0) then
					State<=2;
				end if;
elsif((YBall1-20)<=122) then --WHEN BALL HITS TOP WALL
				 if (State= 1)then
					State <= 0;
				elsif(state = 3) then
				 State <= 2;
				 end if;
elsif((YBall1+20) >= 898) then --BALL HITS BOTTOM WALL
				 if (State = 2) then
				 State <= 3;
				 elsif(state = 0) then
				 State <= 1;
				 end if;
end if;
		end if;
		
	end process;
	
	
	-- Displays the value for the X coordinate or Y coordinate to the LEDS depending on switch 1
	LEDR(10 downto 0) <= YDotPosition when SW(1) = '1'
						 else XDotPosition;

	-- Generates a 108Mhz frequency for the pixel clock using the PLL (The pixel clock determines
   --how much time there is between drawing one pixel at a time)
	VGAFreqModule : VGAFrequency port map (resetFreq, CLOCK_50, PixelClock, lockedPLL);
	
	-- Module generates the X/Y pixel position on the screen as well as the horizontal and vertical
   --	synch signals for monitor with 1280 x 1024 resolution at 60 frams per second
	VGAControl : VGAController port map (PixelClock, redValue, greenValue, blueValue, VGA_R, VGA_G,
	VGA_B, VS, HS, XPixelPosition, YPixelPosition);
	
	-- OUTPUT ASSIGNMENTS FOR VGA SIGNALS
	VGA_VS <= VS;
	VGA_HS <= HS;
	VGA_BLANK_N <= '1';
	VGA_SYNC_N <= '1';			
	VGA_CLK <= PixelClock;
	
	-- OUTPUT ASSIGNEMNTS TO SEVEN SEGMENT DISPLAYS
	HEX0 <= "0000000"; -- display 8
	HEX1 <= "1111000"; -- display 7
	HEX2 <= "0000010"; -- display 6
	HEX3 <= "0010010"; -- display 5
	HEX4 <= "0011001"; -- display 4
	HEX5 <= "0110000"; -- display 3
	HEX6 <= "0100100"; -- display 2
	HEX7 <= "1111001"; -- display 1
	
	-- COLOR ASSIGNMENT STATEMENTS
	process (PixelClock)-- MODIFY CODE HERE TO DISPLAY COLORS IN DIFFERENT REGIONS ON THE SCREEN
	begin
		if PixelClock'event and PixelClock = '1' then
			if SW(0) = '0' then -- display three different colors to screen
--				redValue <= XPixelPosition(7 downto 0); 
--				blueValue <= YPixelPosition(7 downto 0);
--				greenValue <= YPixelPosition(9 downto 2);
				if ((XPixelPosition > 0 and XPixelPosition < 160) and (YPixelPosition > 0 or YPixelPosition <1024)) 
				then -- left hot pink side borders
					redValue <=  "11111111";
					blueValue <= "01101001";
					greenValue <="10110100";	
				elsif ((XPixelPosition > 1120 and XPixelPosition < 1280) and (YPixelPosition > 0 or YPixelPosition <1024))
				then -- right hot pink side borders
					redValue <=  "11111111";
					blueValue <= "01101001";
					greenValue <="10110100";
				elsif ((XPixelPosition > 160 AND XPixelPosition < 1120) and (YPixelPosition >=0 AND YPixelPosition <= 120)) 
				THEN --top borders blue
					redValue <= "00000000"; 
					blueValue <= "11111111";
					greenValue <= "00000000";
				elsif ((XPixelPosition > 160 AND XPixelPosition < 1120) and (YPixelPosition >=900 AND YPixelPosition <= 1024))
				THEN --bottom borders blue
					redValue <= "00000000"; 
					blueValue <= "11111111";
					greenValue <= "00000000";
				else	--black background									
					redValue <=  "00000000";
					blueValue <= "00000000";
					greenValue <="00000000";
				end if; --end of background colors
				
 
            if ((YPixelPosition>(YBall1-20) and (YPixelPosition<(YBall1+20)) and (XPixelPosition<(XBall1+20)) and 
				(XPixelPosition>(XBall1-20)))) then --square in medium spring green 
     		   redValue <= "00000000"; 
			  	blueValue <= "10011010";
				greenValue <= "11111010";				
				end if;
		
				
				if((XPixelPosition > 260 and XPixelPosition < 280) and (YPixelPosition > YLPPosition1 AND
				YPixelPosition < YLPPosition2)) then --paddle one (left)
				redValue <= "11111111"; 
					blueValue <= "11111111";
					greenValue <= "11111111";
				end if;
				if((XPixelPosition > 1020 and XPixelPosition < 1040) and (YPixelPosition > YRPPosition1 AND 
				YPixelPosition < YRPPosition2)) then --paddle two (right)
				redValue <= "11111111"; 
					blueValue <= "11111111";
					greenValue <= "11111111";
				end if;
				
			else -- display the white dot and the black background
				if (XPixelPosition = XDotPosition AND YPixelPosition = YDotPosition) then
					redValue <= "11111111"; 
					blueValue <= "11111111";
					greenValue <= "11111111";
				else
					redValue <= "00000000"; 
					blueValue <= "00000000";
					greenValue <= "00000000";	
				end if;
			end if;
		end if;
	end process;
	
	
end Behavioral;
