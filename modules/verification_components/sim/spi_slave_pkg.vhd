--------------------------------------------------------------------------------------------------
-- Copyright (c) Sebastian Hellgren. All rights reserved.
--------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

package spi_slave_pkg is

  constant spi_slave_check_msg : msg_type_t := new_msg_type("spi slave check msg");
  constant spi_slave_reply_msg : msg_type_t := new_msg_type("spi slave reply msg");

  constant spi_num_bits : positive := 8;

  type spi_slave_t is record
    p_slave_actor : actor_t;
    p_master_actor : actor_t;
  end record;

  impure function new_spi_slave return spi_slave_t;
  impure function as_stream_master(spi_slave : spi_slave_t) return stream_master_t;
  impure function as_stream_slave(spi_slave : spi_slave_t) return stream_slave_t;

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
    return (p_slave_actor => new_actor,
            p_master_actor => new_actor
           );
  end function;

  impure function as_stream_master(spi_slave : spi_slave_t) return stream_master_t is
  begin
    return (p_actor => spi_slave.p_master_actor);
  end function;

  impure function as_stream_slave(spi_slave : spi_slave_t) return stream_slave_t is
  begin
    return (p_actor => spi_slave.p_slave_actor);
  end function;

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

    send(net, spi_slave.p_slave_actor, msg);
  end procedure;

  -- Wait until SPI slave is idle
  procedure wait_until_idle(signal net : inout network_t; spi_slave : spi_slave_t) is
  begin
    wait_until_idle(net, spi_slave.p_slave_actor);
    wait_until_idle(net, spi_slave.p_master_actor);
  end procedure;

end package body;
