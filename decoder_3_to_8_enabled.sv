`timescale 1ps/1ps

module decoder_3_to_8_enabled (enable, b2, b1, b0, out);
	input enable, b2, b1, b0;
	output [7:0] out;
	
	logic not_b2, not_b1, not_b0;
	
	not #(50) inv1 (not_b0, b0);
	not #(50) inv2 (not_b1, b1);
	not #(50) inv3 (not_b2, b2);
	
	and #(50) and1 (out[0], not_b0, not_b1, not_b2, enable);
	and #(50) and2 (out[1], b0, not_b1, not_b2, enable);
	and #(50) and3 (out[2], not_b0, b1, not_b2, enable);
	and #(50) and4 (out[3], b0, b1, not_b2, enable);
	and #(50) and5 (out[4], not_b0, not_b1, b2, enable);
	and #(50) and6 (out[5], b0, not_b1, b2, enable);
	and #(50) and7 (out[6], not_b0, b1, b2, enable);
	and #(50) and8 (out[7], b0, b1, b2, enable);
endmodule 