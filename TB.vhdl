library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity tb is
end entity tb;

architecture tb_arch of tb is

-- component declaration
component uart_tx is
  port (    clk         : in    std_logic;
            rst         : in    std_logic;
            fifo_empty  : in    std_logic;
            fifo_dout   : in    std_logic_vector(7 downto 0);
            fifo_rd_en  : out   std_logic;
            txd_tx      : out   std_logic);
end component uart_tx;

-- constant declaration
constant period				: time := 10 ns;
constant over_sample_time	: time := 8800 ns;
constant samples			: positive := 1000;
-- type definition
type byte_array is array (0 to samples-1) of std_logic_vector(7 downto 0);

-- signal declaration
signal reg_clk			: std_logic:='0';
signal reg_rst          : std_logic:='0';
signal reg_fifo_empty   : std_logic:='1';
signal reg_fifo_dout    : std_logic_vector(7 downto 0):=(others => '0');
signal reg_fifo_rd_en   : std_logic;
signal reg_txd_tx       : std_logic;
signal stimuli			: byte_array;
signal rx				: std_logic_vector(7 downto 0):=(others => '0');


-- functions
function to_std_logic (char : character) return std_logic is
	variable result : std_logic;
	begin
		case char is
		  when '0'    => result := '0';
		  when '1'    => result := '1';
		  when 'x'    => result := '0';
		  when others => assert (false) report "no valid binary character read" severity failure;
		end case;
	return result;
end to_std_logic;
-- load test vector into the byte array
function load_bytes (file_name : string) return byte_array is
	file object_file : text open read_mode is file_name;
	variable memory  : byte_array;
	variable L       : line;
	variable index   : natural := 0;
	variable char    : character;
	begin
		while not endfile(object_file) loop
		  readline(object_file, L);
		  for i in 7 downto 0 loop
			read(L, char);
			memory(index)(i) := to_std_logic(char);
		  end loop;
		  index := index + 1;
		end loop;
	return memory;
end load_bytes;
  

begin

stimuli <= load_bytes("stimuli.tv");

-- DUT instantiation
uart_tx_dut : component uart_tx
	port map(	clk        	=>	reg_clk,
				rst        	=>	reg_rst,
				fifo_empty 	=>	reg_fifo_empty,
				fifo_dout  	=>	reg_fifo_dout,
				fifo_rd_en 	=>	reg_fifo_rd_en,
				txd_tx     	=>	reg_txd_tx);

clock_gen: process
begin
	wait for period/2;
	reg_clk	<= not reg_clk;
end process clock_gen;

global_rst: process
begin
	wait for period;
	reg_rst	<= not reg_rst;
	wait for period;
	reg_rst <= not reg_rst;
	wait;
end process global_rst;

fifo_process: process
begin
	wait until falling_edge(reg_rst);
	reg_fifo_empty <= '0';
	
	for idx in 0 to samples-1 loop
	reg_fifo_dout <= stimuli(idx);
	wait until rising_edge(reg_fifo_rd_en);
	end loop;
	
	wait;
end process fifo_process;

uart_verification: process
begin
	wait until falling_edge(reg_rst);
	assert(reg_fifo_rd_en = '0') report "FIFO read enable not correctly set" severity error;
	assert(reg_txd_tx = '1') report "tx not pulled up" severity error;

	wait until falling_edge(reg_txd_tx);
	wait for over_sample_time/2; --avoid reading during transition
	-- sample loop
	for idx in 0 to samples-1 loop
	wait for over_sample_time; --start state bit
	-- bit loop
	for jdx in 0 to 7 loop
		rx(jdx) <= reg_txd_tx;
		wait for over_sample_time;
	end loop;
	--assert
	assert(rx = stimuli(idx)) report "not correctly received" severity error;
	wait for over_sample_time; --stop state bit
	end loop;
	
	report "Testbench finished" severity failure;
	wait;
end process uart_verification;
end architecture tb_arch;
