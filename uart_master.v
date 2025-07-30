`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2025 12:32:07
// Design Name: 
// Module Name: uart_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_master(

input processor_clk,
input reset,
input t_start,
input [7:0] t_data,

output tx,
input rx

);


parameter clk           = 50_000_000;
parameter baud_rate     = 9600;
parameter over_sampling = 16;


localparam tidle = 2'd0;
localparam tstart = 2'd1;
localparam tdata = 2'd2;
localparam tstop = 2'd3;
reg [1:0] t_curr_state = tidle;
reg [1:0] t_nxt_state = tidle ;

reg tx_reg = 1'b1;


assign tx = tx_reg;





// assuming processor clock = 50M
// baud rate 9600

reg U_baud_tick = 1'b0;
reg [3:0] cnt = 4'd0; // 16
reg U_fast_baud_tick = 1'b0;
reg [8:0] fast_cnt = 9'd0; // 326

// to generate baud tick at 9600 baud rate 
// also to generate oversampled baud tick at 16x oversample
always @ (posedge processor_clk) begin
    // generating 16x baud rate first, from that i will derive 1x vaud tick so as to be phase aligned
    if(fast_cnt == 9'd325) begin
        fast_cnt <= 9'd0;
        U_fast_baud_tick <= 1'b1;
    end
    else begin
        fast_cnt <= fast_cnt + 1;
        U_fast_baud_tick <= 1'b0;
    end
    
    
    if(U_fast_baud_tick == 1'b1) begin
        if(cnt == 4'd15) begin
            cnt <= 4'd0;
            U_baud_tick <= 1'b1;
        end
        else begin
            cnt <= cnt + 1;
            U_baud_tick <= 1'b0;
        end
    end
    else begin
        U_baud_tick <= 1'b0;
    end
    
end



////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////         Transmitt FSM started    /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

reg [3:0] data_cnt = 4'd0;
reg [7:0] tx_buff; // to latch the t_data sent from outside
// sequential block to set current state aas next state at baud clock(here baud pulse)
always @(posedge U_baud_tick or posedge reset) begin
    if(reset)begin
        t_curr_state <= tidle;
        data_cnt    <= 4'd0;
        tx_buff     <= 8'd0;
    end
    else begin
        t_curr_state <= t_nxt_state;
        if(t_curr_state == tstart)begin data_cnt <= 4'd0;  tx_buff <= t_data; end
        if(t_curr_state == tdata)begin data_cnt <= data_cnt + 1; end
    end
end


// combinational block to set next state value
always@(*) begin
   // if updates current state here, it will create  combinatinal logic because we are trying to use updated curr state in same always blck, hence done seperaetly
   
    case(t_curr_state)
        tidle : begin
                if(t_start == 1'b1)begin
                    t_nxt_state = tstart;
                end
                else begin
                    t_nxt_state = tidle;
                end
        end           
        tstart:begin
                t_nxt_state = tdata;
        end               
        tdata: begin
                if(data_cnt == 4'd7)begin
                    t_nxt_state = tstop;
                end
                else begin
                    t_nxt_state = tdata;
                end
        end               
        tstop:begin
                t_nxt_state = tidle;
        end
        default:begin
                t_nxt_state = tidle;
        end
    endcase
end


always@(posedge U_baud_tick)begin
    if(reset)begin
        tx_reg <= 1'b1;
    end
    else begin
        case(t_curr_state)// so that evrything is in sync
        
        tidle:begin 
            tx_reg <= 1'b1; 
        end
        tstart:begin
             tx_reg <= 1'b0;
        end
        tdata:begin
            tx_reg <= tx_buff[data_cnt];
        end
        tstop:begin
            tx_reg <= 1'b1;
        end
        default: begin 
            tx_reg <= 1'b1;    
        end 
        endcase
    end
end
////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////         Transmitt FSM ENDDDDDDD    /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////         Receiver FSM started    /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////



localparam RIDLE  = 3'd0,
           RSTART = 3'd1,
           RDATA  = 3'd2,
           RSTOP  = 3'd3,
           RDONE  = 3'd4;


reg  [2:0] r_curr_state = RIDLE;
reg  [2:0] r_nxt_state  = RIDLE;

reg  [3:0] sample_cnt   = 4'd0;   // counts 0-15 (16×)
reg  [2:0] bit_cnt      = 3'd0;   // counts 0-7  (8 data bits)

reg  [7:0] r_shift;               // shift-in register
reg  [1:0] rx_sync = 2'b11;       // 2-stage synchroniser

reg        r_ready  = 1'b0;       // 1-tick data-valid pulse
reg [7:0]  r_data   = 8'd0;       // received byte


wire       rx_falling_edge =  rx_sync[1] & ~rx_sync[0];


always @(posedge U_fast_baud_tick or posedge reset) begin
    if (reset) begin
        r_curr_state <= RIDLE;
        sample_cnt   <= 0;
        bit_cnt      <= 0;
        rx_sync      <= 2'b11;
    end else begin
        
        rx_sync[0] <= rx;
        rx_sync[1] <= rx_sync[0];

        r_curr_state <= r_nxt_state;

        /* mid-bit sample counter */
        if (r_curr_state == RIDLE) begin
            sample_cnt <= 4'd0;
        end else begin
            sample_cnt <= sample_cnt + 1;
        end

        /* data bit counter and shifter */
        if (r_curr_state == RDATA && sample_cnt == 4'd15) begin
            bit_cnt <= bit_cnt + 1;
            r_shift[bit_cnt] <= rx_sync[0];  // sample at centre
        end else if (r_curr_state == RSTART) begin
            bit_cnt <= 0;
        end
    end
end



// next state logic combinational
always @(*) begin
    case (r_curr_state)
        RIDLE : begin
            if (rx_falling_edge)              r_nxt_state = RSTART;
            else                              r_nxt_state = RIDLE;
        end

        RSTART: begin
            if (sample_cnt == 4'd7) begin
                if (rx_sync[1] == 1'b0)       r_nxt_state = RDATA;
                else                          r_nxt_state = RIDLE;  // false start, maybe because of noise
            end 
            else                          
            r_nxt_state = RSTART;
        end

        RDATA : begin
            if (sample_cnt == 4'd15) begin
                if (bit_cnt == 3'd7)          r_nxt_state = RSTOP;  // last bit hence go to stop state
                else                          r_nxt_state = RDATA;
            end 
            else                          
            r_nxt_state = RDATA;
        end

        RSTOP : begin
            if (sample_cnt == 4'd15) begin
                if (rx_sync[1] == 1'b1)       r_nxt_state = RDONE;  // good stop
                else                          r_nxt_state = RIDLE;  
            end 
            else                          
            r_nxt_state = RSTOP;
        end

        RDONE : r_nxt_state = RIDLE;          

        default: r_nxt_state = RIDLE;
    endcase
end

// output setting block
always @(posedge U_fast_baud_tick or posedge reset) begin
    if (reset) begin
        r_ready <= 1'b0;
        r_data  <= 8'd0;
    end else begin
        
        r_ready <= 1'b0;

        if (r_curr_state == RDONE) begin
            r_ready <= 1'b1;      // one-tick pulse
            r_data  <= r_shift;   // make captured byte available
        end
    end
end


////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////         Receiver FSM ENDDDDDD    /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
