`timescale 1ps/1ps

module program_counter(address, clk, rst, uncond_br, br_taken, cond_address, br_address);
	input logic clk, rst;
	input logic uncond_br, br_taken;
	input logic [18:0] cond_address;
	input logic [25:0] br_address;
	output logic [63:0] address;
	
	logic [63:0] next_address, current_address, cond_address_se, br_address_se, pre_shift, post_shift, br_adder_out, adder_out;
	
	// register (PC)
	register pc (.enable(1'b1), .writeData(next_address), .readData(current_address), .clk, .rst);
	
	// SIGNED sign extension for branch instruction addresses
	signExtender #(.IN_WIDTH(19)) condBr19  (.in(cond_address), .out(cond_address_se), .SE(1'b1));
	signExtender #(.IN_WIDTH(26)) br26 (.in(br_address), .out(br_address_se), .SE(1'b1));
	
	// next address datapath
	alu adder (.A(current_address), .B(64'h0000000000000004), .cntrl(3'b010), .result(adder_out), .zero(), .negative(), .carry_out(), .overflow());
	alu br_adder (.A(current_address), .B(post_shift), .cntrl(3'b010), .result(br_adder_out), .zero(), .negative(), .carry_out(), .overflow());
	
	// branch datapath
	shifter shifted (.value(pre_shift), .direction(1'b0), .distance(6'd2), .result(post_shift));
	
	// branch datapath muxes
	genvar i;
	generate
		for(i = 0; i < 64; i++) begin: muxes
			multiplexer cond_mux0 (.a(cond_address_se[i]), .b(br_address_se[i]), .s(uncond_br), .y(pre_shift[i]));
			multiplexer branch_mux0 (.a(adder_out[i]), .b(br_adder_out[i]), .s(br_taken), .y(next_address[i]));
		end
	endgenerate	
	
	assign address = current_address;
endmodule

module program_counter_testbench();
	parameter ClockDelay = 5000000;
	
	logic clk, rst;
	logic uncond_br, br_taken;
	logic [18:0] cond_address;
	logic [25:0] br_address;
	logic [63:0] address;
	
	program_counter dut (.address, .clk, .rst, .uncond_br, .br_taken, .cond_address, .br_address);
	
	initial begin
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end
	
	
	initial begin
		cond_address = 19'd1;
		br_address = 26'd2;
		br_taken = 0;
		uncond_br = 1;
		rst = 1; #(ClockDelay);
		rst = 0; #(ClockDelay);
		br_taken = 0; #(ClockDelay);
		br_taken = 0; #(ClockDelay);
		br_taken = 0; #(ClockDelay);
		br_taken = 1; uncond_br = 0; #(ClockDelay);
		br_taken = 1; uncond_br = 1; #(ClockDelay);
		br_taken = 1; uncond_br = 0; #(ClockDelay);
		br_taken = 1; uncond_br = 1; #(ClockDelay);
		br_taken = 1; uncond_br = 0; #(ClockDelay);
		br_taken = 0; uncond_br = 1; #(ClockDelay);
		$stop;
	end
endmodule  