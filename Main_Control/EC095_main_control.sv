`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2026 11:29:56
// Design Name: 
// Module Name: main_control
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


module main_control (
    input  logic [6:0] opcode,
    input  logic [2:0] fn3,
    output logic [1:0] memtoreg,    // write-back select
    output logic       branch,
    output logic       mux_inp,     // 1 = JALR (target comes from the ALU)
    output logic       memread,
    output logic       memwrite,
    output logic       alusrc,      // 0 = rs2, 1 = immediate
    output logic       reg_write,
    output logic [2:0] aluop        // operation class for the ALU control
);

    always_comb begin
        // defaults = "other" row
        memtoreg  = 2'b00;
        branch    = 1'b0;
        mux_inp   = 1'b0;
        memread   = 1'b0;
        memwrite  = 1'b0;
        alusrc    = 1'b0;
        reg_write = 1'b0;
        aluop     = 3'b000;

        case (opcode)
            // R-type
            7'b0110011: begin
                memtoreg  = 2'b00;
                alusrc    = 1'b0;
                reg_write = 1'b1;
                aluop     = 3'b000;
            end

            // I-type ALU
            7'b0010011: begin
                memtoreg  = 2'b00;
                alusrc    = 1'b1;
                reg_write = 1'b1;
                aluop     = 3'b001;
            end

            // Load
            7'b0000011: begin
                memtoreg  = 2'b01;
                memread   = 1'b1;
                alusrc    = 1'b1;
                reg_write = 1'b1;
                aluop     = 3'b010;
            end

            // Store
            7'b0100011: begin
                memtoreg  = 2'b11;
                memwrite  = 1'b1;
                alusrc    = 1'b1;
                reg_write = 1'b0;
                aluop     = 3'b011;
            end

            // Branch
            7'b1100011: begin
                memtoreg  = 2'b00;
                branch    = 1'b1;
                alusrc    = 1'b0;
                reg_write = 1'b0;
                aluop     = 3'b100;
            end

            // JAL
            7'b1101111: begin
                memtoreg  = 2'b10;
                alusrc    = 1'b1;
                reg_write = 1'b1;
                aluop     = 3'b110;
            end

            // JALR
            7'b1100111: begin
                memtoreg  = 2'b10;
                mux_inp   = 1'b1;
                alusrc    = 1'b1;
                reg_write = 1'b1;
                aluop     = 3'b001;
            end

            // LUI
            7'b0110111: begin
                memtoreg  = 2'b10;
                alusrc    = 1'b1;
                reg_write = 1'b1;
                aluop     = 3'b110;
            end

            // AUIPC
            7'b0010111: begin
                memtoreg  = 2'b10;
                alusrc    = 1'b1;
                reg_write = 1'b1;
                aluop     = 3'b000;
            end

            default: begin
            end
        endcase
    end

endmodule
