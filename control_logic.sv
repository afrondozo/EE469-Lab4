// Control logic
// inst			Operation						Notes:
//	B
//	B.cond											use negative flag
//	CBZ			PASS_B							use zero flag
//	AND			AND
//	ADD			ADD
//	ADDS			ADD								throw out result
// EOR
//	LSR			LSR
//	SUBS			SUB								throw out result
// ADDI
// STUR												uses add
// LDUR												uses add
//`timescale 1ps/1ps
module control_logic(instruction, Rd, Rn, Rm, br_address, cond_address, SHAMT, mem_wr, reg_wr, br_taken, uncond_br, 
									alu_src, reg_2_loc, mem_to_reg, zero, negative, ctrl, Imm12, D9, setFlags, shift, imm_or_D9, cbZero);
	input logic [31:0] instruction;
	input logic zero, negative, cbZero;
	output logic [4:0] Rd, Rn, Rm;
	output logic [25:0] br_address;
	output logic [18:0] cond_address;
	output logic [5:0] SHAMT;
	output logic [2:0] ctrl;
	output logic [11:0] Imm12;
	output logic [8:0]  D9;
	output logic mem_wr, reg_wr, br_taken, uncond_br, alu_src, reg_2_loc, mem_to_reg, setFlags, shift, imm_or_D9;
	
	logic [10:0] op_code;
	logic [4:0] cond_code;
	logic br_cond;
	
	assign op_code = instruction[31:21];
	assign cond_code = instruction [4:0];
	
	always_comb begin
		case (cond_code)
			5'b00000: br_cond = zero; // EQ == 
			5'b00001: br_cond = !(zero); // NE !=
			5'b01010: br_cond = !(negative); // GE >= 
			5'b01011: br_cond = negative; // LT <
			5'b01100: br_cond = !(negative && zero); // GT >
			5'b01101: br_cond = (negative | zero); // LE <=
			default: br_cond = 1'b0;
		endcase
		
		casex(op_code)
			// B type
			11'b000101XXXXX: begin br_address = instruction[25:0];// B
										  mem_wr = 0; reg_wr = 0; br_taken= 1; uncond_br = 1; alu_src = 1'bX; reg_2_loc = 1'bX; mem_to_reg = 1'bX; setFlags = 0; shift = 0;
								  end
			
			// CB type
			11'b01010100XXX: begin cond_address = instruction[23:5]; // B.cond
										  //cond_code = instruction[4:0]; // conditional code
										  //ctrl = 3'b011; // subtract
										  mem_wr = 0; reg_wr = 0; br_taken = br_cond; uncond_br = 0; alu_src = 1'bX; reg_2_loc = 1'bX; mem_to_reg = 1'bX; setFlags = 0; shift = 0;
								  end
			11'b10110100XXX: begin cond_address = instruction[23:5];// CBZ
										  Rd = instruction[4:0]; // register being checked
										  ctrl = 3'b000; // pass
										  mem_wr = 0; reg_wr = 0; br_taken = cbZero; uncond_br = 0; alu_src = 0; reg_2_loc = 0; mem_to_reg = 1'bX; setFlags = 0; shift = 0;
								  end
								  
			// R type
			11'b10001010000: begin Rd = instruction[4:0]; // AND
										  Rn = instruction[9:5];
										  Rm = instruction[20:16];
										  ctrl = 3'b100; // and
										  mem_wr = 0; reg_wr = 1; br_taken= 0; uncond_br = 1'bX; alu_src = 0; reg_2_loc = 1; mem_to_reg = 0; setFlags = 0; shift = 0; 
								  end
			11'b10001011000: begin Rd = instruction[4:0]; // ADD
										  Rn = instruction[9:5];
										  Rm = instruction[20:16];
										  ctrl = 3'b010; // add
										  mem_wr = 0; reg_wr = 1; br_taken = 0; uncond_br = 1'bX; alu_src = 0; reg_2_loc = 1; mem_to_reg = 0; setFlags = 0; shift = 0;
								  end
			11'b10101011000: begin Rd = instruction[4:0]; // ADDS
										  Rn = instruction[9:5];
										  Rm = instruction[20:16];
										  ctrl = 3'b010; // add
										  mem_wr = 0; reg_wr = 1; br_taken = 0; uncond_br = 1'bX; alu_src = 0; reg_2_loc = 1; mem_to_reg = 0; setFlags = 1; shift = 0;
								  end
			11'b11001010000: begin Rd = instruction[4:0]; // EOR
										  Rn = instruction[9:5];
										  Rm = instruction[20:16];
										  ctrl = 3'b110; // xor
										  mem_wr = 0; reg_wr = 1; br_taken = 0; uncond_br = 1'bX; alu_src = 0; reg_2_loc = 1; mem_to_reg = 0; setFlags = 0; shift = 0;
								  end
			11'b11010011010: begin SHAMT = instruction[15:10]; // LSR
										  Rd = instruction[4:0];
										  Rn = instruction[9:5];
										  ctrl = 3'b000; // is this necessary?
										  mem_wr = 0; reg_wr = 1; br_taken = 0; uncond_br = 1'bX; alu_src = 0; reg_2_loc = 1'bX; mem_to_reg = 0; setFlags = 0; shift = 1;
								  end
			11'b11101011000: begin Rd = instruction[4:0]; // SUBS
										  Rn = instruction[9:5];
										  Rm = instruction[20:16];
										  ctrl = 3'b011; // subtract
										  mem_wr = 0; reg_wr = 1; br_taken = 0; uncond_br = 1'bX; alu_src = 0; reg_2_loc = 1; mem_to_reg = 0; setFlags = 1; shift = 0;
								  end
			
			// I type
			11'b1001000100X: begin Rd = instruction[4:0]; // ADDI
										  Rn = instruction[9:5]; 
										  Imm12 = instruction[21:10]; // need sign extend
										  ctrl = 3'b010; // add
										  mem_wr = 0; reg_wr = 1; br_taken = 0; uncond_br = 1'bX; alu_src = 1; reg_2_loc = 1; mem_to_reg = 0; setFlags = 0; shift = 0; imm_or_D9 = 1;
								  end
			
			// D type
			11'b11111000000: begin Rd = instruction[4:0]; // STUR
										  Rn = instruction[9:5];
										  D9 = instruction[20:12]; // need sign extend
										  ctrl = 3'b010; // add
										  mem_wr = 1; reg_wr = 0; br_taken = 0; uncond_br = 1'bX; alu_src = 1; reg_2_loc = 1'b0; mem_to_reg = 1'bX; setFlags = 0; shift = 0; imm_or_D9 = 0;
								  end
			11'b11111000010: begin Rd = instruction[4:0]; // LDUR
										  Rn = instruction[9:5];
										  D9 = instruction[20:12]; // need sign extend
										  ctrl = 3'b010; // add
										  mem_wr = 0; reg_wr = 1; br_taken = 0; uncond_br = 1'bX; alu_src = 1; reg_2_loc = 1'b0; mem_to_reg = 1; setFlags = 0; shift = 0; imm_or_D9 = 0;
								  end
			default: br_taken = 1'b0;
		endcase
	end
endmodule 