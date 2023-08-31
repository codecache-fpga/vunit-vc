
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

use work.spi_slave_pkg.all;

entity spi_slave is
  generic(
    vc : spi_slave_t
  );

  port(
    sclk : in  std_logic;
    mosi : in std_logic;
    miso : out  std_logic;
    cs   : in  std_logic
  );
end entity;

architecture sim of spi_slave is

  procedure process_transaction(signal   net  : inout network_t;
                                variable msg  : inout msg_t;
                                signal   miso : out std_logic;
                                signal   mosi : in std_logic
                               ) is
    variable bit_num        : natural := 0;
    variable spi_tx, spi_rx : std_logic_vector(spi_num_bits - 1 downto 0);
    variable reply_msg      : msg_t;
  begin
    -- Read data to be sent on SPI bus from message
    spi_tx := pop(msg);

    wait until falling_edge(cs);
    miso <= spi_tx(spi_tx'high);

    wait until rising_edge(sclk);
    spi_rx(bit_num) := mosi;
     
    bit_num := spi_num_bits - 1;

    while bit_num > 0 loop
      wait until rising_edge(sclk);
      spi_rx(bit_num) := mosi;
      
      wait until falling_edge(sclk);
      miso <= spi_tx(bit_num);

      bit_num := bit_num - 1;
    end loop;

    spi_rx := (others => '0');

    -- Reply with received data
    push(reply_msg, spi_rx);
    reply(net, msg, reply_msg);
  end procedure;

begin

  msg_handler : process
    variable request_message : msg_t;
    variable msg_type        : msg_type_t;
  begin
    receive(net, vc.actor, request_message);
    msg_type := message_type(request_message);

    if msg_type = spi_transaction_msg then
      process_transaction(net, request_message, miso, mosi);
    else
      handle_wait_until_idle(net, msg_type, request_message);
    end if;
  end process;

end architecture;
