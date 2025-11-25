`timescale 1ps/1ps
module zeroChecker (result, isZero);
	input logic [63:0] result;
	output logic isZero;
	
	logic [15:0] zero_check_1; // zero logic
	logic [3:0] zero_check_2;
	
	genvar i;
	generate
		for(i = 0; i < 64; i = i + 4) begin: nor_chain
			or #(50) link0 (zero_check_1[i / 4], result[i], result[i+1], result[i+2], result[i+3]); // or every 4 bits of result
		end
		for(i = 0; i < 16; i = i + 4) begin: nor_chain_1
			or #(50) link1_0 (zero_check_2[i / 4], zero_check_1[i], zero_check_1[i+1], zero_check_1[i+2], zero_check_1[i+3]); // or every 4 of bits of zero_check
		end
	endgenerate
	
	nor #(50) nor1 (isZero, zero_check_2[0], zero_check_2[1], zero_check_2[2], zero_check_2[3]); // nor zero_check_2(contains every bit of result or'd)
endmodule