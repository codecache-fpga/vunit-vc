--------------------------------------------------------------------------------------------------
-- Copyright (c) Sebastian Hellgren. All rights reserved.
--------------------------------------------------------------------------------------------------

-- Specific API for SPI slave. VUnit Stream VCI (Verification Component) is also supported, except 
-- the wait_for_time method.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

package spi_slave_pkg is

  constant check_spi_slave_msg : msg_type_t := new_msg_type("spi slave check msg");
  constant spi_slave_set_idle_data_msg : msg_type_t := new_msg_type("spi slave set idle data msg");
  constant spi_slave_clear_idle_data_msg : msg_type_t := new_msg_type("spi slave clear idle data msg");

  constant spi_num_bits : positive := 8;

  type spi_slave_t is record
    p_actor : actor_t;
  end record;

  impure function new_spi_slave return spi_slave_t;
  impure function as_stream_master(spi_slave : spi_slave_t) return stream_master_t;
  impure function as_stream_slave(spi_slave : spi_slave_t) return stream_slave_t;
  impure function as_sync(spi_slave : spi_slave_t) return sync_handle_t;

  procedure set_idle_data(signal net : inout network_t; slave : spi_slave_t; idle_data : std_logic_vector);
  procedure clear_idle_data(signal net : inout network_t; slave : spi_slave_t);

  procedure check_spi_transaction(signal net              : inout network_t;
                                     spi_slave               : spi_slave_t;
                                     expected                : std_logic_vector;
                                     channel_closed_expected : boolean
                                    );
end package;

package body spi_slave_pkg is

  impure function new_spi_slave return spi_slave_t is
  begin
    return (p_actor => new_actor
           );
  end function;

  impure function as_stream_master(spi_slave : spi_slave_t) return stream_master_t is
  begin
    return (p_actor => spi_slave.p_actor);
  end function;

  impure function as_stream_slave(spi_slave : spi_slave_t) return stream_slave_t is
  begin
    return (p_actor => spi_slave.p_actor);
  end function;

  impure function as_sync(spi_slave : spi_slave_t) return sync_handle_t is
  begin
    return spi_slave.p_actor;
  end function;
  
  -- Set idle data to be sent by slave if no data is queued.
  -- If no idle data is set and a transaction occurs, simulation will fail.
  -- All pending tx transactions will be flushed
  procedure set_idle_data(signal net : inout network_t; slave : spi_slave_t; idle_data : std_logic_vector) is
    variable msg : msg_t := new_msg(spi_slave_set_idle_data_msg);
    variable ack : boolean;
  begin
    push(msg, idle_data);
    request(net, slave.p_actor, msg, ack);
    assert ack report "Failed to set idle data";
  end procedure;

  -- Clear idle data
  procedure clear_idle_data(signal net : inout network_t; slave : spi_slave_t) is
    variable msg : msg_t := new_msg(spi_slave_clear_idle_data_msg);
    variable ack : boolean;
  begin
    request(net, slave.p_actor, msg, ack);
    assert ack report "Failed to clear idle data";
  end procedure;
          
  -- Non-blocking alternative to stream VCI check_stream
  procedure check_spi_transaction(signal net              : inout network_t;
                                  spi_slave               : spi_slave_t;
                                  expected                : std_logic_vector;
                                  channel_closed_expected : boolean
                                 ) is
    variable msg : msg_t := new_msg(check_spi_slave_msg);
  begin
    push(msg, expected);
    push(msg, channel_closed_expected);

    send(net, spi_slave.p_actor, msg);
  end procedure;

end package body;
