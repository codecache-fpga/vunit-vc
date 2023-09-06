library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

package spi_slave_pkg is

  constant spi_slave_rx_msg    : msg_type_t := new_msg_type("spi slave msg");
  constant spi_slave_check_msg : msg_type_t := new_msg_type("spi slave check msg");
  constant spi_slave_reply_msg : msg_type_t := new_msg_type("spi slave reply msg");

  constant spi_num_bits : positive := 8;

  type spi_slave_t is record
    rx_actor : actor_t;
    tx_actor : actor_t;
  end record;

  impure function new_spi_slave return spi_slave_t;

  procedure push_spi_tx_transaction(signal net : inout network_t;
                                    spi_slave  : spi_slave_t;
                                    data_tx    : std_logic_vector
                                   );

  procedure await_spi_rx_transaction(signal   net            : inout network_t;
                                     spi_slave               : spi_slave_t;
                                     variable data_rx        : out std_logic_vector;
                                     variable channel_closed : out boolean
                                    );

  procedure check_spi_rx_transaction(signal net              : inout network_t;
                                     spi_slave               : spi_slave_t;
                                     expected                : std_logic_vector;
                                     channel_closed_expected : boolean
                                    );

  procedure wait_until_idle(signal net : inout network_t; spi_slave : spi_slave_t);
end package;

package body spi_slave_pkg is

  impure function new_spi_slave return spi_slave_t is
  begin
    return (rx_actor => new_actor,
            tx_actor => new_actor
           );
  end function;

  -- Send a single byte SPI transaction (non blocking)
  procedure push_spi_tx_transaction(signal net : inout network_t;
                                    spi_slave  : spi_slave_t;
                                    data_tx    : std_logic_vector
                                   ) is
    variable msg : msg_t := new_msg(spi_slave_rx_msg);
  begin
    push_std_ulogic_vector(msg, data_tx);
    send(net, spi_slave.tx_actor, msg);
  end procedure;

  -- Receive a single byte SPI transaction based on previous sent transaction (blocking)
  procedure await_spi_rx_transaction(signal   net            : inout network_t;
                                     spi_slave               : spi_slave_t;
                                     variable data_rx        : out std_logic_vector;
                                     variable channel_closed : out boolean
                                    ) is
    variable msg       : msg_t := new_msg(spi_slave_rx_msg);
    variable reply_msg : msg_t;
  begin
    send(net, spi_slave.rx_actor, msg);

    receive_reply(net, msg, reply_msg);
    data_rx        := pop(reply_msg);
    channel_closed := pop(reply_msg);
  end procedure;

  -- Check a single byte SPI slave RX transaction (non-blocking)
  -- This consumes a response in the slave
  procedure check_spi_rx_transaction(signal net              : inout network_t;
                                     spi_slave               : spi_slave_t;
                                     expected                : std_logic_vector;
                                     channel_closed_expected : boolean
                                    ) is
    variable msg : msg_t := new_msg(spi_slave_check_msg);
  begin
    push(msg, expected);
    push(msg, channel_closed_expected);

    send(net, spi_slave.rx_actor, msg);
  end procedure;

  -- Wait until SPI slave is idle
  procedure wait_until_idle(signal net : inout network_t; spi_slave : spi_slave_t) is
  begin
    wait_until_idle(net, spi_slave.rx_actor);
    wait_until_idle(net, spi_slave.tx_actor);
  end procedure;

end package body;
