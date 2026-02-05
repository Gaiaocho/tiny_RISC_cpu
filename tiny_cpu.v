`default_nettype none
module tiny_cpu (
    //Inputs
    input CLK,
    // outputs
    output wire led_red,  // Red
    output wire led_blue,  // Blue
    output wire led_green  // Green
);

  /* Counter Register for slowing clock*/
  reg         [20:0] frequency_counter_i = 0;


  // CPU  General Purpose register
  reg         [31:0] R                                           [ 16];
  //Program Counter
  reg         [ 3:0] PC = 0;
  //ROM Memory 16 registers whose size is 32 bits
  reg         [31:0] ROM                                         [ 16];

  //RAM Memory 256 Words
  reg         [31:0] RAM                                         [128];



  /* Wires to access registers */
  reg         [31:0] IR = 0;

  wire        [ 6:0] opcode = IR[6:0];
  wire        [ 4:0] rd = IR[11:7];
  wire        [ 3:0] funct3 = IR[14:12];
  wire        [ 4:0] rs1 = IR[19:15];
  wire        [ 4:0] rs2 = IR[24:20];
  wire        [ 6:0] funct7 = IR[31:25];

  wire signed [31:0] imm_i = {{20{IR[31]}}, IR[31:20]};
  wire signed [31:0] imm_s = {{20{IR[31]}}, IR[31:25], IR[11:7]};

  /*hold computation for LED*/
  reg         [ 4:0] last_written_reg = 0;


  /*Run the FPGA oscillator*/
  always @(posedge CLK) begin
    frequency_counter_i <= frequency_counter_i + 1'b1;
  end

  wire slow_clk = frequency_counter_i[2];

  
  /* Actually run our CPU */
  always @(posedge slow_clk) begin
    IR <= ROM[PC];

    case (opcode)
      //RTYPE
      7'b0110011: begin
        case (funct3)
          3'b000: begin
            if (funct7 == 7'b0100000) R[rd] <= R[rs1] - R[rs2];  // SUB
            else R[rd] <= R[rs1] + R[rs2];  // ADD
          end
          3'b111:  R[rd] <= R[rs1] & R[rs2];  //AND
          3'b110:  R[rd] <= R[rs1] | R[rs2];  //OR
          3'b100:  R[rd] <= R[rs1] ^ R[rs2];  //XOR
          default: ;
        endcase
        last_written_reg <= rd;
      end
      //ITYPE
      7'b0010011: begin
        case (funct3)
          3'b000:  R[rd] <= R[rs1] + imm_i;  //ADDI
          3'b111:  R[rd] <= R[rs1] & imm_i;  //ANDI
          3'b110:  R[rd] <= R[rs1] | imm_i;  //ORI
          default: ;
        endcase
        last_written_reg <= rd;
      end
      //LTYPE
      7'b0000011: begin
        case (funct3)
          3'b010:  R[rd] <= RAM[R[rs1]+imm_i];  //LW
          default: ;
        endcase
      end
      //STYPE
      7'b0100011: begin
        case (funct3)
          3'b010:  RAM[R[rs1]+imm_s] <= R[rs2];  //SW
          default: ;
        endcase
      end
      default: ;
    endcase
    PC   <= PC + 1;
    /* R0 is always a 0*/
    R[0] <= 32'b0;
  end

  assign led_blue  = R[last_written_reg][2];
  assign led_green = R[last_written_reg][1];
  assign led_red   = R[last_written_reg][0];

endmodule
