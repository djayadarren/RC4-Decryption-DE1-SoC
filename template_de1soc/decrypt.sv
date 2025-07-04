module decrypter #(
  parameter MSG_LEN = 32
)(
  input  logic        clk,
  input  logic        reset,
  input  logic        start_decrypt,
  input  logic [7:0]  encrypted_byte,

  // S-box RAM port
  input  logic [7:0]  ram_q,
  output logic [7:0]  ram_address,
  output logic [7:0]  ram_data,
  output logic        ram_wren,

  // Decrypted-message outputs
  output logic [7:0]  decrypted_byte,
  output logic [5:0]  msg_addr,         // steps through 0…MSG_LEN-1
  output logic        decrypt_wren,

  output logic        found_key,      // tells key generator to stop
  output logic        done_fail,      // tells controller to generate another key
  output logic        done_decrypting // tells controller key is found
);

  // Internal indices and registers
  logic [7:0] i, j;
  logic [7:0] temp_i, temp_j;
  logic [7:0] f_index, f_byte;
  logic [5:0] k;
  logic [4:0] state;

  // FSM states (with SET_ROM+WAIT_ROM)
  localparam IDLE         = 5'd0,
             INCR_I       = 5'd1,
             SET_ADDR_I   = 5'd2,
             WAIT_ADDR_I  = 5'd3,
             WAIT_I       = 5'd4,
             CALC_J       = 5'd5,
             SET_ADDR_J   = 5'd6,
             WAIT_ADDR_J  = 5'd7,
             WAIT_J       = 5'd8,
             WRITE1       = 5'd9,
             WRITE2       = 5'd10,
             CALC_F       = 5'd11,
             SET_ADDR_F   = 5'd12,
             WAIT_ADDR_F  = 5'd13,
             WAIT_F       = 5'd14,
             SET_ROM      = 5'd15,
             WAIT_ROM     = 5'd16,
             OUTPUT       = 5'd17,
             INCREMENT_K  = 5'd18,
             DONE         = 5'd19,
             DONE_FAIL    = 5'd20;

  // Output flag
  assign done_decrypting = (state == DONE);
  assign done_fail       = (state == DONE_FAIL);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state          <= IDLE;
      i              <= 8'd0;
      j              <= 8'd0;
      k              <= 6'd0;
      ram_address    <= 8'd0;
      ram_data       <= 8'd0;
      ram_wren       <= 1'b0;
      decrypted_byte <= 8'd0;
      decrypt_wren   <= 1'b0;
      msg_addr       <= 6'd0;
      f_byte         <= 8'd0;
    end else begin
      // default deassert writes
      ram_wren     <= 1'b0;
      decrypt_wren <= 1'b0;
      found_key    <= 1'b0;
      case (state)
        IDLE: begin
          if (start_decrypt) begin
            i     <= 8'd0;
            j     <= 8'd0;
            k     <= 6'd0;
            state <= INCR_I;
          end
        end

        INCR_I: begin
          i     <= i + 8'd1;
          state <= SET_ADDR_I;
        end

        SET_ADDR_I: begin
          ram_address <= i;
          state       <= WAIT_ADDR_I;
        end

        WAIT_ADDR_I: begin
          state <= WAIT_I;
        end

        WAIT_I: begin
          temp_i <= ram_q;
          state  <= CALC_J;
        end

        CALC_J: begin
          j     <= j + temp_i;
          state <= SET_ADDR_J;
        end

        SET_ADDR_J: begin
          ram_address <= j;
          state       <= WAIT_ADDR_J;
        end

        WAIT_ADDR_J: begin
          state <= WAIT_J;
        end

        WAIT_J: begin
          temp_j <= ram_q;
          state  <= WRITE1;
        end

        WRITE1: begin
          ram_wren <= 1'b1;
          ram_data <= temp_i;
          state    <= WRITE2;
        end

        WRITE2: begin
          ram_address <= i;
          ram_wren    <= 1'b1;
          ram_data    <= temp_j;
          state       <= CALC_F;
        end

        CALC_F: begin
          f_index <= temp_i + temp_j;
          state   <= SET_ADDR_F;
        end

        SET_ADDR_F: begin
          ram_address <= f_index;
          state       <= WAIT_ADDR_F;
        end

        WAIT_ADDR_F: begin
          state <= WAIT_F;
        end

        WAIT_F: begin
          f_byte <= ram_q;
          state  <= SET_ROM;
        end

        SET_ROM: begin
          msg_addr <= k;
          state    <= WAIT_ROM;
        end

        WAIT_ROM: begin
          state <= OUTPUT;
        end

        OUTPUT: begin
          decrypted_byte <= f_byte ^ encrypted_byte;
          decrypt_wren   <= 1'b1;
          state          <= INCREMENT_K;
        end

        INCREMENT_K: begin
          if ((decrypted_byte >= 8'd97 && decrypted_byte <= 8'd122) || (decrypted_byte == 8'd32)) begin
            if (k == MSG_LEN-1)
              state <= DONE;
            else begin
              k     <= k + 1;
              state <= INCR_I;
            end
          end
          else begin
            state <= DONE_FAIL;
            found_key <= 1'b0;
          end
        end

        DONE: begin
          state <= DONE;
          found_key <= 1'b1;
        end

        DONE_FAIL: begin
          state <= IDLE;
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
