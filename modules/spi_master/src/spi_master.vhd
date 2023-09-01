-- Simple SPI slave supporting SPI mode 0 (CPOL = 0, CPHA = 0)
-- Output SPI clock is clk divided by 2

-- TODO: AXI stream interfaces
-- TODO: Back to back transactions

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_master_pkg.all;

entity spi_master is
  port(
    clk            : in  std_logic;
    -- Module interface
    data_in_valid  : in  std_logic;
    data_in        : in  std_logic_vector(spi_num_bits - 1 downto 0);
    data_out_valid : out std_logic;
    data_out       : out std_logic_vector(spi_num_bits - 1 downto 0);
    -- SPI interface
    spi_sclk       : out std_logic;
    spi_mosi       : out std_logic;
    spi_miso       : in  std_logic;
    spi_cs         : out std_logic
  );
end entity;

architecture rtl of spi_master is

  signal spi_clk_en : std_logic;

  type spi_state_t is (idle, transfer);
  signal spi_state        : spi_state_t := idle;
  signal data_tx, data_rx : std_logic_vector(spi_num_bits - 1 downto 0);
  
  signal sclk_rising      : std_logic;
  signal sclk_falling     : std_logic;
begin

  spi_clk_gen : process
  begin
    wait until rising_edge(clk);

    if spi_clk_en then
      spi_sclk <= not spi_sclk;
    else
      spi_sclk <= '0';
    end if;
  end process;

  spi_tx : process
    variable bit_count : natural range 0 to spi_num_bits - 1 := 0;
  begin
    wait until rising_edge(clk);

    spi_cs         <= '1';
    spi_clk_en     <= '0';
    data_out_valid <= '0';

    case spi_state is
      when idle =>

        if data_in_valid then
          data_tx   <= data_in;
          spi_state <= transfer;
          spi_cs    <= '0';
          spi_mosi  <= data_in(7 - bit_count);
        end if;

      when transfer =>

        spi_clk_en <= '1';
        spi_cs     <= '0';
        
        if sclk_falling then
          if bit_count = spi_num_bits - 1 then
            bit_count      := 0;
            spi_state      <= idle;
            
            data_out       <= data_rx;
            data_out_valid <= '1';
            
            spi_cs         <= '1';
            spi_clk_en     <= '0';
          else
            bit_count := bit_count + 1;
            spi_mosi  <= data_in(spi_num_bits - 1 - bit_count);
          end if;
        end if;
    end case;
  end process;
  
  sclk_rising  <= not spi_sclk and spi_clk_en;
  sclk_falling <= spi_sclk and spi_clk_en;

  spi_rx : process
    variable bit_count : natural range 0 to spi_num_bits - 1 := 0;
  begin
    wait until rising_edge(clk);

    if sclk_rising then
      data_rx(spi_num_bits - 1 - bit_count) <= spi_miso;
      if bit_count = spi_num_bits - 1 then
        bit_count := 0;
      else
        bit_count := bit_count + 1;
      end if;
    end if;

  end process;
end architecture;
