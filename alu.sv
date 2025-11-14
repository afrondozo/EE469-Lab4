`timescale 1ps/1ps

// Top level module
// cntrl			Operation						Notes:
// 000:			result = B						value of overflow and carry_out unimportant
// 010:			result = A + B
// 011:			result = A - B
// 100:			result = bitwise A & B		value of overflow and carry_out unimportant
// 101:			result = bitwise A | B		value of overflow and carry_out unimportant
// 110:			result = bitwise A XOR B	value of overflow and carry_out unimportant

module alu (A, B, cntrl, result, negative, zero, overflow, carry_out);
	input [63:0] A, B;
	input [2:0] cntrl;
	output [63:0] result;
	output negative, zero, overflow, carry_out;
	
	logic [64:0] c; // carry logic
	assign c[0] = cntrl[0];	// initial carry in for 2's comp
	
	// generate alu's
	genvar i;
	generate
		for (i = 0; i < 64; i++) begin: alu_chain
			alu_unit ALU (.a(A[i]), .b(B[i]), .result(result[i]), .carry_in(c[i]), .carry_out(c[i+1]), .ctrl(cntrl));
		end
	endgenerate
	
		
	// flag logic	
	assign carry_out = c[64];
	assign negative = result[63];
	xor #(50) xor1 (overflow, c[63], c[64]); // overflow logic
	
	logic [15:0] zero_check_1; // zero logic
	logic [3:0] zero_check_2;
	
	generate
		for(i = 0; i < 64; i = i + 4) begin: nor_chain
			or #(50) link0 (zero_check_1[i / 4], result[i], result[i+1], result[i+2], result[i+3]); // or every 4 bits of result
		end
		for(i = 0; i < 16; i = i + 4) begin: nor_chain_1
			or #(50) link1_0 (zero_check_2[i / 4], zero_check_1[i], zero_check_1[i+1], zero_check_1[i+2], zero_check_1[i+3]); // or every 4 of bits of zero_check
		end
	endgenerate
	
	nor #(50) nor1 (zero, zero_check_2[0], zero_check_2[1], zero_check_2[2], zero_check_2[3]); // nor zero_check_2(contains every bit of result or'd)
	
endmodule 