-- md5_data.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity md5_data is
    port (
        avs_s0_address   : in  std_logic_vector(3 downto 0) := (others => '0');  -- Avalon address bus
        avs_s0_read      : in  std_logic := '0';                                 -- Read strobe
        avs_s0_write     : in  std_logic := '0';                                 -- Write strobe
        avs_s0_readdata  : out std_logic_vector(31 downto 0);                    -- Read data
        avs_s0_writedata : in  std_logic_vector(31 downto 0) := (others => '0'); -- Write data
        clk              : in  std_logic := '0';                                 -- Clock
        reset            : in  std_logic := '0';                                 -- Global reset
        md5_writedata    : out std_logic_vector(31 downto 0);                    
        md5_writeaddr    : out std_logic_vector(8 downto 0);                    
        md5_readdata     : in  std_logic_vector(31 downto 0);                    
        md5_readaddr     : out std_logic_vector(6 downto 0)                      
    );
end entity md5_data;

architecture rtl of md5_data is
    signal data_reg       : std_logic_vector(31 downto 0);
    signal write_addr_reg : std_logic_vector(8 downto 0);
    signal read_addr_reg  : std_logic_vector(6 downto 0);
begin
    md5_writedata <= data_reg;
    md5_writeaddr <= write_addr_reg;
    md5_readaddr  <= read_addr_reg;

    process(clk, reset)
    begin
        if reset = '1' then
            data_reg        <= (others => '0');
            write_addr_reg  <= (others => '0');
            read_addr_reg   <= (others => '0');
            avs_s0_readdata <= (others => '0');
        elsif rising_edge(clk) then
            if avs_s0_write = '1' then
                case avs_s0_address is
                    when "0000" =>
                        data_reg <= avs_s0_writedata;
                    when "0001" =>
                        write_addr_reg <= avs_s0_writedata(8 downto 0);
                    when "0010" =>
                        read_addr_reg <= avs_s0_writedata(6 downto 0);
                    when others =>
                        null;
                end case;
            end if;
            
            if avs_s0_read = '1' then
                case avs_s0_address is
                    when "0000" =>
                        avs_s0_readdata <= md5_readdata;
                    when "0001" =>
                        avs_s0_readdata <= data_reg;
                    when "0010" =>
                        avs_s0_readdata <= write_addr_reg & std_logic_vector(to_unsigned(0, 23));
                    when "0011" =>
                        avs_s0_readdata <= read_addr_reg & std_logic_vector(to_unsigned(0, 25));
                    when others =>
                        avs_s0_readdata <= (others => '0');
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
