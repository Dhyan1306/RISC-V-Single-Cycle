`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2026 12:00:10
// Design Name: 
// Module Name: tb_single_cycle_riscv
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


`timescale 1ns/1ps

module tb_single_cycle_riscv;

    // ---------------- DUT signals ----------------
    logic        clk;
    logic        reset;
    logic        stall;
    logic [31:0] instruction;
    logic [31:0] mem_out;
    logic [31:0] rs2_data;
    logic [31:0] alu_out;
    logic        mem_write;
    logic        mem_read;
    logic [2:0]  fn3;
    logic [6:0]  opcode;
    logic [31:0] address;

    single_cycle_riscv dut (
        .clk         (clk),
        .reset       (reset),
        .stall       (stall),
        .instruction (instruction),
        .mem_out     (mem_out),
        .rs2_data    (rs2_data),
        .alu_out     (alu_out),
        .mem_write   (mem_write),
        .mem_read    (mem_read),
        .fn3         (fn3),
        .opcode      (opcode),
        .address     (address)
    );

    // ---------------- Clock ----------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---------------- Instruction memory (PC base 0x8000_0000) ----------------
    logic [31:0] imem [0:1023];

    always_comb instruction = imem[address[11:2]];

    // ---------------- Data memory (byte addressed, 4 KB) ----------------
    logic [7:0] dmem [0:4095];

    // Combinational read
    always_comb begin
        mem_out = 32'b0;
        if (mem_read) begin
            case (fn3)
                3'b000: mem_out = {{24{dmem[alu_out[11:0]][7]}}, dmem[alu_out[11:0]]};            // LB
                3'b001: mem_out = {{16{dmem[alu_out[11:0]+1][7]}},
                                   dmem[alu_out[11:0]+1], dmem[alu_out[11:0]]};                   // LH
                3'b010: mem_out = {dmem[alu_out[11:0]+3], dmem[alu_out[11:0]+2],
                                   dmem[alu_out[11:0]+1], dmem[alu_out[11:0]]};                   // LW
                3'b100: mem_out = {24'b0, dmem[alu_out[11:0]]};                                   // LBU
                3'b101: mem_out = {16'b0, dmem[alu_out[11:0]+1], dmem[alu_out[11:0]]};            // LHU
                default: mem_out = 32'b0;
            endcase
        end
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write) begin
            case (fn3)
                3'b000: dmem[alu_out[11:0]] <= rs2_data[7:0];                                     // SB
                3'b001: begin                                                                     // SH
                    dmem[alu_out[11:0]]   <= rs2_data[7:0];
                    dmem[alu_out[11:0]+1] <= rs2_data[15:8];
                end
                3'b010: begin                                                                     // SW
                    dmem[alu_out[11:0]]   <= rs2_data[7:0];
                    dmem[alu_out[11:0]+1] <= rs2_data[15:8];
                    dmem[alu_out[11:0]+2] <= rs2_data[23:16];
                    dmem[alu_out[11:0]+3] <= rs2_data[31:24];
                end
                default: ;
            endcase
        end
    end

    // ---------------- Instruction encoders ----------------
    function automatic [31:0] r_type(input [6:0] f7, input [4:0] rs2, input [4:0] rs1,
                                     input [2:0] f3, input [4:0] rd);
        r_type = {f7, rs2, rs1, f3, rd, 7'b0110011};
    endfunction

    function automatic [31:0] i_type(input [11:0] imm, input [4:0] rs1,
                                     input [2:0] f3, input [4:0] rd, input [6:0] op);
        i_type = {imm, rs1, f3, rd, op};
    endfunction

    function automatic [31:0] s_type(input [11:0] imm, input [4:0] rs2, input [4:0] rs1,
                                     input [2:0] f3);
        s_type = {imm[11:5], rs2, rs1, f3, imm[4:0], 7'b0100011};
    endfunction

    function automatic [31:0] b_type(input [12:0] imm, input [4:0] rs2, input [4:0] rs1,
                                     input [2:0] f3);
        b_type = {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], 7'b1100011};
    endfunction

    function automatic [31:0] u_type(input [19:0] imm, input [4:0] rd, input [6:0] op);
        u_type = {imm, rd, op};
    endfunction

    function automatic [31:0] j_type(input [20:0] imm, input [4:0] rd);
        j_type = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
    endfunction

    // ---------------- Checker ----------------
    integer pass_cnt;
    integer fail_cnt;

    task automatic check(input string name, input [31:0] actual, input [31:0] expected);
        if (actual === expected) begin
            pass_cnt = pass_cnt + 1;
            $display("PASS  %-22s = 0x%08h", name, actual);
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("FAIL  %-22s got 0x%08h, expected 0x%08h", name, actual, expected);
        end
    endtask

    // Shorthand for reading a register through the hierarchy
    function automatic [31:0] xreg(input integer n);
        xreg = dut.u_id_stage.u_register_file.register[n];
    endfunction

    // ---------------- Program ----------------
    integer k;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;

        // Fill memories: NOP everywhere in imem, zeros in dmem
        for (k = 0; k < 1024; k = k + 1) imem[k] = 32'h0000_0013;   // addi x0,x0,0
        for (k = 0; k < 4096; k = k + 1) dmem[k] = 8'h00;

        //  idx  instruction
        imem[0]  = i_type(12'd10,    5'd0,  3'b000, 5'd1,  7'b0010011);        // addi x1,x0,10
        imem[1]  = i_type(12'd20,    5'd0,  3'b000, 5'd2,  7'b0010011);        // addi x2,x0,20
        imem[2]  = r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3);               // add  x3,x1,x2  = 30
        imem[3]  = r_type(7'b0100000, 5'd1, 5'd2, 3'b000, 5'd4);               // sub  x4,x2,x1  = 10
        imem[4]  = r_type(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd5);               // and  x5,x1,x2  = 0
        imem[5]  = r_type(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd6);               // or   x6,x1,x2  = 30
        imem[6]  = r_type(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd7);               // xor  x7,x1,x2  = 30
        imem[7]  = i_type({7'b0000000, 5'd2}, 5'd1, 3'b001, 5'd8, 7'b0010011); // slli x8,x1,2   = 40
        imem[8]  = i_type({7'b0000000, 5'd2}, 5'd2, 3'b101, 5'd9, 7'b0010011); // srli x9,x2,2   = 5
        imem[9]  = i_type(12'hFF0,   5'd0,  3'b000, 5'd10, 7'b0010011);        // addi x10,x0,-16
        imem[10] = i_type({7'b0100000, 5'd2}, 5'd10, 3'b101, 5'd11, 7'b0010011);// srai x11,x10,2 = 0xFFFFFFFC
        imem[11] = r_type(7'b0000000, 5'd1, 5'd10, 3'b010, 5'd12);             // slt  x12,x10,x1 = 1
        imem[12] = r_type(7'b0000000, 5'd1, 5'd10, 3'b011, 5'd13);             // sltu x13,x10,x1 = 0
        imem[13] = u_type(20'h12345, 5'd14, 7'b0110111);                       // lui   x14,0x12345
        imem[14] = u_type(20'h00000, 5'd15, 7'b0010111);                       // auipc x15,0 = PC
        imem[15] = s_type(12'd256, 5'd3,  5'd0, 3'b010);                       // sw x3,256(x0)
        imem[16] = i_type(12'd256, 5'd0,  3'b010, 5'd16, 7'b0000011);          // lw x16,256(x0) = 30
        imem[17] = s_type(12'd260, 5'd10, 5'd0, 3'b000);                       // sb x10,260(x0)
        imem[18] = i_type(12'd260, 5'd0,  3'b000, 5'd17, 7'b0000011);          // lb  x17,260(x0) = 0xFFFFFFF0
        imem[19] = i_type(12'd260, 5'd0,  3'b100, 5'd18, 7'b0000011);          // lbu x18,260(x0) = 0xF0
        imem[20] = b_type(13'd8, 5'd1, 5'd1, 3'b000);                          // beq x1,x1,+8 (taken)
        imem[21] = i_type(12'd99, 5'd0, 3'b000, 5'd19, 7'b0010011);           // skipped
        imem[22] = i_type(12'd1,  5'd0, 3'b000, 5'd20, 7'b0010011);           // addi x20,x0,1
        imem[23] = b_type(13'd8, 5'd2, 5'd1, 3'b001);                          // bne x1,x2,+8 (taken)
        imem[24] = i_type(12'd99, 5'd0, 3'b000, 5'd21, 7'b0010011);           // skipped
        imem[25] = i_type(12'd2,  5'd0, 3'b000, 5'd22, 7'b0010011);           // addi x22,x0,2
        imem[26] = b_type(13'd8, 5'd1, 5'd10, 3'b100);                         // blt x10,x1,+8 (taken)
        imem[27] = i_type(12'd99, 5'd0, 3'b000, 5'd23, 7'b0010011);           // skipped
        imem[28] = b_type(13'd8, 5'd1, 5'd10, 3'b111);                         // bgeu x10,x1,+8 (taken)
        imem[29] = i_type(12'd99, 5'd0, 3'b000, 5'd24, 7'b0010011);           // skipped
        imem[30] = j_type(21'd8, 5'd25);                                       // jal x25,+8
        imem[31] = i_type(12'd99, 5'd0, 3'b000, 5'd26, 7'b0010011);           // skipped
        imem[32] = u_type(20'h00000, 5'd27, 7'b0010111);                       // auipc x27,0
        imem[33] = i_type(12'd12, 5'd27, 3'b000, 5'd28, 7'b1100111);           // jalr x28,12(x27)
        imem[34] = i_type(12'd99, 5'd0, 3'b000, 5'd29, 7'b0010011);           // skipped
        imem[35] = i_type(12'd7,  5'd0, 3'b000, 5'd30, 7'b0010011);           // addi x30,x0,7
        imem[36] = b_type(13'd8, 5'd2, 5'd1, 3'b000);                          // beq x1,x2,+8 (NOT taken)
        imem[37] = i_type(12'd5,  5'd0, 3'b000, 5'd31, 7'b0010011);           // addi x31,x0,5 (executes)
        imem[38] = i_type(12'd5,  5'd0, 3'b000, 5'd0,  7'b0010011);           // addi x0,x0,5 (must not write)
        imem[39] = j_type(21'd0, 5'd0);                                        // jal x0,0 (halt loop)
    end

    // ---------------- Test sequence ----------------
    initial begin
        reset = 1'b1;
        stall = 1'b0;

        // Reset
        repeat (3) @(posedge clk);
        #1;
        check("PC during reset", address, 32'h8000_0000);
        @(negedge clk);
        reset = 1'b0;

        // Stall test: PC must hold and nothing may be written
        stall = 1'b1;
        repeat (3) @(posedge clk);
        #1;
        check("PC held on stall", address, 32'h8000_0000);
        check("x1 not written (stall)", xreg(1), 32'h0);
        @(negedge clk);
        stall = 1'b0;

        // Run the program
        repeat (60) @(posedge clk);
        #1;

        $display("---------------- Results ----------------");
        check("x1  addi",          xreg(1),  32'd10);
        check("x2  addi",          xreg(2),  32'd20);
        check("x3  add",           xreg(3),  32'd30);
        check("x4  sub",           xreg(4),  32'd10);
        check("x5  and",           xreg(5),  32'd0);
        check("x6  or",            xreg(6),  32'd30);
        check("x7  xor",           xreg(7),  32'd30);
        check("x8  slli",          xreg(8),  32'd40);
        check("x9  srli",          xreg(9),  32'd5);
        check("x10 addi neg",      xreg(10), 32'hFFFF_FFF0);
        check("x11 srai",          xreg(11), 32'hFFFF_FFFC);
        check("x12 slt",           xreg(12), 32'd1);
        check("x13 sltu",          xreg(13), 32'd0);
        check("x14 lui",           xreg(14), 32'h1234_5000);
        check("x15 auipc",         xreg(15), 32'h8000_0038);
        check("x16 sw/lw",         xreg(16), 32'd30);
        check("x17 sb/lb",         xreg(17), 32'hFFFF_FFF0);
        check("x18 sb/lbu",        xreg(18), 32'h0000_00F0);
        check("x19 beq skip",      xreg(19), 32'd0);
        check("x20 beq target",    xreg(20), 32'd1);
        check("x21 bne skip",      xreg(21), 32'd0);
        check("x22 bne target",    xreg(22), 32'd2);
        check("x23 blt skip",      xreg(23), 32'd0);
        check("x24 bgeu skip",     xreg(24), 32'd0);
        check("x25 jal link",      xreg(25), 32'h8000_007C);
        check("x26 jal skip",      xreg(26), 32'd0);
        check("x27 auipc",         xreg(27), 32'h8000_0080);
        check("x28 jalr link",     xreg(28), 32'h8000_0088);
        check("x29 jalr skip",     xreg(29), 32'd0);
        check("x30 jalr target",   xreg(30), 32'd7);
        check("x31 beq not taken", xreg(31), 32'd5);
        check("x0 stays zero",     xreg(0),  32'd0);
        check("dmem[256] (SW)",    {dmem[259], dmem[258], dmem[257], dmem[256]}, 32'd30);
        check("dmem[260] (SB)",    {24'b0, dmem[260]}, 32'h0000_00F0);
        check("PC at halt loop",   address,  32'h8000_009C);

        $display("-----------------------------------------");
        $display("Total: %0d passed, %0d failed", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TESTS PASSED");
        else               $display("SOME TESTS FAILED");

        $finish;
    end

    // Safety timeout
    initial begin
        #5000;
        $display("TIMEOUT");
        $finish;
    end

    // Optional waveform dump
    initial begin
        $dumpfile("tb_single_cycle_riscv.vcd");
        $dumpvars(0, tb_single_cycle_riscv);
    end

endmodule
