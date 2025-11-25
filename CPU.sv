//`timescale 1ps/1ps
module CPU (clk, rst);
	input logic clk, rst;
	
//-----------------------------------------------------------------------
//
// Internal Logic 
//
//-----------------------------------------------------------------------

	logic [63:0] inst_address;					// instruction of the address
	logic [31:0] instruction; 					// instruction from instructmem
	
	logic [25:0] br_address; 					// immediate address for branching
	logic [18:0] cond_address; 				// immediate address for branching with conditionals
	logic [4:0] Rd, Rn, Rm, Ab; 				// register adresses
	logic [2:0] ctrl;								// ALUOp
	
	logic mem_wr, reg_wr; 						// CL flags for writing to mem and reg
	logic br_taken, uncond_br; 				// CL flags used for branching
	logic alu_src, reg_2_loc, mem_to_reg; 	// CL flags used for mux
	logic zero, negative; 						// asynchronous flags taken from ALU
	logic zero_flag, neg_flag; 				// synchronous flags used in CL
	logic setFlags; 								// set synchronous flags for CB
	logic imm_or_D9; 								// chooses the value of the immediate in ALUSrc
	logic shift; 									// shift flag
		
	logic [63:0] Da, Db, Dw; 		// ReadRegister1, ReadRegister2, WriteRegister
	logic [63:0] Dout; 				// data read from the memory
	
	logic [63:0] B, A; 			   // inputs to ALU
	logic [63:0] alu_result; 		// output from ALU
	logic [63:0] shift_result; 	// output from shifter
	logic [63:0] op_result; 		// result used for mem_to_reg 
	
	logic [11:0] Imm12; 				// 12 bit immediate
	logic [63:0] Imm12_se; 			// extension of Imm12
	logic [8:0]  D9; 					// 9 bit address
	logic [63:0] D9_se; 				// extension of D9
	logic [63:0] immediate; 		// D9_se or Imm12_se if imm_or_d9 is false or true
	
	logic [5:0] SHAMT; 				// shift amount
	
	logic zero_mux_in, neg_mux_in;// input values for the flag registers
	
	genvar i; // for muxes
	
	// === INSTRUCTION FETCH OUTPUT ===
	logic [31:0] IFETCH_instruction;			// registered instruction
	
	// === REG/DEC OUTPUTS ===
	logic [63:0] REG_Da, REG_Db, ALU_src_out, ReadData1, ReadData2;
	logic [31:0] REG_instruction;
	logic [11:0] REG_Imm12;
	logic [8:0] REG_D9;
	logic [5:0] REG_Shamt;
	logic [4:0] REG_Rd;
	logic [2:0] REG_ctrl;
	logic REG_mem_wr, REG_reg_wr, REG_alu_src, REG_mem_to_reg, REG_setFlags, REG_shift, REG_imm_or_D9;
	
	// === EXECUTE OUTPUTS ===
	logic [63:0] EXEC_ALU_result, EXEC_Db;
	logic [31:0] EXEC_instruction;
	logic [4:0] EXEC_Rd;
	logic EXEC_mem_wr, EXEC_reg_wr, EXEC_mem_to_reg;
	
	// === MEMORY OUTPUTS ===
	logic [63:0] MEM_Dw;
	logic [4:0] MEM_Rd;
	logic MEM_reg_wr;
	
	// === FORWARDING LOGIC ===
	logic [63:0] forwardDa, forwardDb;
	logic [1:0] forward_selA, forward_selB;
	
	// === PROGRAM COUNTER LOGIC ===
	logic [63:0] PC, PC_buffered, nextPC, PC_plus_4, PC_plus_branch;
	logic [63:0] cond_address_se, br_address_se, pre_shift, post_shift;
	logic isZero, br_taken_delayed;

