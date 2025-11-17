// 64 bit register
module register (enable, writeData, readData, clk, rst);
	input logic enable, clk, rst;
	input logic [63:0] writeData;
	output logic [63:0] readData;
	
	logic [63:0] q, y;
	
	genvar i;
	
	generate 
		for (i = 0; i < 64; i = i + 1) begin: regs
			multiplexer mux0 (.a(q[i]), .b(writeData[i]), .s(enable), .y(y[i])); // create muxes to handle enable
			D_FF reg0 (.q(q[i]), .d(y[i]), .reset(rst), .clk); // create module with an enabled input
		end
	endgenerate
	
	assign readData = q;
endmodule 