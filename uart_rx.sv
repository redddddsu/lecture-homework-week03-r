`include "clock_mul.sv"

module uart_rx (
    input clk,
    input rx,
    output reg rx_ready,
    output reg [7:0] rx_data
);

parameter SRC_FREQ = 76800;
parameter BAUDRATE = 9600;

// state: State of the state machine
localparam DATA_BITS = 8;
localparam 
    INIT = 0, 
    IDLE = 1,
    RX_DATA = 2,
    STOP = 3;

// CLOCK MULTIPLIER: Instantiate the clock multiplier

logic uart_clk;

clock_mul #(
    .SRC_FREQ(SRC_FREQ), 
    .OUT_FREQ(BAUDRATE)
) u_clock_mul(
    .src_clk(clk),
    .out_clk(uart_clk)
);

// CROSS CLOCK DOMAIN: The rx_ready flag should only be set 1 one for one source 
// clock cycle. Use the cross clock domain technique discussed in class to handle this.

logic r1, r2, r3;
logic [7:0] bit_count = 0;

always @ (posedge clk) begin
    r1 <= uart_clk;
    r2 <= r1;
    r3 <= r2;

    if (r3 == 1'b0 && r2 == 1'b1 && rx_ready == 1'b0 && bit_count == 8) begin
        rx_ready <= 1'b1;
        bit_count <= 0;
    end else begin
        rx_ready <= 1'b0;
    end
        

end

// STATE MACHINE: Use the UART clock to drive that state machine that receves a byte from the rx signal

logic [1:0] state = INIT;
always @ (posedge uart_clk) begin
    case (state)
        INIT: begin
            state <= IDLE;
        end

        IDLE: begin
            rx_ready <= 1'b0;
            rx_data <= 0;
            if (rx == 1'b0) begin
                state <= RX_DATA;
                
            end
        end

        RX_DATA: begin
            rx_data <= {rx, rx_data[7:1]};
            bit_count <= bit_count + 1;

            if (bit_count == 7)
                state <= STOP;
        end
        STOP: begin
            state <= IDLE;
        end
    endcase 
end
endmodule