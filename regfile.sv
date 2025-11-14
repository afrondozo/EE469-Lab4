module regfile(ReadData1, ReadData2, WriteData, 
					 ReadRegister1, ReadRegister2, WriteRegister,
					 RegWrite, clk);
	output logic [63:0] ReadData1, ReadData2;
	input logic [4:0] ReadRegister1, ReadRegister2, WriteRegister;
	input logic [63:0] WriteData;
	input logic RegWrite, clk;
	
	// two 32x64 mux for read out, each takes readreg directly 
	 
	logic [63:0] readOut1, readOut2;
	logic [31:0][63:0] readReg;
	logic [63:0][31:0] readIn;
	logic [31:0] decoderOut;
	
	decoder dec (.out(decoderOut), .addr(WriteRegister));
	
	genvar i, j;
	
	generate
		for (i = 0; i < 31; i = i + 1) begin: regs	// init 32 * 64 bit regs
			register reg0 (.enable(RegWrite && decoderOut[i]), .writeData(WriteData), .readData(readReg[i]), .clk, .rst(1'b0));
		end
		
		for( i = 0; i < 64; i = i + 1) begin: flip	// flip the array to plug columns into mux
			for( j = 0; j < 32; j = j + 1) begin: flip2
				assign readIn[i][j] = readReg[j][i];
			end
		end
		
		for (i = 0; i < 64; i = i + 1) begin: muxes	// init 2 * 64 32x1 muxes
			mux32x1 readone0 (.in(readIn[i]), .out(ReadData1[i]), .s(ReadRegister1));
			mux32x1 readtwo0 (.in(readIn[i]), .out(ReadData2[i]), .s(ReadRegister2));
		end
	endgenerate
	
	// hardcode reg 31
	assign readReg[31] = 64'b0;
endmodule 