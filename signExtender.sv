`timescale 1ps/1ps

module signExtender 
	#(parameter IN_WIDTH)
	(in, out, SE);	
	
	input logic [IN_WIDTH-1:0] in;
	input logic SE;
	output logic [63:0] out;
	
	genvar i;
	generate
		for (i = 63; i > IN_WIDTH-1; i--) begin: extendSign
			and #(50) signExtended (out[i], SE, in[IN_WIDTH-1]);
		end
		
		for (i = 0; i < IN_WIDTH; i++) begin: originalBits
			assign out[i] = in[i];
		end
	endgenerate
endmodule 