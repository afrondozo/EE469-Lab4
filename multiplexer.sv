`timescale 1ps/1ps
module multiplexer (a, b, s, y); // a is q, b is d for dff
	input logic a, b, s;
	output logic y;
	
	logic s_invert, temp1, temp2;
	not #(50) invert(s_invert, s);
	and #(50) s_not_and_a (temp1, s_invert, a);
	and #(50) s_and_b (temp2, s, b);
	or #(50) temp1_or_temp2 (y, temp1, temp2);
endmodule 
