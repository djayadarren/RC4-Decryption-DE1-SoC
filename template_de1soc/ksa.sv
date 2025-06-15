module ksa (
    input  logic         CLOCK_50,        // 50 MHz clock input
    input  logic [3:0]   KEY,             // Push button switches
    input  logic [9:0]   SW,              // Slider switches
    output logic [9:0]   LEDR,            // Red LEDs
    output logic [6:0]   HEX0,
    output logic [6:0]   HEX1,
    output logic [6:0]   HEX2,
    output logic [6:0]   HEX3,
    output logic [6:0]   HEX4,
    output logic [6:0]   HEX5
);

    // Internal signals
    logic clk;
    logic reset;

    assign clk   = CLOCK_50;
    assign reset = ~KEY[3]; // Active-high reset

    SevenSegmentDisplayDecoder sevenseg0 (.ssOut(HEX0), .nIn(secret_key[3:0]));
    SevenSegmentDisplayDecoder sevenseg1 (.ssOut(HEX1), .nIn(secret_key[7:4]));
    SevenSegmentDisplayDecoder sevenseg2 (.ssOut(HEX2), .nIn(secret_key[11:8]));
    SevenSegmentDisplayDecoder sevenseg3 (.ssOut(HEX3), .nIn(secret_key[15:12]));
    SevenSegmentDisplayDecoder sevenseg4 (.ssOut(HEX4), .nIn(secret_key[19:16]));
    SevenSegmentDisplayDecoder sevenseg5 (.ssOut(HEX5), .nIn({2'b0, secret_key[21:20]}));

    //----------------------------------------------------------------//

    // s_memory RAM signals (WORKING)
    logic [7:0] ram_address;
    logic [7:0] ram_data;
    logic       ram_wren;
    logic [7:0] ram_q;
    // Instantiate RAM
    s_memory s_memory_inst (
        .clock(clk),
        .address(ram_address),
        .data(ram_data),
        .wren(ram_wren),
        .q(ram_q)
    );

    //----------------------------------------------------------------//  

    // Task 1: Inititialize s_memory (WORKING)
    logic [7:0] ram_data_init;
    logic [7:0] ram_address_init;
    logic       ram_wren_init;

    init_mem init_mem_inst (
        .clk(clk),
        .reset(reset),
        .start_init(start_init),
        .ram_address(ram_address_init),
        .ram_data(ram_data_init),
        .ram_wren(ram_wren_init),
        .done_initializing(done_initializing)
    ); 

    //----------------------------------------------------------------//

    logic [21:0] secret_key;
    logic found_key;
    logic done_key;
    logic not_found;

    key_generator key_generator_inst (
        .clk(clk),
        .reset(reset),
        .start_key(start_key),
        .found_key(found_key),
        .done_key(done_key),
        .key_out(secret_key)
    );
    
    // Scrambler output signals
    logic [7:0] ram_data_scramble;
    logic [7:0] ram_address_scramble;
    logic       ram_wren_scramble;
    // Task 2a: Scramble (WORKING)
    scrambler scrambler_inst (
        .clk(clk),
        .reset(reset),
        .start_scramble(start_scramble),
        .ram_q(ram_q),
        .secret_key({2'b0, secret_key}),
        .ram_data(ram_data_scramble),
        .ram_address(ram_address_scramble),
        .ram_wren(ram_wren_scramble),
        .done_scrambling(done_scrambling)
    );

    //----------------------------------------------------------------//

    // message_rom ROM signals
    logic [7:0] rom_address;
    logic [7:0] encrypted_byte;
    //Instantiate ROM for encrypted message
    message_rom message_rom_inst (
        .address(msg_addr),
        .clock(clk),
        .q(encrypted_byte)
    );

    //----------------------------------------------------------------//

    // s_memory ports
    logic [7:0] ram_data_decrypt;
    logic [7:0] ram_address_decrypt;
    logic       ram_wren_decrypt;
    // d_ram ports
    logic [7:0] decrypted_byte;
    logic [7:0] msg_addr;
    logic       decrypt_wren;
    // Task 2b: Decrypt
    decrypter #(
        .MSG_LEN(32)
    ) decrypter_inst (
        .clk             (clk),
        .reset           (reset),
        .start_decrypt   (start_decrypt),

        .encrypted_byte  (encrypted_byte),              // message ROM port

        .ram_q           (ram_q),                       // s_memory RAM port
        .ram_address     (ram_address_decrypt),         // s_memory RAM port
        .ram_data        (ram_data_decrypt),            // s_memory RAM port
        .ram_wren        (ram_wren_decrypt),            // s_memory RAM port

        .msg_addr        (msg_addr),                    // d_memory RAM port
        .decrypted_byte  (decrypted_byte),              // d_memory RAM port
        .decrypt_wren    (decrypt_wren),                // d_memory RAM port

        .found_key       (found_key),                   // output to indicate we have the correct key
        .done_fail       (done_fail),
        .done_decrypting (done_decrypting)
    );

    //----------------------------------------------------------------//

    // Instantiate RAM for decrypted message
    decrypted_ram decrypted_ram_inst (
        .clock(clk),
        .address(msg_addr),
        .data(decrypted_byte),
        .wren(decrypt_wren),
        .q() // unused
    );

    //----------------------------------------------------------------//
    
    // Control signals
    logic       done_initializing, done_scrambling, done_decrypting, done_fail;
    logic       start_init, start_scramble, start_decrypt;
    // Controller to manage flow.
    controller controller_inst (
        .clk(clk),
        .reset(reset),
        .done_initializing(done_initializing),
        .done_scrambling(done_scrambling),
        .done_decrypting(done_decrypting),
        .done_fail(done_fail),
        .done_key(done_key),
        .ram_data_init(ram_data_init),
        .ram_address_init(ram_address_init),
        .ram_wren_init(ram_wren_init),
        .ram_data_scramble(ram_data_scramble),
        .ram_address_scramble(ram_address_scramble),
        .ram_wren_scramble(ram_wren_scramble),
        .ram_data_decrypt(ram_data_decrypt),
        .ram_address_decrypt(ram_address_decrypt),
        .ram_wren_decrypt(ram_wren_decrypt),
        .ram_address(ram_address),
        .ram_data(ram_data),
        .ram_wren(ram_wren),
        .start_init(start_init),
        .start_scramble(start_scramble),
        .start_decrypt(start_decrypt),
        .start_key(start_key)
    );

    //----------------------------------------------------------------//

    assign LEDR[0] = done_key;

endmodule
