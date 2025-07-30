`timescale 1ns / 1ps

module testbench;

  // Inputs to DUT
  reg clk = 0;
  reg reset = 1;
  reg t_start = 0;
  reg [7:0] t_data = 8'h00;
  wire tx;
  wire rx;

  // DUT instantiation
  uart_master uut (
    .processor_clk(clk),
    .reset(reset),
    .t_start(t_start),
    .t_data(t_data),
    .tx(tx),
    .rx(tx) // loopback for test
  );

  // Clock generation: 50 MHz => 20 ns period
  always #10 clk = ~clk;

  initial begin
    // Wait for reset
    #100;
    reset = 0;

    // Send a byte (e.g., 0xA5)
    t_data = 8'h99;
    t_start = 1;
    #20;
    

    // Wait until r_ready is high (i.e., byte received)
    wait (uut.r_ready == 1);
    #20; // settle time

    $display("UART Receiver: Received Byte = %h", uut.r_data);

    $finish;
  end

endmodule
