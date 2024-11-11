--------------------------------------------------------------------------------------------------
-- Copyright (c) Sebastian Hellgren. All rights reserved.
--------------------------------------------------------------------------------------------------

-- Simple SPI slave supporting SPI mode 0 (CPOL = 0, CPHA = 0)
-- Supports VUnit Stream VCI, except for wait_for_time.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

use work.spi_slave_pkg.all;

entity spi_slave is
  generic(
    slave : spi_slave_t
  );
  port(
    sclk : in  std_logic;
    mosi : in  std_logic;
    miso : out std_logic;
    cs   : in  std_logic
  );
end entity;

architecture sim of spi_slave is
  signal miso_int : std_logic;

  constant tx_queue : queue_t := new_queue;
  constant rx_queue : queue_t := new_queue;

  signal has_idle_data : boolean := false;
  signal idle_data : std_logic_vector(spi_num_bits - 1 downto 0) := (others => '0');

  signal new_rx_msg : event_t;
  signal tx_complete : event_t;
begin

  tx_handler : process
    variable spi_tx : std_logic_vector(spi_num_bits - 1 downto 0);
    variable bit_num : natural range 0 to spi_num_bits - 1 := 0;
  begin
    wait until cs'event or sclk'event;
    if cs = '1' then
      bit_num := 0;
      notify(tx_complete);
    elsif cs = '0' then
      if falling_edge(sclk) then
        if bit_num = 0 then
          if has_idle_data then
            spi_tx := idle_data;
          else
            check_false(is_empty(tx_queue), "Transaction was requested without populating tx data");
            spi_tx := pop(tx_queue);
            bit_num := spi_num_bits - 1;
          end if;
        else
          bit_num := bit_num - 1;
        end if;
      end if;
    end if;

    miso_int <= spi_tx(bit_num);
  end process;

  miso <= miso_int when cs = '0' else 'Z';

  rx_handler : process is
    variable msg : msg_t;
    variable reply_msg : msg_t := new_msg;
    variable spi_rx, expected : std_logic_vector(spi_num_bits - 1 downto 0);
    variable channel_closed : boolean;
    variable last : boolean;
    constant key : key_t := get_entry_key(test_runner_cleanup);
  begin
    if is_empty(rx_queue) then
      wait until is_active(new_rx_msg);
    end if;

    msg := pop(rx_queue);

    lock(runner, key);

    for bit_num in spi_rx'range loop
      wait until rising_edge(sclk);
      spi_rx(bit_num) := mosi;
    end loop;
    
    -- Determine if channel is closed or not
    wait until cs'event or sclk'event;
    
    if rising_edge(cs) then
      channel_closed := true;
    elsif rising_edge(sclk) then
      channel_closed := false;
    end if;

    if message_type(msg) = spi_slave_check_msg then
      -- Check received data
      expected := pop(msg);
      last     := pop(msg);

      check_equal(spi_rx, expected);
      check_equal(channel_closed, last);
    elsif message_type(msg) = stream_pop_msg then
      -- Respond with received data
      reply_msg := new_msg;
      push(reply_msg, spi_rx);
      push(reply_msg, channel_closed);

      -- Reply with received data
      reply(net, msg, reply_msg);
    end if;

    unlock(runner, key);
  end process;

  msg_handler : process
    variable request_message : msg_t;
    variable msg_type        : msg_type_t;
  begin
    receive(net, slave.p_actor, request_message);
    msg_type := message_type(request_message);
    
    handle_wait_until_idle(net, msg_type, request_message);

    if msg_type = stream_pop_msg or msg_type = spi_slave_check_msg then
      push(rx_queue, request_message);
      notify(new_rx_msg);
    elsif msg_type = stream_push_msg then
      push(tx_queue, pop_std_ulogic_vector(request_message));
    elsif msg_type = spi_slave_set_idle_data_msg then
      idle_data <= pop(request_message);
      has_idle_data <= true;
      flush(tx_queue);
      acknowledge(net, request_message);
    elsif msg_type = spi_slave_clear_idle_data_msg then
      has_idle_data <= false;
      acknowledge(net, request_message);
    else
      unexpected_msg_type(msg_type);
    end if;
  end process;

end architecture;
