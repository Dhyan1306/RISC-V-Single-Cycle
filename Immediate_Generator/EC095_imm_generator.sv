`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2026 11:28:47
// Design Name: 
// Module Name: imm_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module imm_generator(
    input  logic [11:0] imm_input,       // decoder `imm`
    input  logic [2:0]  fn3,
    input  logic [6:0]  opcode,
    input  logic [19:0] imm_input_uj,    // decoder `imm_uj`
    output logic [31:0] imm_output
);

    always_comb begin
        case (opcode)
            // Branch: sign_extend(imm) << 1
            7'b1100011: imm_output = {{20{imm_input[11]}}, imm_input} << 1;

            // JAL: sign_extend(imm_uj) << 1
            7'b1101111: imm_output = {{12{imm_input_uj[19]}}, imm_input_uj} << 1;

            // LUI, AUIPC: {imm_uj, 12'b0}
            7'b0110111,
            7'b0010111: imm_output = {imm_input_uj, 12'b0};

            // JALR: sign_extend(imm)
            7'b1100111: imm_output = {{20{imm_input[11]}}, imm_input};

            // I-type ALU
            7'b0010011: begin
                if (fn3 == 3'b001 || fn3 == 3'b101)
                    imm_output = {27'b0, imm_input[4:0]};          // shifts
                else
                    imm_output = {{20{imm_input[11]}}, imm_input}; // other I-type
            end

            // Load, store, R-type, anything else
            default: imm_output = {{20{imm_input[11]}}, imm_input};
        endcase
    end

endmodule
