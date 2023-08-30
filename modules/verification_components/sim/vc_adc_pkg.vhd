library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.data_types_context;
context vunit_lib.vc_context;

package vc_adc_pkg is

  -- Message types
  constant vc_adc_set_value_msg : msg_type_t := new_msg_type("vc_adc_set_value");

  type vc_adc_t is record
    actor       : actor_t;
    ref_voltage : real;
    num_bits    : positive;
  end record;

  impure function new_vc_adc(ref_voltage : real; num_bits : positive) return vc_adc_t;
  function get_num_bits(vc : vc_adc_t) return positive;
  function calc_output(vc : vc_adc_t; voltage : real) return std_logic_vector;

  procedure vc_adc_set_value(signal net : inout network_t; vc : vc_adc_t; voltage : real);

end package;

package body vc_adc_pkg is

  impure function new_vc_adc(ref_voltage : real; num_bits : positive) return vc_adc_t is
  begin
    return (actor       => new_actor,
            ref_voltage => ref_voltage,
            num_bits    => num_bits);
  end function;

  function get_num_bits(vc : vc_adc_t) return positive is
  begin
    return vc.num_bits;
  end function;

  function calc_output(vc : vc_adc_t; voltage : real) return std_logic_vector is
    variable ret : std_logic_vector(get_num_bits(vc) - 1 downto 0);
    variable ret_real : real;
  begin
    if voltage > vc.ref_voltage then
      ret := (others => '1');
    elsif voltage < 0.0 then
      ret := (others => '0');
    else
      ret_real := real(2 ** vc.num_bits - 1) * voltage / vc.ref_voltage;
      ret := std_logic_vector(to_unsigned(integer(ret_real), get_num_bits(vc)));
    end if;

    return ret;
  end function;

  procedure vc_adc_set_value(signal net : inout network_t; vc : vc_adc_t; voltage : real) is
    variable message : msg_t := new_msg(vc_adc_set_value_msg);
  begin
    push_real(message, voltage);
    send(net, vc.actor, message);
  end procedure;

end package body;
