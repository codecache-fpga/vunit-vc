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

  procedure receive_spi_transaction(signal   net     : inout network_t;
                                    variable data_rx : out std_logic_vector;
                                    variable future  : inout msg_t
                                   );

  procedure spi_transaction(signal   net     : inout network_t;
                            spi_slave        : spi_slave_t;
                            variable data_tx : in std_logic_vector;
                            variable data_rx : out std_logic_vector);

  procedure wait_until_idle(signal net : inout network_t; spi_slave : spi_slave_t);
end package;

package body spi_slave_pkg is

  impure function new_spi_slave return spi_slave_t is
  begin
    return (actor => new_actor);
  end function;

  -- Send an SPI transaction (non blocking)
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

  -- Receive an SPI transaction based on previous sent transaction (blocking)
  procedure receive_spi_transaction(signal   net     : inout network_t;
                                    variable data_rx : out std_logic_vector;
                                    variable future  : inout msg_t
                                   ) is
    variable reply_msg : msg_t;
  begin
    receive_reply(net, future, reply_msg);
    data_rx := pop_std_ulogic_vector(reply_msg);
  end procedure;

  -- Send and receive SPI transaction (blocking)
  procedure spi_transaction(signal   net     : inout network_t;
                            spi_slave        : spi_slave_t;
                            variable data_tx : in std_logic_vector;
                            variable data_rx : out std_logic_vector) is
    variable msg : msg_t;
  begin
    msg := new_msg(spi_transaction_msg);
    send_spi_transaction(net, spi_slave, data_tx, msg);

    receive_spi_transaction(net, data_rx, msg);
  end procedure;

  procedure wait_until_idle(signal net : inout network_t; spi_slave : spi_slave_t) is
  begin
    wait_until_idle(net, spi_slave.actor);
  end procedure;

end package body;
