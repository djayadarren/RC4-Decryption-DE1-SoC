module key_generator
(
    input  logic        clk,
    input  logic        reset,            // active-high synchronous reset
    input  logic        start_key,        // one-cycle pulse per decryption run
    input  logic        found_key,        // high when the current trial is correct
    output logic        done_key,         // stays high once the correct key is found
    output logic [21:0] key_out           // 22-bit key candidate counter
);

    // State encoding
    localparam IDLE         = 2'd0,
               INCREMENT    = 2'd1,
               DONE         = 2'd2;

    logic [1:0] state;
    logic not_found;
    logic first_run = 1'b1;

    // done_key goes high when we enter DONE
    assign done_key = (state == DONE);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state   <= IDLE;
            key_out <= 22'h0;
        end
        else begin
            case (state)
                //----------------------------------------
                // Wait for a one-cycle start_key pulse
                IDLE: begin
                    if (found_key) state <= DONE;
                    else if (start_key) begin
                        if (key_out == 22'b1111111111111111111111) begin
                            state <= IDLE;
                            not_found <= 1'b1;
                        end
                        else
                            state <= INCREMENT;
                    end
                end

                //----------------------------------------
                // Bump the 22-bit counter
                INCREMENT: begin
                    if (first_run) begin
                        key_out <= 22'd0;
                        first_run <= 1'b0;
                    end else begin
                        key_out <= key_out + 22'd1;
                    end
                    state   <= DONE;
                end

                //----------------------------------------
                // Stop here forever once we hit the right key
                DONE: begin
                    state <= IDLE;
                end

                default: begin
                    key_out <= 22'd0;
                    state <= IDLE;
                    not_found <= 1'b0;
                end
            endcase
        end
    end

endmodule