module multiplexer_3to1 (a, b, c, out, sel);
	input logic a, b, c;
	input logic [1:0] sel;
	output logic out;
	
	logic temp;
	
	multiplexer m1 (.a, .b, .s(sel[0]), .y(temp));
	multiplexer m2 (.a(temp), .b(c), .s(sel[1]), .y(out));
endmodule 