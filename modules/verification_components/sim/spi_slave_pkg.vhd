library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

package spi_slave_pkg is

  constant spi_transaction_msg : msg_type_t := new_msg_type("spi transaction");
  
  constant spi_num_bits : positive := 8;

  type spi_slave_t is record
    actor : actor_t;
  end record;

  impure function new_spi_slave return spi_slave_t;

end package;

package body spi_slave_pkg is

  impure function new_spi_slave return spi_slave_t is
  begin
    return (actor => new_actor);
  end function;

end package body;
