`timescale 1ns / 1ps

module tb_scramble;

    // Inputs
    logic clk;
    logic reset;
    logic start_scramble;
    logic [23:0] secret_key;
    logic [7:0] ram_q;

    // Outputs
    wire [7:0] ram_address;
    wire [7:0] ram_data;
    wire ram_wren;
    wire done_scrambling;

    // Instantiate the scramble module
    scramble dut (
        .clk(clk),
        .reset(reset),
        .start_scramble(start_scramble),
        .secret_key(secret_key),
        .ram_q(ram_q),
        .ram_address(ram_address),
        .ram_data(ram_data),
        .ram_wren(ram_wren),
        .done_scrambling(done_scrambling)
    );

    // Clock generation: 100 MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        start_scramble = 0;
        secret_key = 24'h123456;
        ram_q = 8'h00;

        // Apply reset
        #10 reset = 0;

        // Trigger scrambling
        #10 start_scramble = 1;
        #10 start_scramble = 0;

        // Simulate memory contents with dummy data
        repeat (300) begin
            #10;
            ram_q = ram_q + 1;
        end

        // Finish simulation
        $stop;
    end

endmodule
