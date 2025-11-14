`timescale 1ps/1ps

// Handles mathematic operations (add & subtract)

module full_adder(a, b, c_in, sub, c_out, out);
	input a, b, c_in, sub;
	output out, c_out;
	
	// output logic
	logic not_b, sel_b;

	not #(50) inv1 (not_b, b);
	xor #(50) xor1 (out, sel_b, a, c_in);
	
	multiplexer mux_sub (.a(b), .b(not_b), .s(sub), .y(sel_b));
	
	// carry out logic
	logic c_in_and_a, c_in_and_b, a_and_b;
	
	and #(50) and1 (c_in_and_b, sel_b, c_in);
	and #(50) and2 (c_in_and_a, a, c_in);
	and #(50) and3 (a_and_b, sel_b, a);
	or #(50) or1 (c_out, c_in_and_b, c_in_and_a, a_and_b);
endmodule 

module full_adder_tb();
	logic a, b, c_in, sub;
	logic out, c_out;
	
	full_adder dut(.a, .b, .c_in, .sub, .out, .c_out);
	
	initial begin
		sub = 0; #500;
		for(int i = 0; i < 8; i = i + 1) begin
			{a, b, c_in} = i; #500;
		end
		sub = 1; #500;
		for(int i = 0; i < 8; i = i + 1) begin
			{a, b, c_in} = i; #500;
		end
	end
endmodule 