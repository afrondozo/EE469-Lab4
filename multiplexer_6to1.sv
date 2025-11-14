`timescale 1ps/1ps
module multiplexer_6to1 (PASS, ADD, SUBTRACT, XOR, AND, OR, ctrl, out);
	input logic PASS, ADD, SUBTRACT, XOR, AND, OR;
	input logic [2:0] ctrl;
	output logic out;
	
	logic out1, out2, out3, out4;
	
	multiplexer m1 (.a(PASS), .b(AND), .s(ctrl[2]), .y(out1));
	multiplexer m2 (.a(ADD), .b(XOR), .s(ctrl[2]), .y(out2));
	multiplexer m3 (.a(SUBTRACT), .b(OR), .s(ctrl[2]), .y(out3));
	multiplexer m4 (.a(out1), .b(out2), .s(ctrl[1]), .y(out4));
	multiplexer m5 (.a(out4), .b(out3), .s(ctrl[0]), .y(out));
endmodule

module multiplexer_6to1_testbench();
	logic PASS, ADD, SUBTRACT, XOR, AND, OR;
	logic [2:0] ctrl;
	logic out;
	
	multiplexer_6to1 dut (.PASS, .ADD, .SUBTRACT, .XOR, .AND, .OR, .ctrl, .out);
	
	// a = pass
	// b = +
	// c = -
	// d = xor
	// e = &
	// f = |
	initial begin
		{PASS, ADD, SUBTRACT, XOR, AND, OR} = 6'b100000; ctrl = 3'b000; #1000;
		{PASS, ADD, SUBTRACT, XOR, AND, OR} = 6'b010000; ctrl = 3'b010; #1000;
		{PASS, ADD, SUBTRACT, XOR, AND, OR} = 6'b001000; ctrl = 3'b011; #1000;
		{PASS, ADD, SUBTRACT, XOR, AND, OR} = 6'b000100; ctrl = 3'b110; #1000;
		{PASS, ADD, SUBTRACT, XOR, AND, OR} = 6'b000010; ctrl = 3'b100; #1000;
		{PASS, ADD, SUBTRACT, XOR, AND, OR} = 6'b000001; ctrl = 3'b101; #1000;
	end
endmodule
