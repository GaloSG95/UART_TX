# UART TX
The **UART_TX** project demonstrates the implementation of the transmission component of the UART protocol. 
It has been comprehensively developed in VHDL, and its customization is facilitated by utilizing generic parameters, which allow for adapting the baud rate and clock frequency.

This project is meant to be used with a FIFO buffer. Therefore, 
when the *fifo_empty* signal is deserted, the transmission begins until it is again asserted; 
once a byte has been transmitted, it asserts the *read_enable* signal for the FIFO to pop out the next byte to transmit.
# Functional Verification
The project includes a testbench file implemented in VHDL; it provides random stimuli from the test vector (.tv) file, 
and at the same time, it captures the transmitted output bits and checks for correctness.

A shell script is provided to check all 1000 random samples; the script compiles, optimizes, and executes simulation via vsim in command mode.
