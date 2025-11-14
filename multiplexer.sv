module multiplexer (a, b, s, y); // a is q, b is d for dff
	input logic a, b, s;
	output logic y;
	
	assign y = (~s & a) + (s & b);
endmodule 
