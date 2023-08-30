-- Simple verification component for an SPI ADC

-- TODO: Multi-channel
-- TODO: Set offset
-- TODO: Add timings

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

use work.vc_adc_pkg.all;

entity vc_adc_par is
  generic(
    vc : vc_adc_t
  );
  port(
    sclk  : in  std_logic;
    dout  : out std_logic_vector(get_num_bits(vc) - 1 downto 0);
    cnvst : in  std_logic
  );
end entity;

architecture sim of vc_adc_par is

  procedure process_set_value(variable msg : in msg_t; signal dout : out std_logic_vector) is
    variable voltage      : real;
  begin
    wait until falling_edge(cnvst);

    voltage      := pop_real(msg);

    dout <= calc_output(vc, voltage);
  end procedure;

begin

  msg_handler : process
    variable request_message : msg_t;
    variable msg_type        : msg_type_t;
  begin
    receive(net, vc.actor, request_message);
    msg_type := message_type(request_message);

    if msg_type = vc_adc_set_value_msg then
      process_set_value(request_message, dout);
    else
      handle_wait_until_idle(net, msg_type, request_message);
    end if;
  end process;

end architecture;
