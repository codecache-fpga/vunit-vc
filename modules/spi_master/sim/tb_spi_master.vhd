library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library verification_components;
use verification_components.spi_slave_pkg.all;

library osvvm;
use osvvm.RandomPkg.all;

entity tb_spi_master is
  generic(
    runner_cfg : string
  );
end entity;

architecture sim of tb_spi_master is

  constant spi_slave : spi_slave_t := new_spi_slave;

  constant clk_period : time := 10 ns;

  signal clk            : std_logic := '0';
  signal data_in_valid  : std_logic;
  signal data_in        : std_logic_vector(spi_num_bits - 1 downto 0);
  signal data_out_valid : std_logic;
  signal data_out       : std_logic_vector(spi_num_bits - 1 downto 0);

  signal sclk : std_logic;
  signal mosi : std_logic;
  signal miso : std_logic;
  signal cs   : std_logic;

  shared variable rnd : RandomPType;

begin

  clk <= not clk after clk_period / 2;

  main : process
    variable spi_data_rx, spi_data_tx : std_logic_vector(spi_num_bits - 1 downto 0);
    variable future                   : msg_t;
  begin
    test_runner_setup(runner, runner_cfg);

    wait until rising_edge(clk);

    if run("single_byte_test") then
      
      -- Generate random indata
      data_in     <= rnd.RandSlv(data_in'length);
      spi_data_tx := rnd.RandSlv(spi_data_tx'length);

      -- In this case for blocking transaction to work, 
      -- we have to be careful to avoid race conditions
      data_in_valid <= '1';
      spi_transaction(net, spi_slave, spi_data_tx, spi_data_rx);
      wait until rising_edge(clk);

      -- Wait for master to receive slave data
      wait until rising_edge(clk) and data_out_valid = '1';

      -- Check that data matched
      check_equal(spi_data_rx, data_in, "Slave received wrong data");
      check_equal(data_out, spi_data_tx, "Master received wrong data");
      
      -- Ensure that all queued transactions has been consumed
      wait_until_idle(net, spi_slave);
    
    elsif run("single_byte_test_future") then
      -- Use a so called "future" with a non-blocking transaction which queues up
      -- a transaction in the slave, and then reads the reply later.
      
      -- Generate random indata
      data_in     <= rnd.RandSlv(data_in'length);
      spi_data_tx := rnd.RandSlv(spi_data_tx'length);

      -- Queue SPI transaction
      send_spi_transaction(net, spi_slave, spi_data_tx, future);

      -- Start master transaction
      data_in_valid <= '1';
      wait until rising_edge(clk);
      data_in_valid <= '0';

      -- Wait for slave to receive data
      receive_spi_transaction(net, spi_data_rx, future);

      -- Wait for master to receive slave data
      wait until rising_edge(clk) and data_out_valid = '1';

      -- Check that data matched
      check_equal(spi_data_rx, data_in, "Slave received wrong data");
      check_equal(data_out, spi_data_tx, "Master received wrong data");
      
      -- Ensure that all queued transactions has been consumed
      wait_until_idle(net, spi_slave);
    end if;

    test_runner_cleanup(runner);
  end process;

  test_runner_watchdog(runner, 1 us);

  spi_slave_inst : entity verification_components.spi_slave
    generic map(
      spi_slave => spi_slave
    )
    port map(
      sclk => sclk,
      mosi => mosi,
      miso => miso,
      cs   => cs
    );

  spi_master : entity work.spi_master
    port map(
      clk            => clk,
      data_in_valid  => data_in_valid,
      data_in        => data_in,
      data_out_valid => data_out_valid,
      data_out       => data_out,
      spi_sclk       => sclk,
      spi_mosi       => mosi,
      spi_miso       => miso,
      spi_cs         => cs
    );

end architecture;
