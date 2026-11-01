`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2026 11:32:13
// Design Name: 
// Module Name: wb_stage
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


module wb_stage(
    input  logic [31:0] mem_out,           // data from data memory
    input  logic [31:0] alu_out,
    input  logic [31:0] return_addr,       // PC + 4
    input  logic [31:0] imm_out,           // LUI immediate
    input  logic [31:0] pc_signed_offset,  // PC + upper immediate (AUIPC)
    input  logic [1:0]  memtoreg,
    input  logic [6:0]  opcode_out_d,
    output logic [31:0] wb_data
);

    always_comb begin
        case (memtoreg)
            2'b00: wb_data = alu_out;
            2'b01: wb_data = mem_out;
            2'b10: begin
                case (opcode_out_d)
                    7'b1101111,                         // JAL
                    7'b1100111: wb_data = return_addr;  // JALR
                    7'b0110111: wb_data = imm_out;      // LUI
                    7'b0010111: wb_data = pc_signed_offset; // AUIPC
                    default:    wb_data = alu_out;
                endcase
            end
            2'b11:   wb_data = alu_out;
            default: wb_data = alu_out;
        endcase
    end

endmodule