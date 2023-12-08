library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx is
  port (    clk         : in    std_logic;
            rst         : in    std_logic;
            fifo_empty  : in    std_logic;
            fifo_dout   : in    std_logic_vector(7 downto 0);
            fifo_rd_en  : out   std_logic;
            txd_tx      : out   std_logic);
end uart_tx;

architecture uart_tx_arch of uart_tx is

component uart_baud is
  generic(  baud_rate   : real:=115200.0;
            clock_rate  : real:=100.0e6);
  port (    clk     : in    std_logic;
            rst     : in    std_logic;
            baud_en : out   std_logic);
end component uart_baud;

component uart_tx_ctl is
  port (    clk         : in    std_logic;                      -- clock signal
            rst         : in    std_logic;                      -- active high reset
            baud_en     : in    std_logic;                      -- 16x bit oversampling rate
            fifo_empty  : in    std_logic;                      -- empty signal from fifo
            fifo_dout   : in    std_logic_vector(7 downto 0);   -- data from fifo
            fifo_rd_en  : out   std_logic;                      -- pop signal to fifo
            txd_tx      : out   std_logic);                     -- transmit serial signal
end component uart_tx_ctl;

signal reg_baud_en          : std_logic;
signal reg_fifo_rd_en       : std_logic;
signal reg_txd_tx           : std_logic;
begin

uart_baud_inst: component uart_baud
    generic map(    baud_rate   => 115200.0,
                    clock_rate  => 100.0e6)
    port map(       clk     => clk,
                    rst     => rst,
                    baud_en => reg_baud_en);

uart_tx_ctl_inst: component uart_tx_ctl
    port map(       clk         =>  clk,
                    rst         =>  rst,
                    baud_en     =>  reg_baud_en,
                    fifo_empty  =>  fifo_empty,
                    fifo_dout   =>  fifo_dout,
                    fifo_rd_en  =>  reg_fifo_rd_en,
                    txd_tx      =>  reg_txd_tx);  
                    
                              
fifo_rd_en  <=  reg_fifo_rd_en;
txd_tx      <=  reg_txd_tx;

end uart_tx_arch;
