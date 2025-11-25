`timescale 1ns/10ps
module CPUstim ();

	parameter ClockDelay = 20000;

	logic clk, rst;
	
	CPU dut (.clk, .rst);
	
	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end
	
	initial begin
		rst = 1; #20000;
		rst = 0; #20000;
		#10000000;
		//#10000000;
		//#10000000;
		//#10000000;
		$stop;
	end
endmodule 