//=======================================================
// IFETCH
//=======================================================
	PC_register pc (.clk, .rst, .currPC(PC), .nextPC);
	register pcBuffer (.enable(1'b1), .writeData(PC), .readData(PC_buffered), .clk, .rst);
	instructmem inst   (.clk, .address(PC), .instruction);
	generate
		// IFETCH -> REG/DECODE
		for (i = 0; i < 32; i++) begin: fetch_instr
			D_FF reg2 (.d(instruction[i]), .q(IFETCH_instruction[i]), .reset(rst), .clk(clk));
		end
		
		// PC + 4 OR PC + BRANCH ADDRESS MUX
		for (i = 0; i < 64; i++) begin: newPC
			multiplexer pcMux (.a(PC_plus_4[i]), .b(PC_plus_branch[i]), .s(br_taken/*br_taken from control logic*/), .y(nextPC[i]));
		end
	endgenerate
	
	// calculate PC + 4 in IFETCH
	alu adder (.A(PC), .B(64'd4), .cntrl(3'b010), .result(PC_plus_4), .zero(), .negative(), .carry_out(), .overflow());
		
//=======================================================
// REG/DEC
//=======================================================
	// control logic happens right after IFETCH
	control_logic CL 	 (.instruction(IFETCH_instruction), .Rd, .Rn, .Rm, .br_address, .cond_address, .SHAMT, .mem_wr, .reg_wr, 
							  .br_taken, .uncond_br, .alu_src, .reg_2_loc, .mem_to_reg, .zero(zero_mux_in), 
							  .negative(neg_mux_in), .ctrl, .Imm12, .D9, .shift, .imm_or_D9, .setFlags, .cbZero(isZero));
	
	// === FORWARDING LOGIC ===
	forwarding_logic FL (.IFETCH_instruction, .REG_instruction, .EXEC_instruction, .forward_selA, .forward_selB);
	generate // forwarding muxes
		for (i = 0; i < 64; i++) begin: f1
			multiplexer_3to1 m1 (.a(Da[i]), .b(op_result[i]), .c(Dw[i]), .sel(forward_selA), .out(forwardDa[i]));
			multiplexer_3to1 m2 (.a(Db[i]), .b(op_result[i]), .c(Dw[i]), .sel(forward_selB), .out(forwardDb[i]));
		end
	endgenerate
	
	// === COMPUTE BRANCH ADDRESS ===
	signExtender #(.IN_WIDTH(19)) condBr19  (.in(cond_address), .out(cond_address_se), .SE(1'b1));
	signExtender #(.IN_WIDTH(26)) br26 (.in(br_address), .out(br_address_se), .SE(1'b1));
	shifter shifted (.value(pre_shift), .direction(1'b0), .distance(6'd2), .result(post_shift));
	alu br_adder (.A(PC_buffered), .B(post_shift), .cntrl(3'b010), .result(PC_plus_branch), .zero(), .negative(), .carry_out(), .overflow());
	generate // conditional or unconditional mux
		for(i = 0; i < 64; i++) begin: muxes
			multiplexer cond_mux0 (.a(cond_address_se[i]), .b(br_address_se[i]), .s(uncond_br), .y(pre_shift[i]));
		end
	endgenerate	
	
	// === BRANCH LOGIC === 
	//zeroChecker checkCBZ (.result(fowardDb), .isZero);
	alu checkCBZ (.A(), .B(forwardDb), .cntrl(3'b000), .result(), .zero(isZero), .negative(), .carry_out(), .overflow()); // for computing CBZ
	

	// === MAIN REGISTER ===
	generate // reg2loc
		for(i = 0; i < 5; i++) begin: register_input_muxes
			multiplexer mux_Reg2Loc_0 (.a(Rd[i]), .b(Rm[i]), .s(reg_2_loc), .y(Ab[i]));
		end
	endgenerate
	regfile register (.clk(~clk), .RegWrite(MEM_reg_wr), .ReadData1(Da), .ReadData2(Db), .WriteData(MEM_Dw), .ReadRegister1(Rn), 
									.ReadRegister2(Ab), .WriteRegister(MEM_Rd));
	
	
	// send register results to next stage
	RegisterFetch regDec (.Da(forwardDa), .Db(forwardDb), .Rd, .mem_wr, .reg_wr, .alu_src, .ctrl, .mem_to_reg, .setFlags, .shift, .imm_or_D9, .D9, .Imm12, .Shamt(SHAMT), .clk, .rst, .instruction(IFETCH_instruction[31:0]),
								 .REG_Da, .REG_Db, .REG_Rd, .REG_mem_wr, .REG_reg_wr, .REG_alu_src, .REG_ctrl, .REG_mem_to_reg, 
								 .REG_setFlags, .REG_shift, .REG_imm_or_D9, .REG_D9, .REG_Imm12, .REG_Shamt, .REG_instruction);
	
//=======================================================
// EXEC
//=======================================================
	// sign extension for immediates
	signExtender #(9) se_9 (.in(REG_D9), .out(D9_se), .SE(1'b1));
	signExtender #(12) se_12 (.in(REG_Imm12), .out(Imm12_se), .SE(1'b0));
	
	// Datapath muxes
	generate
		for(i = 0; i < 64; i++) begin: datapath_muxes
			multiplexer mux_imm_sel_0 (.a(D9_se[i]), .b(Imm12_se[i]), .s(REG_imm_or_D9), .y(immediate[i]));
			multiplexer mux_ALUSrc_0 (.a(REG_Db[i]), .b(immediate[i]), .s(REG_alu_src), .y(ALU_src_out[i]));
			multiplexer mux_shift_0 (.a(alu_result[i]), .b(shift_result[i]), .s(REG_shift), .y(op_result[i]));
		end
	endgenerate
	
	alu ALU (.A(REG_Da), .B(ALU_src_out), .cntrl(REG_ctrl), .result(alu_result), .negative, .zero, .overflow(), .carry_out()); 
	shifter shifter (.value(REG_Da), .direction(1'b1), .distance(REG_Shamt), .result(shift_result));
	
	// Flag register
	multiplexer zero_mux(.a(zero_flag), .b(zero), .s(REG_setFlags), .y(zero_mux_in));
	multiplexer neg_mux(.a(neg_flag), .b(negative), .s(REG_setFlags), .y(neg_mux_in));
	D_FF zero_reg (.q(zero_flag), .d(zero_mux_in), .clk, .reset(rst));
	D_FF neg_reg(.q(neg_flag), .d(neg_mux_in), .clk, .reset(rst));
	
	// send results to memory stage
	Execute toMemory (.ALU_result(op_result), .Db(REG_Db), .Rd(REG_Rd), .mem_wr(REG_mem_wr), .reg_wr(REG_reg_wr), 
							.mem_to_reg(REG_mem_to_reg), .clk(clk), .rst(rst), .instruction(REG_instruction),
							.REG_ALU_result(EXEC_ALU_result), .REG_Db(EXEC_Db), .REG_Rd(EXEC_Rd), .REG_mem_wr(EXEC_mem_wr), 
							.REG_reg_wr(EXEC_reg_wr), .REG_mem_to_reg(EXEC_mem_to_reg), .REG_instruction(EXEC_instruction));
	
//=======================================================
// MEM/WR
//=======================================================
	datamem memory (.clk, .address(EXEC_ALU_result), .write_enable(EXEC_mem_wr), .read_enable(1'b1), 
						 .write_data(EXEC_Db), .xfer_size(4'b1000), .read_data(Dout));

	generate
		// MEM TO REG MUX
		for (i = 0; i < 64; i++) begin: MemToReg
			multiplexer mux_MemToReg_0 (.a(EXEC_ALU_result[i]), .b(Dout[i]), .s(EXEC_mem_to_reg), .y(Dw[i]));
		end
	endgenerate
	
	// send results to write stage
	register MemoryToRegister (.enable(1'b1), .writeData(Dw), .readData(MEM_Dw), .clk, .rst);
	D_FF MemoryToRegisterWriteEnable (.q(MEM_reg_wr), .d(EXEC_reg_wr), .clk, .reset(rst));
	generate
		// === RD ===
		for (i = 0; i < 5; i++) begin: rd
		  D_FF regx (.d(EXEC_Rd[i]), .q(MEM_Rd[i]), .reset(rst), .clk(clk));
		end
	endgenerate
endmodule 