library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

package spi_slave_pkg is

  constant spi_transaction_msg : msg_type_t := new_msg_type("spi transaction");

  constant spi_num_bits : positive := 8;

  type spi_slave_t is record
    actor : actor_t;
  end record;

  impure function new_spi_slave return spi_slave_t;

  procedure send_spi_transaction(signal   net     : inout network_t;
                                 spi_slave        : spi_slave_t;
                                 variable data_tx : in std_logic_vector;
                                 variable future  : inout msg_t
                                );

  procedure receive_spi_transaction(signal   net            : inout network_t;
                                    variable future         : inout msg_t;
                                    variable data_rx        : out std_logic_vector;
                                    variable channel_closed : out boolean
                                   );

  procedure wait_until_idle(signal net : inout network_t; spi_slave : spi_slave_t);
end package;

package body spi_slave_pkg is

  impure function new_spi_slave return spi_slave_t is
  begin
    return (actor => new_actor);
  end function;

  -- Send a single byte SPI transaction (non blocking)
  procedure send_spi_transaction(signal   net     : inout network_t;
                                 spi_slave        : spi_slave_t;
                                 variable data_tx : in std_logic_vector;
                                 variable future  : inout msg_t
                                ) is
  begin
    future := new_msg(spi_transaction_msg);
    push_std_ulogic_vector(future, data_tx);
    send(net, spi_slave.actor, future);
  end procedure;

  -- Receive a single byte SPI transaction based on previous sent transaction (blocking)
  procedure receive_spi_transaction(signal   net            : inout network_t;
                                    variable future         : inout msg_t;
                                    variable data_rx        : out std_logic_vector;
                                    variable channel_closed : out boolean
                                   ) is
    variable reply_msg : msg_t;
  begin
    receive_reply(net, future, reply_msg);
    data_rx        := pop(reply_msg);
    channel_closed := pop(reply_msg);
  end procedure;

  -- Wait until SPI slave is idle
  procedure wait_until_idle(signal net : inout network_t; spi_slave : spi_slave_t) is
  begin
    wait_until_idle(net, spi_slave.actor);
  end procedure;

end package body;
