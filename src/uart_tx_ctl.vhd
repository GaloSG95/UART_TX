library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_ctl is
  port (    clk         : in    std_logic;                      -- clock signal
            rst         : in    std_logic;                      -- active high reset
            baud_en     : in    std_logic;                      -- 16x bit oversampling rate
            fifo_empty  : in    std_logic;                      -- empty signal from fifo
            fifo_dout   : in    std_logic_vector(7 downto 0);   -- data from fifo
            fifo_rd_en  : out   std_logic;                      -- pop signal to fifo
            txd_tx      : out   std_logic);                     -- transmit serial signal
end uart_tx_ctl;

architecture uart_tx_ctl_arch of uart_tx_ctl is

type state_type is (IDLE, START, DATA, STOP);
signal state, next_state : state_type;
-- counter signals
signal over_sample_cnt  : unsigned(3 downto 0):=(others => '0');
signal bit_cnt          : unsigned(2 downto 0):=(others => '0');
-- counter flags
signal over_sample_done : std_logic:='0';
signal bit_cnt_done     : std_logic:='0';
-- output registers
signal reg_fifo_pop     : std_logic:='0';
signal reg_txd_tx       : std_logic:='1';


begin

SYNC_PROC: process (clk)
begin
  if (clk'event and clk = '1') then
     if (rst = '1') then
        state   <= IDLE;
     elsif baud_en = '1' then
        state   <= next_state;
     else
        state   <= state;
     end if;
  end if;
end process;

OUTPUT_DECODE: process (state, over_sample_done, bit_cnt_done)
begin
  if state = DATA then
    if (over_sample_done = '1' and bit_cnt_done = '1')then
        reg_fifo_pop <= '1';
    else
        reg_fifo_pop <= '0';
    end if;
  else
    reg_fifo_pop <= '0';
  end if;
end process;

fifo_rd_en  <= '1' when (reg_fifo_pop = '1' and baud_en = '1') else '0';

NEXT_STATE_DECODE: process (state, fifo_empty, over_sample_done, bit_cnt_done)
begin
  --declare default state for next_state to avoid latches
  next_state <= state;  --default is to stay in current state

  case (state) is
     when IDLE =>
        if fifo_empty = '0' then
           next_state <= START;
        end if;
     when START =>
        if (over_sample_done = '1' and bit_cnt_done = '0') then
           next_state <= DATA;
        end if;
     when DATA =>
        if (over_sample_done = '1' and bit_cnt_done = '1')then
           next_state <= STOP;
        end if;
    when STOP =>
        if over_sample_done = '1' then
           if(fifo_empty = '0') then
             next_state <= START;
           else
             next_state <= IDLE;
           end if;
        end if;
  end case;
end process;

OVER_SAMPLE: process(clk)
begin
    if clk'event and clk = '1' then
       if rst = '1' then
         over_sample_cnt <= (others => '0');
       else
         if(baud_en = '1') then
           if(over_sample_done = '0') then
             over_sample_cnt <= over_sample_cnt - 1;
           else
             if(((state = IDLE) and (fifo_empty = '0')) or
                ((state = START)) or ((state = DATA)) or
                ((state = STOP) and (fifo_empty = '0'))) then
                over_sample_cnt <= "1111";
             end if;
           end if;
         end if; -- baud assert
       end if; -- reset assert 
    end if; -- clock event
end process OVER_SAMPLE;

over_sample_done <= '1' when over_sample_cnt = "0000" else '0';

BIT_COUNT: process(clk)
begin
    if clk'event and clk = '1' then
       if rst = '1' then
         bit_cnt <= (others => '0');
       else
         if(baud_en = '1') then
           if(over_sample_done = '1') then
             if(state = START) then
               bit_cnt <= (others => '0');
             elsif(state = DATA) then
               bit_cnt <= bit_cnt + 1;
             end if;
           end if;
         end if; -- baud assert
       end if; -- reset assert 
    end if; -- clock event
end process BIT_COUNT;

bit_cnt_done    <= '1' when bit_cnt = "111" else '0';

OUTPUT_GEN: process(clk)
begin
    if clk'event and clk = '1' then
       if rst = '1' then
         reg_txd_tx <= '1';
       else
         if(baud_en = '1') then
           if(state = IDLE) or (state = STOP) then
             reg_txd_tx <= '1';
           elsif(state = START) then
             reg_txd_tx <= '0';
           else
             reg_txd_tx <= fifo_dout(to_integer(bit_cnt));
           end if;
         end if; -- baud assert
       end if; -- reset assert 
    end if; -- clock event
end process OUTPUT_GEN;

txd_tx <= reg_txd_tx;

end uart_tx_ctl_arch;
