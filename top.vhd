-- Create Date:    22:55:21 12/15/2017 
-- Created by:     Serkan Kavak
-- Design Name:    Iterative Divider
-- Module Name:    top - Behavioral

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
Port(
		clk, reset : in std_logic;
		start : in std_logic;
		dividend : in std_logic_vector (5 downto 0);
		divisor : in std_logic_vector (3 downto 0);
		
		done_led : out std_logic;
		
		seg_out, seg_sel : out std_logic_vector (7 downto 0);
		
		result_is_equal : out std_logic
);
end top;

architecture Behavioral of top is

component Converter_1HZ is
Port(   clk : in STD_LOGIC;
		enable : in STD_LOGIC;
		clock_out : out STD_LOGIC);
end component;

component seven_four is
    Port ( in1 : in  STD_LOGIC_VECTOR (3 downto 0);
           in2 : in  STD_LOGIC_VECTOR (3 downto 0);
           in3 : in  STD_LOGIC_VECTOR (3 downto 0);
           in4 : in  STD_LOGIC_VECTOR (3 downto 0);
           clk : in  STD_LOGIC;
		   dp  : out  STD_LOGIC;
           sel : out  STD_LOGIC_VECTOR (3 downto 0);
           segment : out  STD_LOGIC_VECTOR (6 downto 0)
			);
end component;


type state_type is (idle, op, last, done, is_equal);
signal state_reg, state_next : state_type;

signal r1_reg, r1_next : std_logic_vector (5 downto 0);
signal r2_reg, r2_next : std_logic_vector (5 downto 0);
signal d_reg, d_next : std_logic_vector (3 downto 0);
signal n_reg, n_next : unsigned (2 downto 0);

signal r1_tmp  : std_logic_vector (5 downto 0);
signal q_bit : std_logic;

signal clk_1hz : std_logic;

signal quotient : std_logic_vector (5 downto 0);
signal remainder : std_logic_vector (5 downto 0);

signal dp : std_logic;
signal seg_sel_4 : std_logic_vector (3 downto 0);
signal seg_out_7 : std_logic_vector (6 downto 0);

signal state_out : std_logic_vector (3 downto 0);
signal state_out_led : std_logic_vector (3 downto 0);

begin

Convert_to_one_Hz : Converter_1HZ
	port map( clk=> clk, enable => '1', clock_out => clk_1hz);
	
--STATE AND DATA REGISTERS
Process(clk_1hz, reset)
begin
	if reset = '1' then
		state_reg <= idle;
		r1_reg <= (others=>'0');
		r2_reg <= (others=>'0');
		d_reg <= (others=>'0');
		n_reg <= (others=>'0');
		
	elsif( clk_1hz'event and clk_1hz='1') then
		state_reg <= state_next;
		r1_reg <= r1_next;
		r2_reg <= r2_next;
		d_reg <= d_next;
		n_reg <= n_next;
		end if;
end process;

--COMBINATIONAL CIRCUIT
process (state_reg, start, r1_reg, r2_reg, d_reg, n_reg)
begin

	--default values
	r1_next <= r1_reg;
	r2_next <= r2_reg;
	d_next <= d_reg;
	n_next <= n_reg;
	
	case state_reg is
		when idle =>
			if (start='1') then
				r1_next <= (others=>'0');
				r2_next <= dividend;
				d_next <= divisor;
				n_next <= "111";
				result_is_equal <= '0';
				state_next <= op;
			else
				state_next <= idle;
			end if;

		when op=>
			if (r1_reg >= ("00" & d_reg)) then
				r1_tmp <= std_logic_vector(unsigned(r1_reg) - unsigned(d_reg));
				q_bit <= '1';
			else
				r1_tmp <= r1_reg;
				q_bit <= '0';
			end if;
			
			r1_next <= r1_tmp(4 downto 0) & r2_reg(5);
			r2_next <= r2_reg(4 downto 0) & q_bit;
			n_next <= n_reg - 1;
			
			if (n_reg = 2) then
				state_next <= last;
			else 
				state_next <= op;
			end if;

		when last=>
			r1_next <= r1_tmp;
			r2_next <= r2_reg(4 downto 0) & q_bit;
			state_next <= is_equal;
			
		when is_equal=>
			if (r2_reg = r1_reg) then 
				result_is_equal <= '1';
			else result_is_equal <= '0';
			end if;
			state_next <= done;
			
		when done=>
			state_next <= idle;

	end case;

end process;

quotient <= r2_reg;
remainder <= r1_reg;

Seven_segment : seven_four
	Port map(in1 => remainder (3 downto 0), in2 => quotient(3 downto 0),
			   in3=>state_out, in4=>state_out_led, 
				clk=>clk, dp=>dp, sel=>seg_sel_4, segment=>seg_out_7);

-- Seven segment related part
seg_out <= (seg_out_7 & dp);
seg_sel <= "1111" & seg_sel_4;


state_out <= "0000" when (state_reg = idle) else  -- 0
				 "0001" when (state_reg = op) else  -- 1
				 "0010" when (state_reg = last) else  -- 2
				 "0011" when (state_reg = is_equal) else  -- 3
				 "0100" when (state_reg = done) else  -- 4
				 "1111";

done_led <= '1' when (state_reg = done) else '0';
state_out_led <= '0' & std_logic_vector(n_reg);

end Behavioral;

