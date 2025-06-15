module controller
(
    input logic         clk,
    input logic         reset,
    input logic         done_initializing,
    input logic         done_scrambling,
    input logic         done_decrypting,
    input logic         done_key,
    input logic         done_fail,
    input logic [7:0]   ram_data_init,
    input logic [7:0]   ram_data_scramble,
    input logic [7:0]   ram_data_decrypt,
    input logic [7:0]   decrypted_byte,
    input logic [7:0]   ram_address_init,
    input logic [7:0]   ram_address_scramble,
    input logic [7:0]   ram_address_decrypt,
    input logic         ram_wren_init,
    input logic         ram_wren_scramble,
    input logic         ram_wren_decrypt,
    output logic [7:0]  ram_address,
    output logic [7:0]  ram_data,
    output logic        ram_wren,
    output logic        start_init,
    output logic        start_scramble,
    output logic        start_decrypt,
    output logic        start_key
);
    logic [9:0] state;
    logic [1:0] select_output;

    // select_output: 
    // 00 -> init       (task 1)
    // 01 -> scramble   (task 2a)
    // 10 -> scramble   (task 2b)

    // Encodings: state_id[3:0], start_key, start_init, start_scramble, start_decrypt, select_output[1:0]
    parameter check_start_init          = 10'b0000_000000;
    parameter give_start_init           = 10'b0001_010000; 
    parameter wait_init                 = 10'b0010_000000;
    parameter init_done                 = 10'b0011_000000;
    parameter check_start_scramble      = 10'b0100_000001;
    parameter give_start_scramble       = 10'b0101_001001;
    parameter wait_scramble             = 10'b0110_000001;
    parameter scramble_done             = 10'b0111_000001;
    parameter check_start_decrypt       = 10'b1000_000010;
    parameter give_start_decrypt        = 10'b1001_000110;
    parameter wait_decrypt              = 10'b1010_000010;
    parameter decrypt_done              = 10'b1011_000010;
    parameter give_start_key_generator  = 10'b1100_100000;
    parameter wait_key_generator        = 10'b1101_000000;
    parameter done_key_generator        = 10'b1110_000000;

    parameter idle                      = 10'b1111_00000;

    always_ff@(posedge clk or posedge reset) begin
        if (reset) state <= give_start_key_generator;
        else begin
            case(state)
                // Initializing
                check_start_init: state <= give_start_init;
                give_start_init: state <= wait_init;
                wait_init: 
                    if (done_initializing) state <= init_done;
                    else state <= wait_init;
                init_done: state <= check_start_scramble;

                // Find secret key
                give_start_key_generator: state <= wait_key_generator;
                wait_key_generator:
                    if (done_key) state <= done_key_generator;
                    else state <= wait_key_generator;
                done_key_generator: state <= check_start_init;
                
                // Scrambling 
                check_start_scramble: state <= give_start_scramble;
                give_start_scramble: state <= wait_scramble;
                wait_scramble: 
                    if (done_scrambling) state <= scramble_done;
                    else state <= wait_scramble;
                scramble_done: state <= check_start_decrypt;

                // Decrypting
                check_start_decrypt: state <= give_start_decrypt;
                give_start_decrypt: state <= wait_decrypt;
                wait_decrypt: 
                    if (done_decrypting) state <= decrypt_done;
                    else if (done_fail) state <= give_start_key_generator;
                    else state <= wait_decrypt;
                decrypt_done: state <= idle;                

                // Idle (Infinite loop unless reset goes HIGH)
                idle: state <= idle;
                default: state <= give_start_key_generator;
            endcase
        end
    end

    always_comb begin
    case (select_output)
        2'b00: begin
        ram_data    = ram_data_init;
        ram_address = ram_address_init;
        ram_wren    = ram_wren_init;
        end
        2'b01: begin
        ram_data    = ram_data_scramble;
        ram_address = ram_address_scramble;
        ram_wren    = ram_wren_scramble;
        end
        2'b10: begin
        ram_data    = ram_data_decrypt;
        ram_address = ram_address_decrypt;
        ram_wren    = ram_wren_decrypt;
        end
        default: begin
        ram_data    = 8'd0;
        ram_address = 8'd0;
        ram_wren    = 1'b0;
        end
    endcase
    end
    
    assign start_key = state[5];
    assign start_init = state[4];
    assign start_scramble = state[3];
    assign start_decrypt = state [2];
    assign select_output = state[1:0];

endmodule