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
	
	logic [63:0] B; 					// B input to ALU
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
	logic [63:0] IFETCH_instruction;			// registered instruction
	
	// === REG/DEC OUTPUTS ===
	logic [63:0] REG_Da, REG_Db;
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

//=======================================================
// IFETCH
//=======================================================
	// program counter
	program_counter pc (.clk, .rst, .address(inst_address), .uncond_br, .br_taken, .cond_address, .br_address);
	instructmem inst   (.clk, .address(inst_address), .instruction); // do we need to register instruction?
	register instructionFetch (.enable(1'b1), .writeData({32'b0, instruction}), .readData(IFETCH_instruction), .clk, .rst);
	
//=======================================================
// REG/DEC
//=======================================================
	// control logic happens right after IFETCH
	control_logic CL 	 (.instruction(IFETCH_instruction[31:0]), .Rd, .Rn, .Rm, .br_address, .cond_address, .SHAMT, .mem_wr, .reg_wr, 
							  .br_taken, .uncond_br, .alu_src, .reg_2_loc, .mem_to_reg, .zero(zero_flag), 
							  .negative(neg_flag), .ctrl, .Imm12, .D9, .shift, .imm_or_D9, .setFlags, .cbZero(zero));
	// forwarding logic happens in reg thru mem
	logic [1:0] forward_sel;
	forwarding_logic FL (.IFETCH_instruction, .REG_instruction, .EXEC_instruction, .forward_sel);
	
	// REG 2 LOC
	generate
		for(i = 0; i < 6; i++) begin: register_input_muxes
			multiplexer mux_Reg2Loc_0 (.a(Rd[i]), .b(Rm[i]), .s(reg_2_loc), .y(Ab[i]));
		end
	endgenerate
	
	// DataA mux
	logic [63:0] forwardDa, forwardDb;
	generate
		for (i = 0; i < 64; i++) begin: f1
			multiplexer_3to1 m1 (.a(Da[i]), .b(op_result[i]), .c(Dout[i]), .sel(forward_sel), .out(forwardDa[i]));
			multiplexer_3to1 m2 (.a(Db[i]), .b(op_result[i]), .c(Dout[i]), .sel(forward_sel), .out(forwardDb[i]));
		end
	endgenerate
	
	regfile register (.clk, .RegWrite(MEM_reg_wr), .ReadData1(Da), .ReadData2(Db), .WriteData(MEM_Dw), .ReadRegister1(Rn), 
									.ReadRegister2(Ab), .WriteRegister(MEM_Rd));	
	// TO DO STILL:						
		// implement REG/DEC reg....
		// For accelerated branching:
		// take PC from registered IFETCH.
		//	calculate cond_address or br_address and send it right back to PC
	
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
			multiplexer mux_ALUSrc_0 (.a(REG_Db[i]), .b(immediate[i]), .s(REG_alu_src), .y(B[i]));
			multiplexer mux_shift_0 (.a(alu_result[i]), .b(shift_result[i]), .s(REG_shift), .y(op_result[i]));
		end
	endgenerate
	
	alu ALU (.A(REG_Da), .B, .cntrl(REG_ctrl), .result(alu_result), .negative, .zero, .overflow(), .carry_out()); 
	shifter shifter (.value(REG_Da), .direction(1'b1), .distance(REG_Shamt), .result(shift_result));
	
	// flag logic
	multiplexer zero_mux(.a(zero_flag), .b(zero), .s(REG_setFlags), .y(zero_mux_in));
	multiplexer neg_mux(.a(neg_flag), .b(negative), .s(REG_setFlags), .y(neg_mux_in));
	D_FF zero_reg (.q(zero_flag), .d(zero_mux_in), .clk, .reset(1'b0));
	D_FF neg_reg(.q(neg_flag), .d(neg_mux_in), .clk, .reset(1'b0));
	
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