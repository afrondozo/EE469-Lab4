`timescale 1ns/10ps
module CPUstim ();

	parameter ClockDelay = 10000;

	logic clk, rst;
	
	CPU dut (.clk, .rst);
	
	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end
	
	initial begin
		rst = 1; #10000;
		rst = 0; #10000;
		#10000000;
		#300000;
		$stop;
	end
endmodule 