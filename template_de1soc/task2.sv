module scramble
(
    input logic clk,
    input logic reset,
    input logic start_scramble,            
    input logic [23:0] secret_key,  // Secret key for scrambling
    input logic [7:0] ram_q,
    output logic [7:0] ram_address, // Address to write to RAM
    output logic [7:0] ram_data,    // Data to write to RAM
    output logic ram_wren,          // Write enable signal
    output logic done_scrambling    // Signal to indicate scrambling is done
);

    // Encodings: state_id[3:0], store_i_and_calc_j, store_j, load_i, load_j, go_to_i, go_to_j, increment_enable, done_scrambling
    parameter idle =            12'b0000_00000000;
    parameter store_data_i =    12'b0001_10000000;
    parameter get_j =           12'b0010_10000000;
    parameter i_to_j =          12'b0011_00000100;
    parameter store_data_j =    12'b0100_01000000;
    parameter load_i_to_j =     12'b0101_00010000;
    parameter j_to_i =          12'b0110_00001000;
    parameter load_j_to_i =     12'b0111_00100000;
    parameter increment_i =     12'b1000_00000010;
    parameter done =            12'b1001_00000001;
    
    logic [7:0] i = 8'b0;
    logic [7:0] j = 8'b0;
    logic [7:0] temp_i; // Temporary register to store data at s[i]
    logic [7:0] temp_j; // Temporary register to store data at s[j]
    logic [11:0] state;
    logic [7:0] key_data;
    logic store_i_and_calc_j, store_j, load_i, load_j, go_to_i, go_to_j, increment_enable;

    // State logic
    always_ff@(posedge clk or posedge reset) begin
        if (reset) state <= idle;
        else begin
            case(state)
                idle: if (start_scramble)   state <= store_data_i;  // Do nothing
                store_data_i:               state <= get_j;         // Storing s[i] into temp_i
                get_j:                      state <= i_to_j;        // Calculate j = (j + s[i] + secret_key[i mod keylength]) mod 256
                i_to_j:                     state <= store_data_j;  // Go from address i to j
                store_data_j:               state <= load_i_to_j;   // Storing s[j] into temp_j
                load_i_to_j:                state <= j_to_i;        // Load s[i] into s[j]
                j_to_i:                     state <= load_j_to_i;   // Go from address j to i
                load_j_to_i:                state <= increment_i;   // Load s[j] into s[i]
                increment_i: begin
                    if (i == 8'd255)        state <= done;          // If i = 255, the last swap has been done for s[255]
                    else                    state <= store_data_i;  // Else, continue swapping
                end

                done:                       state <= idle;
                default:                    state <= idle;
            endcase
        end
    end

    // Scrambling logic
    always_ff@(posedge clk) begin
        // Storing i in temporary register and calculating j at the same time.
        if (store_i_and_calc_j) begin
            ram_address <= i;
            ram_wren <= 1'b0;
            temp_i <= ram_q;
            j <= j + ram_q + key_data;
        end
        if (go_to_j) begin
            ram_wren <= 1'b0;
            ram_address <= j;
        end
        if (store_j) begin
            ram_wren <= 1'b0;
            temp_j <= ram_q;
        end
        // s[i] = temp_j;
        if (load_i) begin
            ram_wren <= 1'b1;
            ram_data <= temp_j;
        end
        // s[j] = temp_i
        if (load_j) begin
            ram_wren <= 1'b1;
            ram_data <= temp_i;
        end
        if (go_to_i) begin
            ram_wren <= 1'b0;
            ram_address <= i;
        end
        if (increment_enable) i <= i + 8'd1;

        if (done_scrambling) begin
            ram_wren <= 1'b0;
            i <= 8'd0;
        end
    end

    // Key byte selection (i mod 3)
    always_comb begin
        case (i % 3)
            0: key_data = secret_key[23:16];
            1: key_data = secret_key[15:8];
            2: key_data = secret_key[7:0];
            default: key_data = 8'h00;
        endcase
    end

    // Output assignments
    assign store_i_and_calc_j = state[7];
    assign store_j =            state[6];
    assign load_i =             state[5]; 
    assign load_j =             state[4];
    assign go_to_i =            state[3];
    assign go_to_j =            state[2];
    assign increment_enable =   state[1];
    assign done_scrambling =    state[0];

endmodule
