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
	
//-----------------------------------------------------------------------
//
// Controller 
//
//-----------------------------------------------------------------------
	
	instructmem inst   (.clk, .address(inst_address), .instruction);
	control_logic CL 	 (.instruction, .Rd, .Rn, .Rm, .br_address, .cond_address, .SHAMT, .mem_wr, .reg_wr, 
									.br_taken, .uncond_br, .alu_src, .reg_2_loc, .mem_to_reg, .zero(zero_flag), 
									.negative(neg_flag), .ctrl, .Imm12, .D9, .shift, .imm_or_D9, .setFlags, .cbZero(zero));							
									
//-----------------------------------------------------------------------
//
// Datapath
//
//-----------------------------------------------------------------------
	
	// program counter
	program_counter pc (.clk, .rst, .address(inst_address), .uncond_br, .br_taken, .cond_address, .br_address);
	
	// register and memory
	regfile register (.clk, .RegWrite(reg_wr), .ReadData1(Da), .ReadData2(Db), .WriteData(Dw), .ReadRegister1(Rn), 
									.ReadRegister2(Ab), .WriteRegister(Rd));
	datamem memory (.clk, .address(alu_result), .write_enable(mem_wr), .read_enable(1'b1), 
								.write_data(Db), .xfer_size(4'b1000), .read_data(Dout));
								
	// operations
	alu ALU (.A(Da), .B, .cntrl(ctrl), .result(alu_result), .negative, .zero, .overflow(), .carry_out()); 
	shifter shifter (.value(Da), .direction(1'b1), .distance(SHAMT), .result(shift_result));
	
	// sign extension for immediates
	signExtender #(9) se_9 (.in(D9), .out(D9_se), .SE(1'b1));
	signExtender #(12) se_12 (.in(Imm12), .out(Imm12_se), .SE(1'b0));
	
	// flag logic
	multiplexer zero_mux(.a(zero_flag), .b(zero), .s(setFlags), .y(zero_mux_in));
	multiplexer neg_mux(.a(neg_flag), .b(negative), .s(setFlags), .y(neg_mux_in));
	D_FF zero_reg (.q(zero_flag), .d(zero_mux_in), .clk, .reset(1'b0));
	D_FF neg_reg(.q(neg_flag), .d(neg_mux_in), .clk, .reset(1'b0));
	
	// muxes
	genvar i;
	
	generate
		for(i = 0; i < 64; i++) begin: datapath_muxes
			multiplexer mux_imm_sel_0 (.a(D9_se[i]), .b(Imm12_se[i]), .s(imm_or_D9), .y(immediate[i]));
			multiplexer mux_ALUSrc_0 (.a(Db[i]), .b(immediate[i]), .s(alu_src), .y(B[i]));
			multiplexer mux_shift_0 (.a(alu_result[i]), .b(shift_result[i]), .s(shift), .y(op_result[i]));
			multiplexer mux_MemToReg_0 (.a(op_result[i]), .b(Dout[i]), .s(mem_to_reg), .y(Dw[i]));
		end
		for(i = 0; i < 6; i++) begin: register_input_muxes
			multiplexer mux_Reg2Loc_0 (.a(Rd[i]), .b(Rm[i]), .s(reg_2_loc), .y(Ab[i]));
		end
	endgenerate
	
endmodule 