`timescale 1ps/1ps

// Handles logical operations (and, nand, or, nor, xor, xnor)
// cntrl			Operation						Notes:
// 000:			result = B						value of overflow and carry_out unimportant
// 010:			result = A + B
// 011:			result = A - B
// 100:			result = bitwise A & B		value of overflow and carry_out unimportant
// 101:			result = bitwise A | B		value of overflow and carry_out unimportant
// 110:			result = bitwise A XOR B	value of overflow and carry_out unimportant
module alu_unit(a, b, result, carry_in, carry_out, ctrl);
	input [2:0] ctrl;
	input a, b, carry_in;
	output result, carry_out;
	
	// logical operations
	logic a_and_b, a_or_b, a_xor_b, b_invert;
	
	and #(50) and1 (a_and_b, a, b);
	or #(50) or1 (a_or_b, a, b);
	xor #(50) xor1 (a_xor_b, a, b);
	
	// adder logic
	logic addResult, subtractResult, carry_out_add, carry_out_sub;
	full_adder add (.a, .b, .c_in(carry_in), .sub(1'b0), .c_out(carry_out_add), .out(addResult));
	full_adder sub (.a, .b, .c_in(carry_in), .sub(1'b1), .c_out(carry_out_sub), .out(subtractResult));
	
	// mux logic for result and carry out
	multiplexer m_2x1 (.a(carry_out_add), .b(carry_out_sub), .s(ctrl[0]), .y(carry_out));
	multiplexer_6to1 m (.PASS(b), .ADD(addResult), .SUBTRACT(subtractResult), 
	.XOR(a_xor_b), .AND(a_and_b), .OR(a_or_b), .ctrl, .out(result));
endmodule

module alu_unit_testbench();
	logic [2:0] ctrl;
	logic a, b, carry_in;
	logic result, carry_out;
	
	alu_unit dut (.a, .b, .result, .ctrl, .carry_in, .carry_out);
	
	initial begin
		for (int i = 0; i < 8; i++) begin
			ctrl = i;#500000;
			for (int j = 0; j < 8; j++) begin
				{a, b, carry_in} = j; #500000;
			end
		end
	end
endmodule