library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;

entity uart_baud is
  generic(  baud_rate   : real:=115200.0;
            clock_rate  : real:=100.0e6);
  port (    clk     : in    std_logic;
            rst     : in    std_logic;
            baud_en : out   std_logic);
end uart_baud;

architecture uart_baud_arch of uart_baud is

constant over_sample    : integer := integer(ceil(clock_rate/(baud_rate*16.0)));

signal count            : integer range 0 to over_sample-1;
signal baud_en_reg      : std_logic:='0';
begin

uart_cnt: process(clk)
begin
  if(clk'event and clk = '1') then
    if(rst = '1') then
        count           <= 0;
        baud_en_reg     <= '0';
    else
        if count = over_sample-1 then
          count         <= 0;
          baud_en_reg   <= '1';
        else
          count         <= count + 1;
          baud_en_reg   <= '0';
        end if; --counter
    end if; --rst assert
  end if; --clk rising_edge
end process uart_cnt;

baud_en             <= baud_en_reg;
end uart_baud_arch;
