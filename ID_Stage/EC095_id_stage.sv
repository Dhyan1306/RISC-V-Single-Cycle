`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2026 11:56:55
// Design Name: 
// Module Name: id_stage
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

module id_stage(
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic [31:0] instruction,
    input  logic [31:0] wb_data,        // data to write back (from the WB stage)
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] imm_out,
    output logic [6:0]  opcode_out_d,
    output logic [6:0]  imm11_5,
    output logic [2:0]  fn3_out_d,
    output logic        fn7_5,
    output logic [2:0]  aluop,
    output logic [1:0]  memtoreg,
    output logic        branch,
    output logic        mem_write,
    output logic        mem_read,
    output logic        alu_src,
    output logic        mux_inp
);

    // Decoder outputs
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic [11:0] imm_12;
    logic [19:0] imm_uj;

    // Main control output
    logic        reg_write;

    // Register write enable gated by stall
    logic        reg_write_en;
    assign reg_write_en = reg_write && !stall;

    // Decoder
    decoder u_decoder (
        .instruction (instruction),
        .rs1         (rs1_addr),
        .rs2         (rs2_addr),
        .rd          (rd_addr),
        .opcode      (opcode_out_d),
        .imm11_5     (imm11_5),
        .fn3         (fn3_out_d),
        .imm         (imm_12),
        .imm_uj      (imm_uj),
        .fn7_5       (fn7_5)
    );

    // Immediate generator
    imm_generator u_imm_generator (
        .imm_input    (imm_12),
        .fn3          (fn3_out_d),
        .opcode       (opcode_out_d),
        .imm_input_uj (imm_uj),
        .imm_output   (imm_out)
    );

    // Register file
    register_file u_register_file (
        .rs1_sel   (rs1_addr),
        .rs2_sel   (rs2_addr),
        .reg_write (reg_write_en),
        .clk       (clk),
        .reset     (reset),
        .wb_data   (wb_data),
        .rd_sel    (rd_addr),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    // Main control
    main_control u_main_control (
        .opcode    (opcode_out_d),
        .fn3       (fn3_out_d),
        .memtoreg  (memtoreg),
        .branch    (branch),
        .mux_inp   (mux_inp),
        .memread   (mem_read),
        .memwrite  (mem_write),
        .alusrc    (alu_src),
        .reg_write (reg_write),
        .aluop     (aluop)
    );

endmodule
