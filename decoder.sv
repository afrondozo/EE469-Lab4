module decoder (out, addr);
	input logic [4:0] addr;
	output logic [31:0] out;
	
	logic a,b,c,d,e;
	assign a = addr[4];
	assign b = addr[3];
	assign c = addr[2];
	assign d = addr[1];
	assign e = addr[0];
	
	assign out[0] = ~a & ~b & ~c & ~d & ~e;
	assign out[1] = ~a & ~b & ~c & ~d & e;
	assign out[2] = ~a & ~b & ~c & d & ~e;
	assign out[3] = ~a & ~b & ~c & d & e;
	assign out[4] = ~a & ~b & c & ~d & ~e;
	assign out[5] = ~a & ~b & c & ~d & e;
	assign out[6] = ~a & ~b & c & d & ~e;
	assign out[7] = ~a & ~b & c & d & e;
	assign out[8] = ~a & b & ~c & ~d & ~e;
	assign out[9] = ~a & b & ~c & ~d & e;
	assign out[10] = ~a & b & ~c & d & ~e;
	assign out[11] = ~a & b & ~c & d & e;
	assign out[12] = ~a & b & c & ~d & ~e;
	assign out[13] = ~a & b & c & ~d & e;
	assign out[14] = ~a & b & c & d & ~e;
	assign out[15] = ~a & b & c & d & e;
	assign out[16] = a & ~b & ~c & ~d & ~e;
	assign out[17] = a & ~b & ~c & ~d & e;
	assign out[18] = a & ~b & ~c & d & ~e;
	assign out[19] = a & ~b & ~c & d & e;
	assign out[20] = a & ~b & c & ~d & ~e;
	assign out[21] = a & ~b & c & ~d & e;
	assign out[22] = a & ~b & c & d & ~e;
	assign out[23] = a & ~b & c & d & e;
	assign out[24] = a & b & ~c & ~d & ~e;
	assign out[25] = a & b & ~c & ~d & e;
	assign out[26] = a & b & ~c & d & ~e;
	assign out[27] = a & b & ~c & d & e;
	assign out[28] = a & b & c & ~d & ~e;
	assign out[29] = a & b & c & ~d & e;
	assign out[30] = a & b & c & d & ~e;
	assign out[31] = a & b & c & d & e;
	
endmodule 

module decoder_testbench();

endmodule