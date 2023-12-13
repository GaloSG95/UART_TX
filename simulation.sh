#!/bin/bash

#create work library
vlib work
#compiling TB and Design files
vcom TB.vhdl src/uart_tx.vhd src/uart_baud.vhd src/uart_tx_ctl.vhd
#run optimization
vopt TB +acc=rn -o tb_opt
#run simulation
#vsim -do TB_DO.do tb_opt
vsim -c -do "run -all; exit" tb_opt
