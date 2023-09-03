-- Simple SPI slave supporting SPI mode 0 (CPOL = 0, CPHA = 0)

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

  procedure process_transaction(signal   net  : inout network_t;
                                variable msg  : inout msg_t;
                                signal   miso : out std_logic;
                                signal   mosi : in std_logic
                               ) is
    variable bit_num        : natural := spi_num_bits;
    variable spi_tx, spi_rx : std_logic_vector(spi_num_bits - 1 downto 0);
    variable reply_msg      : msg_t   := new_msg(spi_transaction_msg);
    variable channel_closed : boolean;
  begin
    -- Read data to be sent on SPI bus from message
    spi_tx := pop(msg);

    wait until falling_edge(cs) or sclk = '1';
    miso <= spi_tx(bit_num - 1);

    while bit_num > 0 loop

      bit_num         := bit_num - 1;
      wait until rising_edge(sclk);
      spi_rx(bit_num) := mosi;

      if bit_num > 0 then
        wait until falling_edge(sclk);
        miso <= spi_tx(bit_num - 1);
      end if;
    end loop;

    -- Determine if channel is closed or not
    wait until cs'event or sclk'event;
    
    if rising_edge(cs) then
      channel_closed := true;
    elsif rising_edge(sclk) then
      channel_closed := false;
    end if;

    -- Add received data to msg
    push(reply_msg, spi_rx);
    push(reply_msg, channel_closed);

    -- Reply with received data
    reply(net, msg, reply_msg);

  end procedure;

begin

  msg_handler : process
    variable request_message : msg_t;
    variable msg_type        : msg_type_t;
  begin
    receive(net, slave.actor, request_message);
    msg_type := message_type(request_message);

    if msg_type = spi_transaction_msg then
      process_transaction(net, request_message, miso, mosi);
    else
      handle_wait_until_idle(net, msg_type, request_message);
    end if;
  end process;

end architecture;
