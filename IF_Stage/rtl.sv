
module if_stage (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        and_out,
    input  logic [31:0] pc_signed_offset,
    output logic [31:0] address,
    output logic [31:0] pc_new
);

    logic [31:0] next_pc;

    // Calculate sequential next PC
    assign pc_new = address + 32'd4;

    // Select branch/jump target or sequential PC
    assign next_pc = and_out ? pc_signed_offset : pc_new;

    // Program Counter register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            address <= 32'h8000_0000;
        else if (!stall)
            address <= next_pc;
    end

endmodule
