# UART Master-Slave Communication in Verilog

##  Overview

This Verilog design implements a full-duplex UART Master that supports both serial transmission (TX) and reception (RX) using two independent finite state machines (FSMs). It conforms to standard UART framing: 1 start bit (logic low), 8 data bits (LSB first), and 1 stop bit (logic high). The module utilizes a parameterizable baud rate defined by `CLKS_PER_BIT` and operates at a system clock frequency of 100 MHz, as configured in the testbench.

---

##  Key Features

- **Transmitter and Receiver FSMs**: Two separate FSMs manage the sending and receiving of UART data frames.

- **Configurable Baud Rate**: Bit timing is based on the `CLKS_PER_BIT` parameter, allowing compatibility with different baud rates depending on the system clock.

- **FSM Control Logic**:
  - TX FSM transitions through `IDLE → START_BIT → DATA_BITS → STOP_BIT`.
  - RX FSM transitions through `IDLE → RX_START_BIT → RX_DATA_BITS → RX_STOP_BIT → CLEANUP`.

- **Mid-Bit Sampling**: The receiver samples each bit at the middle of its period to ensure data stability.

- **Handshaking Signals**:
  - `o_TX_Done` pulses high when a byte transmission completes.
  - `o_RX_DV` pulses high when a byte is successfully received.

---

##  Signal Behavior

This module uses a 100 MHz system clock (`i_Clock`) to manage all timing. To initiate a transmission, the `i_TX_DV` signal is set high with the byte on `i_TX_Byte`. The serialized output appears on `o_TX_Serial`, and `o_TX_Done` indicates when transmission is finished.

The input line `i_RX_Serial` is continuously monitored. When a start bit is detected, the receiver samples each bit in the middle of its expected time window. Once a valid byte is received, it is placed on `o_RX_Byte` and `o_RX_DV` is raised for one clock cycle. The `CLKS_PER_BIT` parameter defines the number of clock cycles per UART bit (e.g., 868 for 115200 baud at 100 MHz).

---

##  Working

The transmitter FSM waits for a valid request, sends a start bit (`0`), shifts out the 8 bits of the data byte from LSB to MSB, and ends with a stop bit (`1`). Each bit is held on the serial line for `CLKS_PER_BIT` clock cycles.

The receiver FSM looks for a falling edge indicating a start bit, waits `CLKS_PER_BIT / 2` to align mid-bit, and then samples each data bit and the stop bit sequentially. When all bits are received correctly, the byte is presented on the output along with a data-valid pulse.

---

##  Testbench

The testbench simulates UART operation using a 100 MHz clock (10 ns period). It initiates a transmission of the byte `0x3F`, observes the output on the `o_TX_Serial` line, and checks the internal signal behavior over a sufficient simulation window.

A waveform file `dump.vcd` is generated, which can be visualized in **GTKWave** to inspect signal transitions, FSM activity, and protocol correctness.

---

##  Usage

This UART module is ideal for **FPGA or ASIC designs** that require UART-based serial communication. It can be used for interfacing with terminals, MCUs, sensors, or other digital systems.

With FSM-based modularity, clock configurability, and standard protocol framing, the design is **portable**, **scalable**, and **robust** across a variety of embedded applications.
