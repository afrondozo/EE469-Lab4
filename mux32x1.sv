module mux32x1(in, out, s);
	input logic [31:0] in;
	input logic [4:0] s;
	output logic out;
	
	genvar i;
	
	logic [15:0] fourth;
	logic [7:0] third;
	logic [3:0] second;
	logic [1:0] first;
	
	generate
		for (i = 0; i < 16; i = i + 1) begin: fourthbit // most significant
			multiplexer muxfourth0 (.a(in[i]), .b(in[i+16]), .s(s[4]), .y(fourth[i])); 
		end
		for (i = 0; i < 8; i = i + 1) begin: thirdbit
			multiplexer muxthird0 (.a(fourth[i]), .b(fourth[i+8]), .s(s[3]), .y(third[i])); 
		end
		for (i = 0; i < 4; i = i + 1) begin: secondbit
			multiplexer muxsecond0 (.a(third[i]), .b(third[i+4]), .s(s[2]), .y(second[i]));
		end
		for (i = 0; i < 2; i = i + 1) begin: firstbit
			multiplexer muxfirst0 (.a(second[i]), .b(second[i+2]), .s(s[1]), .y(first[i]));
		end
	endgenerate
	
	multiplexer muxfinal (.a(first[0]), .b(first[1]), .s(s[0]), .y(out)); // least significant
endmodule 