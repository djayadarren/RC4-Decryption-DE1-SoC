module scrambler
(
    input  logic        clk,
    input  logic        reset,
    input  logic        start_scramble,
    input  logic [23:0] secret_key,
    input  logic [7:0]  ram_q,
    output logic [7:0]  ram_data,
    output logic [7:0]  ram_address,
    output logic        ram_wren,
    output logic        done_scrambling
);

    // Internal registers
    logic [7:0] i, j;
    logic [7:0] temp_i, temp_j;
    logic [7:0] secret_key_data;
    logic [3:0] state;

    // FSM state encoding
    localparam IDLE         = 4'd0,
               SET_ADDR_I   = 4'd1,
               WAIT_ADDR_I  = 4'd2,
               WAIT_I       = 4'd3,
               CALC_J       = 4'd4,
               SET_ADDR_J   = 4'd5,
               WAIT_ADDR_J  = 4'd6,
               WAIT_J       = 4'd7,
               WRITE1       = 4'd8,
               WRITE2       = 4'd9,
               INCREMENT    = 4'd10,
               DONE         = 4'd11;

    // Drive done flag when in DONE state
    assign done_scrambling = (state == DONE);

    // Select the proper byte of secret_key based on i mod 3
    always_comb begin
        case (i % 3)
            2'd0: secret_key_data = secret_key[23:16];
            2'd1: secret_key_data = secret_key[15:8];
            default: secret_key_data = secret_key[7:0];
        endcase
    end

    // Main FSM
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // reset everything
            state       <= IDLE;
            i           <= 8'd0;
            j           <= 8'd0;
            ram_address <= 8'd0;
            ram_data    <= 8'd0;
            ram_wren    <= 1'b0;
        end else begin
            // default: no write
            ram_wren <= 1'b0;

            case (state)
                // wait for start_scramble
                IDLE: begin
                    if (start_scramble) begin
                        i     <= 8'd0;
                        j     <= 8'd0;
                        state <= SET_ADDR_I;
                    end
                end

                // read S[i]
                SET_ADDR_I: begin
                    ram_address <= i;
                    state       <= WAIT_ADDR_I;
                end

                // allow ram_address to settle
                WAIT_ADDR_I: begin
                    state       <= WAIT_I;
                end

                // Now the new ram_q is valid
                WAIT_I: begin
                    temp_i <= ram_q;
                    state  <= CALC_J;
                end

                // compute j
                CALC_J: begin
                    j      <= j + temp_i + secret_key_data;
                    state  <= SET_ADDR_J;
                end

                // read S[j]
                SET_ADDR_J: begin
                    ram_address <= j;
                    state       <= WAIT_ADDR_J;
                end

                // for address latency
                WAIT_ADDR_J: begin
                    state       <= WAIT_J;
                end

                WAIT_J: begin
                    temp_j <= ram_q;
                    state  <= WRITE1;
                end

                // swap - write temp_i to S[j]
                WRITE1: begin
                    ram_wren    <= 1'b1;
                    ram_data    <= temp_i;
                    // ram_address remains j
                    state       <= WRITE2;
                end

                // swap - write temp_j to S[i]
                WRITE2: begin
                    ram_address <= i;
                    ram_wren    <= 1'b1;
                    ram_data    <= temp_j;
                    state       <= INCREMENT;
                end

                // increment or finish
                INCREMENT: begin
                    if (i == 8'd255)
                        state <= DONE;
                    else begin
                        i     <= i + 1;
                        state <= SET_ADDR_I;
                    end
                end

                // done - hold until start_scramble deasserts
                DONE: begin
                    state <= (start_scramble ? DONE : IDLE);
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule