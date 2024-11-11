--------------------------------------------------------------------------------------------------
-- Copyright (c) Sebastian Hellgren. All rights reserved.
--------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library osvvm;
use osvvm.RandomPkg.all;

use work.spi_slave_pkg.all;

entity tb_spi_slave is
  generic(
    runner_cfg : string
  );
end entity;

architecture sim of tb_spi_slave is
  constant clk_period : time := 10 ns;

  constant spi_slave : spi_slave_t := new_spi_slave;

  constant spi_stream_master : stream_master_t := as_stream_master(spi_slave);
  constant spi_stream_slave : stream_slave_t := as_stream_slave(spi_slave);

  signal sclk : std_logic := '1';
  signal mosi : std_logic;
  signal miso : std_logic;
  signal cs : std_logic := '1';

  shared variable rnd : RandomPType;

  constant rx_check_queue : queue_t := new_queue;
  constant tx_check_queue : queue_t := new_queue;

  signal rx_check_new_data : event_t;
  signal tx_check_new_data : event_t;
begin

  main : process
    procedure send_transaction(data : std_logic_vector) is
    begin
      for idx in data'range loop
        mosi <= data(idx);
        sclk <= '0';
        wait for clk_period / 2;
        sclk <= '1';
        wait for clk_period / 2;
      end loop;
    end procedure;

    procedure test_rx_transaction(num_transactions : positive := 1) is
      variable data : std_logic_vector(spi_num_bits - 1 downto 0);
    begin
      cs <= '0';
      for i in 0 to num_transactions - 1 loop
        data := x"AA"; --rnd.RandSlv(data'length);
        push(rx_check_queue, data);
        notify(rx_check_new_data);
        send_transaction(data);
      end loop;
      cs <= '1';
    end procedure;

    procedure check_receive_transaction(data : std_logic_vector) is
    begin
      push(tx_check_queue, data);
      notify(tx_check_new_data);
    end procedure;

    procedure test_tx_transaction(num_transactions : positive := 1) is
      variable data : std_logic_vector(spi_num_bits - 1 downto 0);
    begin
      -- Prepare tx data
      for i in 0 to num_transactions - 1 loop
        data := rnd.RandSlv(data'length);
        push_stream(net, spi_stream_master, data);
        check_receive_transaction(data);
      end loop;

      wait_until_idle(net, as_sync(spi_slave));

      -- Perform transactions with master dummy data
      cs <= '0';
      for i in 0 to num_transactions - 1 loop
        send_transaction(x"AA");
      end loop;
      cs <= '1';
    end procedure;

    procedure test_bidir_transaction(num_transactions : positive := 1) is
      variable data : std_logic_vector(spi_num_bits - 1 downto 0);
    begin
      -- Prepare data
      for i in 0 to num_transactions - 1 loop
        data := rnd.RandSlv(data'length);
        push_stream(net, spi_stream_master, data);
        check_receive_transaction(data);
      end loop;

      wait_until_idle(net, as_sync(spi_slave));

      -- Perform transactions
      cs <= '0';
      for i in 0 to num_transactions - 1 loop
        data := rnd.RandSlv(data'length);
        push(rx_check_queue, data);
        notify(rx_check_new_data);
        send_transaction(data);
      end loop;
      cs <= '1';
    end procedure;

    variable num_bytes : positive;

  begin
    rnd.InitSeed(rnd'instance_name);

    test_runner_setup(runner, runner_cfg);

    wait for clk_period;

    if run("one_single_byte_rx_transaction") then
      set_idle_data(net, spi_slave, x"AA");
      test_rx_transaction;
    elsif run("many_single_byte_rx_transactions") then
      set_idle_data(net, spi_slave, x"AA");
      for i in 0 to 100 - 1 loop
        test_rx_transaction;
      end loop;
    elsif run("one_multi_byte_rx_transaction") then
      set_idle_data(net, spi_slave, x"AA");
      test_rx_transaction(8);
    elsif run("many_multi_byte_rx_transactions") then
      set_idle_data(net, spi_slave, x"AA");

      for i in 0 to 100 - 1 loop
        num_bytes := rnd.RandInt(2, 64);
        test_rx_transaction(num_bytes);
      end loop;

    elsif run("one_single_byte_tx_transaction") then
      clear_idle_data(net, spi_slave);
      test_tx_transaction;

    elsif run("many_single_byte_tx_transactions") then
      clear_idle_data(net, spi_slave);
      for i in 0 to 100 - 1 loop
        test_tx_transaction;
      end loop;

    elsif run("one_multi_byte_tx_transaction") then
      clear_idle_data(net, spi_slave);
      for i in 0 to 100 - 1 loop
        test_tx_transaction(8);
      end loop;
    
    elsif run("many_multi_byte_tx_transactions") then
      clear_idle_data(net, spi_slave);

      for i in 0 to 100 - 1 loop
        num_bytes := rnd.RandInt(2, 64);
        test_tx_transaction(num_bytes);
      end loop;

    elsif run("one_single_byte_bidirectional_transaction") then
      test_bidir_transaction;

    elsif run("many_single_byte_bidirectional_transactions") then
      for i in 0 to 100 - 1 loop
        test_bidir_transaction;
      end loop;

    elsif run("one_multi_byte_bidirectional_transaction") then
      test_bidir_transaction(8);

    elsif run("many_multi_byte_bidirectional_transaction") then
      for i in 0 to 100 - 1 loop
        num_bytes := rnd.RandInt(2, 64);
        test_bidir_transaction(num_bytes);
      end loop;
    end if;

    -- wait_until_idle(net, spi_slave);
    wait for 500 ns;
    test_runner_cleanup(runner);
  end process;

  rx_check_proc : process
    variable got, expected : std_logic_vector(spi_num_bits - 1 downto 0);
    constant key : key_t := get_entry_key(test_runner_cleanup);
  begin
    if is_empty(rx_check_queue) then
      unlock(runner, key);
      wait until is_active(rx_check_new_data);
    end if;
    lock(runner, key);

    expected := pop(rx_check_queue);
    pop_stream(net, spi_stream_slave, got);
    check_equal(got, expected);
  end process;

  tx_check_proc : process
    variable got, expected : std_logic_vector(spi_num_bits - 1 downto 0);
    constant key : key_t := get_entry_key(test_runner_cleanup);
  begin
    if is_empty(tx_check_queue) then
      unlock(runner, key);
      wait until is_active(tx_check_new_data);
    end if;
    lock(runner, key);

    for idx in got'range loop
      wait until rising_edge(sclk);
      got(idx) := miso;
    end loop;

    expected := pop(tx_check_queue);
    check_equal(got, expected);
  end process;


  test_runner_watchdog(runner, 10 ms);

  dut : entity work.spi_slave
   generic map(
      slave => spi_slave
  )
   port map(
      sclk => sclk,
      mosi => mosi,
      miso => miso,
      cs => cs
  );
end architecture;