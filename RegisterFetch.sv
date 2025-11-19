// clocked outputs from regFile

module RegisterFetch (Da, Db, Rd, mem_wr, reg_wr, alu_src, ctrl, mem_to_reg, setFlags, shift, imm_or_D9, D9, Imm12, Shamt, clk, rst, instruction,
							 REG_Da, REG_Db, REG_Rd, REG_mem_wr, REG_reg_wr, REG_alu_src, REG_ctrl, REG_mem_to_reg, REG_setFlags, REG_shift, REG_imm_or_D9, 
							 REG_D9, REG_Imm12, REG_Shamt, REG_instruction);
	// === INPUTS ===
	input logic [63:0] Da, Db;
	input logic [31:0] instruction;
	input logic [11:0] Imm12;
	input logic [8:0] D9;
	input logic [5:0] Shamt;
	input logic [4:0] Rd;
	input logic [2:0] ctrl;
	input logic mem_wr, reg_wr, alu_src, mem_to_reg, setFlags, shift, imm_or_D9;
	input logic clk, rst;
	
	// === OUTPUTS ===
	output logic [63:0] REG_Da, REG_Db;
	output logic [31:0] REG_instruction;
	output logic [11:0] REG_Imm12;
	output logic [8:0] REG_D9;
	output logic [5:0] REG_Shamt;
	output logic [4:0] REG_Rd;
	output logic [2:0] REG_ctrl;
	output logic REG_mem_wr, REG_reg_wr, REG_alu_src, REG_mem_to_reg, REG_setFlags, REG_shift, REG_imm_or_D9;
	
	// === REGISTER OUTPUTS ===
	register DataA (.enable(1), .writeData(Da), .readData(REG_Da), .clk(clk), .rst(rst));
	register DataB (.enable(1), .writeData(Db), .readData(REG_Db), .clk(clk), .rst(rst));
	
	// === CONTROL FLAGS ===
	D_FF MemoryWriteEnable (.d(mem_wr), .q(REG_mem_wr), .reset(rst), .clk(clk));
	D_FF RegisterWriteEnable (.d(reg_wr), .q(REG_reg_wr), .reset(rst), .clk(clk));
	D_FF ALUSource (.d(alu_src), .q(REG_alu_src), .reset(rst), .clk(clk));
	D_FF MemoryToRegMuxSelect (.d(mem_to_reg), .q(REG_mem_to_reg), .reset(rst), .clk(clk));
	D_FF SetALUFlags (.d(setFlags), .q(REG_setFlags), .reset(rst), .clk(clk));
	D_FF ShiftSelect (.d(shift), .q(REG_shift), .reset(rst), .clk(clk));
	D_FF ImmOrD9Select (.d(imm_or_D9), .q(REG_imm_or_D9), .reset(rst), .clk(clk));
	
	genvar i;
	generate
		// === 12-BIT IMMEDIATE ===
		for (i = 0; i < 12; i++) begin: imm12
			D_FF reg0 (.d(Imm12[i]), .q(REG_Imm12[i]), .reset(rst), .clk(clk));
		end
		
		// === INSTRUCTION ===
		for (i = 0; i < 32; i++) begin: instr
			D_FF reg2 (.d(instruction[i]), .q(REG_instruction), .reset(rst), .clk(clk));
		end
		
		// === D9 ===
		for (i = 0; i < 9; i++) begin: d9
			D_FF reg2 (.d(D9[i]), .q(REG_D9[i]), .reset(rst), .clk(clk));
		end
		
		// === SHAMT ===
		for (i = 0; i < 6; i++) begin: shamt
		  D_FF reg3 (.d(Shamt[i]), .q(REG_Shamt[i]), .reset(rst), .clk(clk));
		end

		// === RD ===
		for (i = 0; i < 5; i++) begin: rd
		  D_FF reg4 (.d(Rd[i]), .q(REG_Rd[i]), .reset(rst), .clk(clk));
		end

		// === CTRL ===
		for (i = 0; i < 3; i++) begin: ctrl_bits
		  D_FF reg5 (.d(ctrl[i]), .q(REG_ctrl[i]), .reset(rst), .clk(clk));
		end
	endgenerate
endmodule 