-- md5_control.vhd

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity md5_control is 
	port(
		avs_s0_address   : in  std_logic_vector(3 downto 0)  := (others => '0'); --         s0.address
		avs_s0_write     : in  std_logic                     := '0';             --           .write
		avs_s0_writedata : in  std_logic_vector(31 downto 0) := (others => '0'); --           .writedata
		avs_s0_read      : in  std_logic                     := '0';             --           .read
		avs_s0_readdata  : out std_logic_vector(31 downto 0);                    --           .readdata
		clk              : in  std_logic                     := '0';             --      clock.clk
		reset            : in  std_logic                     := '0';             --      reset.reset
		md5_start	 : out std_logic_vector(31 downto 0);
		md5_reset	 : out std_logic_vector(31 downto 0);
		md5_done	 : in std_logic_vector(31 downto 0)
	);
end entity md5_control;

architecture rtl of md5_control is
	
	SIGNAL start, reset2: std_logic_vector(31 downto 0);

BEGIN

	process(clk, reset, avs_s0_address, avs_s0_write, avs_s0_writedata, avs_s0_read)
	begin
		if(reset = '1') then
			start <= (OTHERS => '0');
			reset2 <= (OTHERS => '0');
		elsif(rising_edge(clk)) then
			if (avs_s0_write = '1') then
				CASE avs_s0_address is
					WHEN "0000" =>
						start <= avs_s0_writedata;
					WHEN "0001" =>
						reset2 <= avs_s0_writedata;
					WHEN OTHERS =>
				END CASE;
			elsif (avs_s0_read = '1') then
				reset2 <= (OTHERS => '0');
				CASE avs_s0_address is 
					WHEN "0000" =>
						avs_s0_readdata <= start;
					WHEN "0001" =>
						avs_s0_readdata <= reset2;
					WHEN "0010" =>
				 		avs_s0_readdata <= md5_done;
					WHEN OTHERS =>
				END CASE;
			END if;
		END if;
	end process;

	md5_start <= start;
	md5_reset <= reset2;
end architecture rtl;
 
