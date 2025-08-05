-- md5_data.vdh

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity md5_data is
    port (
        avs_s0_address    : in  std_logic_vector(3 downto 0) := (others => '0');  -- Avalon address bus
        avs_s0_read       : in  std_logic := '0';                                  -- Read strobe
        avs_s0_write      : in  std_logic := '0';                                  -- Write strobe
        avs_s0_readdata   : out std_logic_vector(31 downto 0);                     -- Read data
        avs_s0_writedata  : in  std_logic_vector(31 downto 0) := (others => '0');  -- Write data
        clk               : in  std_logic := '0';                                  -- Clock
        reset             : in  std_logic := '0';                                  -- Global reset
        md5_writedata     : out std_logic_vector(31 downto 0);                     
        md5_writeaddr     : out std_logic_vector(8 downto 0);                      
        md5_readdata      : in  std_logic_vector(31 downto 0);                     
        md5_readaddr      : out std_logic_vector(6 downto 0)                      
    );
end entity md5_data;

architecture rtl of md5_data is
    signal data_reg       : std_logic_vector(31 downto 0);
    signal write_addr_reg : std_logic_vector(8 downto 0);
    signal read_addr_reg  : std_logic_vector(6 downto 0);
begin

    process(clk, reset)
    begin
        if reset = '1' then
            data_reg       <= (others => '0');
            write_addr_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if avs_s0_write = '1' then
                data_reg       <= avs_s0_writedata;
                write_addr_reg <= "00000" & avs_s0_address; 
            end if;
        end if;
    end process;
    
    md5_writedata <= data_reg;
    md5_writeaddr <= write_addr_reg;
    
    process(clk, reset)
    begin
        if reset = '1' then
            read_addr_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if avs_s0_read = '1' then
                read_addr_reg <= "000" & avs_s0_address;
            end if;
        end if;
    end process;
    
    md5_readaddr <= read_addr_reg;

    process(clk, reset, avs_s0_read)
    begin
        if reset = '1' then
            avs_s0_readdata <= (others => '0');
        elsif (rising_edge(clk)) then
            if avs_s0_read = '1' then
                avs_s0_readdata <= md5_readdata;
            end if;
        end if;
    end process;

end architecture rtl;
