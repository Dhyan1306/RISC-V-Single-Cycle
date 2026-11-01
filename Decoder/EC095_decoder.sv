`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2026 11:25:29
// Design Name: 
// Module Name: decoder
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


module decoder(
    input  logic [31:0] instruction,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic [6:0]  opcode,
    output logic [6:0]  imm11_5,      // instruction[31:25] (I-type ALU only)
    output logic [2:0]  fn3,
    output logic [11:0] imm,          // I / S / B immediate bits
    output logic [19:0] imm_uj,       // U / J immediate bits
    output logic        fn7_5         // instruction[30] (R-type only)
);

    always_comb begin
        // opcode is always instruction[6:0]
        opcode  = instruction[6:0];

        // everything else defaults to 0
        rs1     = 5'b0;
        rs2     = 5'b0;
        rd      = 5'b0;
        imm11_5 = 7'b0;
        fn3     = 3'b0;
        imm     = 12'b0;
        imm_uj  = 20'b0;
        fn7_5   = 1'b0;

        case (instruction[6:0])
            // R-type
            7'b0110011: begin
                rd    = instruction[11:7];
                fn3   = instruction[14:12];
                rs1   = instruction[19:15];
                rs2   = instruction[24:20];
                fn7_5 = instruction[30];
            end

            // I-type ALU
            7'b0010011: begin
                rd      = instruction[11:7];
                fn3     = instruction[14:12];
                rs1     = instruction[19:15];
                imm     = instruction[31:20];
                imm11_5 = instruction[31:25];
            end

            // Load
            7'b0000011: begin
                rd  = instruction[11:7];
                fn3 = instruction[14:12];
                rs1 = instruction[19:15];
                imm = instruction[31:20];
            end

            // Store
            7'b0100011: begin
                fn3 = instruction[14:12];
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                imm = {instruction[31:25], instruction[11:7]};
            end

            // Branch
            7'b1100011: begin
                fn3 = instruction[14:12];
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                imm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
            end

            // JAL
            7'b1101111: begin
                rd     = instruction[11:7];
                imm_uj = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
            end

            // JALR
            7'b1100111: begin
                rd  = instruction[11:7];
                fn3 = instruction[14:12];
                rs1 = instruction[19:15];
                imm = instruction[31:20];
            end

            // LUI
            7'b0110111: begin
                rd     = instruction[11:7];
                imm_uj = instruction[31:12];
            end

            // AUIPC
            7'b0010111: begin
                rd     = instruction[11:7];
                imm_uj = instruction[31:12];
            end

            // Unsupported: only opcode is driven
            default: begin
            end
        endcase
    end

endmodule