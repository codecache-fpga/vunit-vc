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

package spi_memory_pkg is 

  type spi_memory_t is record 
    p_spi_slave : spi_slave_t;
    p_memory : memory_t;
  end record;
  
  type spi_memory_transaction_t is record
    data : integer_array_t;
  end record;

  impure function new_spi_memory(mem : memory_t := null_memory) return spi_memory_t;
  impure function as_memory(spi_mem : spi_memory_t) return memory_t;

  impure function new_spi_memory_transaction return spi_memory_transaction_t;

  type spi_memory_cmd_t is (read, write, sector_erase);

  constant write_cmd : std_logic_vector(spi_num_bits - 1 downto 0) := x"02";
  constant read_cmd : std_logic_vector(spi_num_bits - 1 downto 0) :=  x"03";
  constant sector_erase_cmd : std_logic_vector(spi_num_bits - 1 downto 0) := x"d8";

  type spi_cmd_t is (no_cmd, page_program, read, sector_erase);
  
  function to_spi_cmd(data : std_logic_vector) return spi_cmd_t;
  function has_address(cmd : spi_cmd_t) return boolean;
  function has_data(cmd : spi_cmd_t) return boolean;

  constant sector_size : natural := 4 * 1024;

end package;

package body spi_memory_pkg is
  impure function new_spi_memory(mem : memory_t := null_memory) return spi_memory_t is
    variable memory : memory_t;
  begin
    if mem = null_memory then
      memory := new_memory;
    end if;

    return (p_spi_slave => new_spi_slave,
            p_memory => memory);
  end function;

  impure function as_memory(spi_mem : spi_memory_t) return memory_t is
  begin
    return spi_mem.p_memory;
  end function;

  function to_spi_cmd(slv : std_logic_vector) return spi_cmd_t is
  begin
    case slv is
    when write_cmd =>
      return page_program;
    when read_cmd => 
      return read;
    when sector_erase_cmd =>
      return sector_erase;
    when others => 
      return no_cmd;
    end case;
  end function;
    
  function has_address(cmd : spi_cmd_t) return boolean is
  begin
    return (cmd = page_program or cmd = read or cmd = sector_erase);
  end function;

  procedure erase_sector(spi_mem : spi_memory_t; address : std_logic_vector) is
    variable start_sector : natural;
    variable start_addr : natural;
    variable end_addr : natural;
  begin
    start_sector := to_integer(unsigned(address)) / sector_size;

    start_addr := start_sector * sector_size;
    end_addr := (start_sector + 1) * sector_size - 1;

    for addr in start_addr to end_addr loop
      
    end loop;

  end procedure;

end package body;