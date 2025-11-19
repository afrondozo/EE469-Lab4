// CLOCKED OUTPUTS FROM EXECUTE STAGE
module Execute (ALU_result, Db, Rd, mem_wr, reg_wr, mem_to_reg, clk, rst, instruction,
					 REG_ALU_result, REG_Db, REG_Rd, REG_mem_wr, REG_reg_wr, REG_mem_to_reg, REG_instruction);
	// === INPUTS ===
	input logic [63:0] ALU_result, Db;
	input logic [31:0] instruction;
	input logic [4:0] Rd;
	input logic mem_wr, reg_wr, mem_to_reg;
	input logic clk, rst;
	
	// === OUTPUTS ===
	output logic [63:0] REG_ALU_result, REG_Db;
	output logic [31:0] REG_instruction;
	output logic [4:0] REG_Rd;
	output logic REG_mem_wr, REG_reg_wr, REG_mem_to_reg;
	
	// === 64-BIT OUTPUTS ===
	register aluResult (.enable(1), .writeData(ALU_result), .readData(REG_ALU_result), .clk(clk), .rst(rst));
	register DataB (.enable(1), .writeData(Db), .readData(REG_Db), .clk(clk), .rst(rst));
	
	// === 32-BIT INSTRUCTION OUTPUT ===
	genvar i;
	generate
		// === INSTRUCTION ===
		for (i = 0; i < 32; i++) begin: instr
			D_FF reg2 (.d(instruction[i]), .q(REG_instruction), .reset(rst), .clk(clk));
		end
	endgenerate
	
	// === CONTROL FLAGS ===
	D_FF MemoryWriteEnable (.d(mem_wr), .q(REG_mem_wr), .reset(rst), .clk(clk));
	D_FF RegisterWriteEnable (.d(reg_wr), .q(REG_reg_wr), .reset(rst), .clk(clk)); 
	D_FF MemoryToRegMuxSelect (.d(mem_to_reg), .q(REG_mem_to_reg), .reset(rst), .clk(clk));
endmodule 