
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

  constant trx_axi_stream_master  : axi_stream_master_t := new_axi_stream_master(16);
  constant data_axi_stream_master : axi_stream_master_t := new_axi_stream_master(spi_num_bits);
  constant data_axi_stream_slave  : axi_stream_slave_t  := new_axi_stream_slave(spi_num_bits);

  constant clk_period : time := 10 ns;

  signal clk  : std_logic := '0';
  signal busy : std_logic;

  signal trx_ready  : std_logic;
  signal trx_length : std_logic_vector(16 - 1 downto 0);
  signal trx_valid  : std_logic;

  signal data_in       : std_logic_vector(spi_num_bits - 1 downto 0);
  signal data_in_valid : std_logic;
  signal data_in_ready : std_logic;

  signal data_out       : std_logic_vector(spi_num_bits - 1 downto 0);
  signal data_out_ready : std_logic;
  signal data_out_valid : std_logic;

  signal sclk : std_logic;
  signal mosi : std_logic;
  signal miso : std_logic;
  signal cs   : std_logic;

  shared variable rnd : RandomPType;

begin

  clk <= not clk after clk_period / 2;

  main : process
    variable future         : msg_t;
    variable channel_closed : boolean;

    procedure new_spi_transaction(length : positive) is
    begin
      push_axi_stream(net, trx_axi_stream_master, std_logic_vector(to_unsigned(length, spi_num_bits)));
    end procedure;

    procedure test_spi_single_byte is
      variable spi_slave_rx, spi_slave_tx   : std_logic_vector(spi_num_bits - 1 downto 0);
      variable spi_master_tx, spi_master_rx : std_logic_vector(spi_num_bits - 1 downto 0);
      variable axi_stream_reference         : axi_stream_reference_t;
      variable tlast                        : std_logic;
    begin
      -- Generate random indata
      spi_master_tx := rnd.RandSlv(spi_master_tx'length);
      spi_slave_tx  := rnd.RandSlv(spi_slave_tx'length);

      -- Queue SPI transaction
      new_spi_transaction(1);

      -- Send in data on axi stream channel
      push_axi_stream(net, data_axi_stream_master, spi_master_tx);
      send_spi_transaction(net, spi_slave, spi_slave_tx, future);

      -- Open data out receive channel
      pop_axi_stream(net, data_axi_stream_slave, axi_stream_reference);

      -- Wait for slave to receive data
      receive_spi_transaction(net, future, spi_slave_rx, channel_closed);

      await_pop_axi_stream_reply(net, axi_stream_reference, tdata => spi_master_rx, tlast => tlast);

      -- Check that data matched
      check_equal(spi_slave_rx, spi_master_tx, "Slave received wrong data");
      check_equal(spi_master_rx, spi_slave_tx, "Master received wrong data");
      check_true(channel_closed, "SPI channel was not closed");
    end procedure;

  begin
    rnd.InitSeed(rnd'instance_name);

    test_runner_setup(runner, runner_cfg);

    wait until rising_edge(clk);

    if run("single_byte_test") then
      test_spi_single_byte;

      -- Ensure that all queued transactions has been consumed
      wait until busy = '0' and rising_edge(clk);
      wait_until_idle(net, spi_slave);

    elsif run("test_many_single_byte") then

      for i in 0 to 100 - 1 loop
        test_spi_single_byte;
      end loop;

      -- Ensure that all queued transactions has been consumed
      wait until busy = '0' and rising_edge(clk);
    end if;

    wait_until_idle(net, spi_slave);
    wait_until_idle(net, as_sync(trx_axi_stream_master));
    wait_until_idle(net, as_sync(data_axi_stream_master));
    wait_until_idle(net, as_sync(data_axi_stream_slave));

    test_runner_cleanup(runner);
  end process;

  test_runner_watchdog(runner, 100 us);

  trx_axi_stream_master_inst : entity vunit_lib.axi_stream_master
    generic map(
      master => trx_axi_stream_master
    )
    port map(
      aclk   => clk,
      tvalid => trx_valid,
      tready => trx_ready,
      tdata  => trx_length
    );

  data_out_axi_stream_master_inst : entity vunit_lib.axi_stream_master
    generic map(
      master => data_axi_stream_master
    )
    port map(
      aclk   => clk,
      tvalid => data_in_valid,
      tready => data_in_ready,
      tdata  => data_in
    );

  data_out_axi_stream_slave_inst : entity vunit_lib.axi_stream_slave
    generic map(
      slave => data_axi_stream_slave
    )
    port map(
      aclk   => clk,
      tvalid => data_out_valid,
      tready => data_out_ready,
      tdata  => data_out
    );

  spi_slave_inst : entity verification_components.spi_slave
    generic map(
      slave => spi_slave
    )
    port map(
      sclk => sclk,
      mosi => mosi,
      miso => miso,
      cs   => cs
    );

  spi_master : entity work.spi_master
    port map(
      clk             => clk,
      busy            => busy,
      trx_in_valid    => trx_valid,
      trx_in_ready    => trx_ready,
      trx_num_bytes   => to_integer(unsigned(trx_length)),
      data_in_valid   => data_in_valid,
      data_in_ready   => data_in_ready,
      data_in         => data_in,
      data_out_valid  => data_out_valid,
      data_out_tready => data_out_ready,
      data_out        => data_out,
      spi_sclk        => sclk,
      spi_mosi        => mosi,
      spi_miso        => miso,
      spi_cs          => cs
    );

end architecture;
