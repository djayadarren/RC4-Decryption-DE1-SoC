module init_mem
(
    input logic clk,
    input logic reset,
    input logic start_init,
    output logic [7:0] ram_address,
    output logic [7:0] ram_data,
    output logic ram_wren,
    output logic done_initializing
);  
    // Encodings: state_id[2:0], done_initializing, increment_enable
    parameter idle = 4'b00_00;
    parameter incrementing = 4'b00_01;
    parameter done = 4'b10_10;
    
    logic [7:0] i = 8'b0;
    logic [3:0] state;
    logic increment_enable;

    // State logic
    always_ff@(posedge clk or posedge reset) begin
        if (reset) state <= idle;
        else begin
            case(state)
                idle: if (start_init)           state <= incrementing;
                incrementing: if (i == 8'd255)  state <= done;
                done:                           state <= idle;
                default:                        state <= idle;
            endcase
        end
    end

    // Increment logic
    always_ff@(posedge clk) begin
        if (increment_enable) begin                 
            ram_address <= i;
            ram_data <= i;
            ram_wren <= 1'b1; // Enable write
            i <= i + 8'd1;
        end
        else if (done_initializing) begin
            ram_wren <= 1'b0; // Disable write
            i <= 8'd0;
        end
    end

    // Output assignments
    assign done_initializing = state[1];
    assign increment_enable = state[0];

endmodule