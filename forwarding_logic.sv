// Forwarding logic: forward_sel
// 2'b00 = no forwarding
// 2'b01 = forward from ALU
// 2'b10 = forward from memory
module forwarding_logic (IFETCH_instruction, REG_instruction, EXEC_instruction, forward_sel);
	input logic [31:0] IFETCH_instruction, REG_instruction, EXEC_instruction;
	output logic [1:0] forward_sel;
	
	logic forward_from_alu, forward_from_memory;
	logic [4:0] Rn, Rm, Rd, alu_data, mem_data;
	
	always_comb begin
	
//---------------------------------------
// Do we need to forward from the ALU?
//---------------------------------------

		casex(REG_instruction[31:21])
			// B type
			11'b000101XXXXX: forward_from_alu = 1'b0;
			// CB type
			11'b01010100XXX: forward_from_alu = 1'b0;
			11'b10110100XXX: forward_from_alu = 1'b0;
			// R type
			11'b10001010000: forward_from_alu = 1'b1; // we only forward from ALU with R and I types
			11'b10001011000: forward_from_alu = 1'b1;
			11'b10101011000: forward_from_alu = 1'b1;
			11'b11001010000: forward_from_alu = 1'b1;
			11'b11010011010: forward_from_alu = 1'b1;
			11'b11101011000: forward_from_alu = 1'b1;
			// I type
			11'b1001000100X: forward_from_alu = 1'b1;
			// D type
			11'b11111000000: forward_from_alu = 1'b0;
			11'b11111000010: forward_from_alu = 1'b0;
		endcase
		
//---------------------------------------
// Forwarding logic
//---------------------------------------

		casex(IFETCH_instruction[31:21])
			// B type
			11'b000101XXXXX: forward_sel = 2'b00;
			// CB type
			11'b01010100XXX: forward_sel = 2'b00;
			11'b10110100XXX: begin // CBZ: Rd output dependent
										if(forward_from_alu && (Rd == alu_data)) forward_sel = 2'b01;
										else if(forward_from_memory && (Rd == mem_data)) forward_sel = 2'b10;
										else forward_sel = 2'b01;
								  end
			// R type
			11'b10001010000: begin // R-types(excluding LS): Rn Rm output dependent
										if(((Rm == alu_data) | (Rn == alu_data)) && forward_from_alu) forward_sel = 2'b01;
										else if(((Rm == mem_data) | (Rn == mem_data)) && forward_from_memory) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
			11'b10001011000: begin
										if(((Rm == alu_data) | (Rn == alu_data)) && forward_from_alu) forward_sel = 2'b01;
										else if(((Rm == mem_data) | (Rn == mem_data)) && forward_from_memory) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
			11'b10101011000: begin
										if(((Rm == alu_data) | (Rn == alu_data)) && forward_from_alu) forward_sel = 2'b01;
										else if(((Rm == mem_data) | (Rn == mem_data)) && forward_from_memory) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
			11'b11001010000: begin
										if(((Rm == alu_data) | (Rn == alu_data)) && forward_from_alu) forward_sel = 2'b01;
										else if(((Rm == mem_data) | (Rn == mem_data)) && forward_from_memory) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
			11'b11010011010: begin // LS: Rn output dependent
										if(forward_from_alu && (Rn == alu_data)) forward_sel = 2'b01;
										else if(forward_from_memory && (Rn == mem_data)) forward_sel = 2'b10;
										else forward_sel = 2'b01;
								  end
			11'b11101011000: begin // R-types(excluding LS): Rn Rm output dependent
										if(((Rm == alu_data) | (Rn == alu_data)) && forward_from_alu) forward_sel = 2'b01;
										else if(((Rm == mem_data) | (Rn == mem_data)) && forward_from_memory) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
			// I type
			11'b1001000100X: begin // I-types: Rn output dependent
										if(forward_from_alu && (Rn == alu_data)) forward_sel = 2'b01;
										else if(forward_from_memory && (Rn == mem_data)) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
			// D type
			11'b11111000000: begin // D-types: Rn output dependent
										if(forward_from_alu && (Rn == alu_data)) forward_sel = 2'b01;
										else if(forward_from_memory && (Rn == mem_data)) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
			11'b11111000010: begin
										if(forward_from_alu && (Rn == alu_data)) forward_sel = 2'b01;
										else if(forward_from_memory && (Rn == mem_data)) forward_sel = 2'b10;
										else forward_sel = 2'b00;
								  end
		endcase
	end
	
//---------------------------------------
// Do we need to forward from memory?
//---------------------------------------

	assign forward_from_memory = (EXEC_instruction[31:21] == 11'b11111000010); // only forward for LDUR calls
	
//---------------------------------------
// Variable assignment
//---------------------------------------	

	assign Rn = IFETCH_instruction[9:5]; // from op 1 (instruction currently at RF)
	assign Rm = IFETCH_instruction[20:16];
	assign Rd = IFETCH_instruction[4:0];
	assign alu_data = REG_instruction[4:0]; // Rd of op 2 (instruction currently at EX)
	assign mem_data = EXEC_instruction[4:0]; // Rd of op 3 (instruction currently at MEM)
	
endmodule 