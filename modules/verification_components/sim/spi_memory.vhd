--------------------------------------------------------------------------------------------------
-- Copyright (c) Sebastian Hellgren. All rights reserved.
--------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

use work.spi_slave_pkg.all;
use work.spi_memory_pkg.all;

-- TODO: Num address bits

entity spi_memory is
  generic (
    spi_memory : spi_memory_t
  );
  port(
    sclk : in  std_logic;
    mosi : in  std_logic;
    miso : out std_logic;
    cs   : in  std_logic
  );
end entity;

architecture sim of spi_memory is
  constant stream_master : stream_master_t := as_stream_master(spi_memory.p_spi_slave);
  constant stream_slave : stream_slave_t := as_stream_slave(spi_memory.p_spi_slave);

  constant address_bytes : natural := 3;

  function in_address_range(cnt : natural) return boolean is
  begin
    return (cnt > 1) and (cnt < 1 + address_bytes);
  end function;
begin
  spi_slave_inst: entity work.spi_slave
   generic map(
      slave => spi_memory.p_spi_slave
  )
   port map(
      sclk => sclk,
      mosi => mosi,
      miso => miso,
      cs => cs
  );

  main : process
    variable cmd : spi_cmd_t := no_cmd;
    variable spi_data : std_logic_vector(spi_num_bits - 1 downto 0);
    variable address : std_logic_vector(31 downto 0);
    variable last : boolean;
    variable count : natural;
    constant write_data : integer_array_t := new_1d(bit_width => 8, is_signed => false);
  begin
    last := false;
    cmd := no_cmd;
    count := 0;
    

    while not last loop
      pop_stream(net, stream_slave, spi_data, last);

      if count = 1 then
        cmd := to_spi_cmd(spi_data);
      end if;
      
      -- Store address
      if has_address(cmd) and in_address_range(count) then
        for i in address_bytes - 1 downto 0 loop
          address((i+1)*8 - 1 downto i*8) := spi_data;
        end loop;
      end if;

      -- Act upon command
      case cmd is
        when read =>
           
        when page_program =>
          if in_data_range(count) then
          end if; 
        when sector_erase => 
          erase_sector(address);
      end case;


      count := count + 1;
    end loop;

    -- Commit command
      
  end process;
end architecture;