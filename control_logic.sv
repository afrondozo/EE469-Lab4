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
	
	always_comb begin
		casex(op_code)
			// B type
			11'b000101XXXXX: begin br_address = instruction[25:0];// B
										  mem_wr = 0; reg_wr = 0; br_taken= 1; uncond_br = 1; alu_src = 1'bX; reg_2_loc = 1'bX; mem_to_reg = 1'bX; setFlags = 0; shift = 0;
								  end
			
			// CB type
			11'b01010100XXX: begin cond_address = instruction[23:5]; // B.cond
										  cond_code = instruction[4:0]; // conditional code
										  ctrl = 3'b011; // subtract
										  mem_wr = 0; reg_wr = 0; br_taken = br_cond; uncond_br = 0; alu_src = 1'bX; reg_2_loc = 1'bX; mem_to_reg = 1'bX; setFlags = 0; shift = 0;
								  end
			11'b10110100XXX: begin cond_address = instruction[23:5];// CBZ
										  Rd = instruction[4:0]; // register being checked
										  ctrl = 3'b000; // pass
										  mem_wr = 0; reg_wr = 0; br_taken= cbZero; uncond_br = 0; alu_src = 0; reg_2_loc = 0; mem_to_reg = 1'bX; setFlags = 0; shift = 0;
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
		endcase
		
		case (cond_code)
			5'b00000: br_cond = zero; // EQ == 
			5'b00001: br_cond = !(zero); // NE !=
			5'b01010: br_cond = !(negative); // GE >= 
			5'b01011: br_cond = negative; // LT <
			5'b01100: br_cond = !(negative && zero); // GT >
			5'b01101: br_cond = (negative | zero); // LE <=
		endcase
	end
endmodule

/*
module control_logic_testbench();
	logic [31:0] instruction;
	logic zero, negative;
	logic [4:0] Rd, Rn, Rm;
	logic [25:0] br_address;
	logic [18:0] cond_address;
	logic [5:0] SHAMT;
	logic [2:0] ctrl;
	logic [11:0] Imm12;
	logic [8:0]  D9;
	logic mem_wr, reg_wr, br_taken, uncond_br, alu_src, reg_2_loc, mem_to_reg;
	
	control_logic dut (.instruction, .Rd, .Rn, .Rm, .br_address, .SHAMT, .mem_wr, .reg_wr, .br_taken, .uncond_br, 
									.alu_src, .reg_2_loc, .mem_to_reg, .zero, .negative, .ctrl, .Imm12, .D9);
									
	initial begin
		// Test I-types
		instruction = 32'b1001000100_000000100011_00110_10000; zero = 0; negative = 0; #10; // ADDI X16, X6, #35
		// Test R-types	
		instruction = 32'b10101011000_00110_000000_00101_00011; zero = 0; negative = 0; #10; // ADDS X3, X5, X6
		instruction = 32'b10001010000_00110_000000_00101_00011; zero = 0; negative = 0; #10; // AND X3, X5, X6
		instruction = 32'b11001010000_00001_000000_00010_00011; zero = 0; negative = 0; #10; // EOR X3, X2, X1
		instruction = 32'b11010011010_00000_000110_00100_01010; zero = 0; negative = 0; #10; // LSR X10, X4, #6
		instruction = 32'b11101011000_01000_000000_10000_00011; zero = 0; negative = 0; #10; // SUBS X3, X16, X8
		// Test CB-Type
		instruction = 32'b000101_11111111111111111111111101; zero = 0; negative = 0; #10; // B -3
		instruction = 32'b01010100_1111111111111111011_01011; zero = 0; negative = 1; #10; // B.LT -5
		instruction = 32'b10110100_1111111111111111101_01100; zero = 0; negative = 0; #10; // CBZ X12, -3
		// Test D-Type
		instruction = 32'b11111000010_000001100_00_01111_00110; zero = 0; negative = 0; #10; // LDUR X6, [X15, #12]
		instruction = 32'b11111000000_000001100_00_01111_00110; zero = 0; negative = 0; #10; // STUR X6, [X15, #12]
	end
endmodule 
*/