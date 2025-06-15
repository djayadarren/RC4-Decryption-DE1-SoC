`timescale 1ns / 1ps

module tb_init_mem;

    // DUT I/O signals
    logic clk;
    logic reset;
    logic [7:0] ram_address;
    logic [7:0] ram_data;
    logic       ram_wren;
    logic       done_initializing;

    // Instantiate DUT
    init_mem dut (
        .clk(clk),
        .reset(reset),
        .ram_address(ram_address),
        .ram_data(ram_data),
        .ram_wren(ram_wren),
        .done_initializing(done_initializing)
    );

    // Clock generation: 50 MHz
    always #10 clk = ~clk;

    // Test sequence
    initial begin
        // Initial values
        clk = 0;
        reset = 1;
        ram_address = 8'd0;
        ram_data = 8'd0;
        ram_wren = 0;
        done_initializing = 0;

        // Hold reset for a few cycles
        #50;
        reset = 0;

        // Let the FSM run
        #6000;

        // Finish simulation
        $display("Final Address: %0d, Final Data: %0d, WREN: %b, Done: %b",
                 ram_address, ram_data, ram_wren, done_initializing);
        $finish;
    end

    // Optional: monitor output for debugging
    initial begin
        $monitor("Time: %0t | Addr: %0d | Data: %0d | WREN: %b | Done: %b",
                  $time, ram_address, ram_data, ram_wren, done_initializing);
    end

endmodule
