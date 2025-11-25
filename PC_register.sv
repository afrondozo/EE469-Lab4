module PC_register (clk, rst, nextPC, currPC);
	input logic clk, rst;
	input logic [63:0] nextPC;
	
	output logic [63:0] currPC;
	
	// register (PC)
	register pc (.enable(1'b1), .writeData(nextPC), .readData(currPC), .clk, .rst);
endmodule 