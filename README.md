# UART_verilog
Verilog implementation of UART protocol including transmitter, receiver, and configurable FSM-based control.
This repository contains a Verilog implementation of a **UART (Universal Asynchronous Receiver Transmitter) Master** that supports both serial **transmission (TX)** and **reception (RX)** using finite state machines (FSMs). It includes a complete testbench for functional simulation and waveform analysis.

## Features

-  Full-duplex UART Master (Transmitter + Receiver)
-  Parameterized baud rate using `CLKS_PER_BIT`
-  1 start bit, 8 data bits (LSB first), 1 stop bit
-  Independent FSMs for TX and RX
-  Mid-bit sampling for robust reception
-  Configurable and reusable design for different platforms

##  Files

- `uart_master.v` – Main Verilog module with both TX and RX FSMs
- `testbench.v` – Testbench simulating transmission of a byte (`0x3F`)

##  Simulation Details

- **System Clock**: 100 MHz (10 ns period)
- **Baud Rate**: Defined via `CLKS_PER_BIT` (e.g., 868 for 115200 baud)
- **TX Byte Sent**: `0x3F`

The testbench stimulates the UART TX logic and monitors the output serial line. You can inspect the behavior using Modelsim-Altera or any compatible VCD viewer.

##  Usage

This UART design can be directly used or integrated into FPGA/ASIC projects for serial communication with:
- PCs (via USB-UART bridge)
- Microcontrollers
- Serial sensors or peripherals
