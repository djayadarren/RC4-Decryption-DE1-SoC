`timescale 1ns / 1ps

module tb_controller;

    // Inputs
    logic clk;
    logic reset;
    logic done_initializing;
    logic done_scrambling;
    logic [7:0] ram_data_init;
    logic [7:0] ram_data_scramble;
    logic [7:0] ram_address_init;
    logic [7:0] ram_address_scramble;
    logic ram_wren_init;
    logic ram_wren_scramble;

    // Outputs
    wire [7:0] ram_address;
    wire [7:0] ram_data;
    wire ram_wren;
    wire start_init;
    wire start_scramble;

    // Instantiate the controller
    controller dut (
        .clk(clk),
        .reset(reset),
        .done_initializing(done_initializing),
        .done_scrambling(done_scrambling),
        .ram_data_init(ram_data_init),
        .ram_data_scramble(ram_data_scramble),
        .ram_address_init(ram_address_init),
        .ram_address_scramble(ram_address_scramble),
        .ram_wren_init(ram_wren_init),
        .ram_wren_scramble(ram_wren_scramble),
        .ram_address(ram_address),
        .ram_data(ram_data),
        .ram_wren(ram_wren),
        .start_init(start_init),
        .start_scramble(start_scramble)
    );

    // Clock generation: toggle every 5ns (100 MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        done_initializing = 0;
        done_scrambling = 0;
        ram_data_init = 8'hAA;
        ram_address_init = 8'h01;
        ram_wren_init = 1'b1;
        ram_data_scramble = 8'h55;
        ram_address_scramble = 8'h02;
        ram_wren_scramble = 1'b1;

        // Reset pulse
        #10 reset = 0;

        // Wait for FSM to reach wait_init and simulate completion
        #50 done_initializing = 1;
        #20 done_initializing = 0;

        // Wait for FSM to reach wait_scramble and simulate completion
        #50 done_scrambling = 1;
        #20 done_scrambling = 0;

        // Observe outputs through one complete FSM cycle
        #100;

        $stop;
    end

endmodule
