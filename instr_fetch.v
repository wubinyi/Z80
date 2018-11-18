// Company           :   tud                      
// Author            :   wubi17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   instr_fetch.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Thu Aug 31 11:13:04 2017 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module instr_fetch(
	clk,
	reset,
	data_input,

	fsm_if_en,
	fsm_if_pc_modify,
	address_bus_if,
	//if_fsm_instr,

	if_of_pc,
	of_if_pc,

	if_fsm_num_bytes,
	if_fsm_instr_finish,
	instruction
);

input clk;
input reset;
input [7:0] data_input;

input fsm_if_en;
input fsm_if_pc_modify;
output reg [15:0] address_bus_if;
//output reg [7:0] if_fsm_instr;

input [15:0] of_if_pc;
output reg [15:0] if_of_pc;

output reg if_fsm_instr_finish;
output reg [2:0] if_fsm_num_bytes;
output reg [31:0] instruction;

//==================================================================================================================================
//                  clock counter
//==================================================================================================================================
reg clock_counter;
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		clock_counter <= 1'b0;
	end
	else if(fsm_if_en) begin
		clock_counter <= ~clock_counter;
	end
end

//==================================================================================================================================
//                  pc register
//==================================================================================================================================
reg [15:0] pc;

reg [15:0] pc_plus;
// always @(pc) begin
// 	pc_plus = pc + 16'h0001;
// end
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		pc_plus <= 16'h0000;
	end
	else if ((clock_counter == 1'b1) && (fsm_if_en == 1'b1)) begin
		pc_plus <= pc + 16'h0001;
	end 
	else if(fsm_if_pc_modify) begin
		pc_plus <= of_if_pc;
	end
end

// always @(posedge clk or negedge reset) begin
// 	if (!reset) begin
// 		pc <= 16'h0000;
// 	end
// 	else if (fsm_if_pc_modify) begin
// 		pc <= of_if_pc;
// 	end 
// 	else if ((clock_counter == 1'b0) && (fsm_if_en == 1'b1)) begin
// 		pc <= pc_plus;
// 	end
// end
always @* begin
	case(fsm_if_pc_modify)
		1'b1: pc = of_if_pc;
		1'b0: pc = pc_plus;
	endcase
end

always @(posedge clk or negedge reset) begin
	if (!reset) begin
		if_of_pc <= 16'h0000;
	end
	else begin
		if_of_pc <= pc;
	end
end

//==================================================================================================================================
//                  read from memory one byte
//==================================================================================================================================

always @(pc) begin
	address_bus_if = pc;
end
// always @(posedge clk or negedge reset) begin
// 	if (!reset) begin
// 		address_bus_if <= 16'h0000;
// 	end
// 	else begin
// 		address_bus_if = pc;
// 	end
// end

// always @(posedge clk or negedge reset) begin
// 	if (!reset) begin
// 		if_fsm_instr <= 8'h00;
// 	end
// 	else if(clock_counter  == 1'b1) begin
// 		if_fsm_instr <= data_input;
// 	end
// end

//==================================================================================================================================
//            judge the number of bytes (every instruction)
//==================================================================================================================================
reg [2:0] fetch_stage;
parameter FETCH_INST                   = 3'b000;
parameter TWO_BYTE_INST                = 3'b001;
parameter THRER_BYTE_INST_TEMP         = 3'b010;
parameter THRER_BYTE_INST              = 3'b011;
parameter FOUR_BYTE_INST_1             = 3'b100;
parameter FOUR_BYTE_INST_2             = 3'b101;
parameter TWO_BYTE_INST_OR_MORE        = 3'b110;

always @(posedge clk or negedge reset) begin
	if (!reset) begin
		fetch_stage <= FETCH_INST;
		if_fsm_instr_finish <= 1'b0;
		if_fsm_num_bytes <= 3'b0;
		instruction <= 32'h00000000;
	end
	else if(clock_counter  == 1'b1) begin
		case(fetch_stage)
			FETCH_INST:begin
				if_fsm_num_bytes <= 3'd1;
				instruction[7:0] <= data_input;
				instruction[31:8] <= 24'h000000;
				case(data_input)
					8'h3e, 8'h06, 8'h0e, 8'h16, 8'h1e, 8'h26, 8'h2e, 8'h36,
					8'hc6, 8'hce, 8'hd6, 8'hde, 8'he6, 8'hee, 8'hf6, 8'hfe,
					8'hcb, 8'h18, 8'h20, 8'h28, 8'h30, 8'h38, 8'h10, 8'hd3,
					8'hdb: begin // 2 bytes
						fetch_stage <= TWO_BYTE_INST;
						if_fsm_instr_finish <= 1'b0;
					end
					8'hdd, 8'hfd, 8'hed:begin                      // 2 bytes or 3 bytes or 4 bytes
						fetch_stage <= TWO_BYTE_INST_OR_MORE;
						if_fsm_instr_finish <= 1'b0;
					end
					8'h32, 8'h3a, 8'h01, 8'h11, 8'h21, 8'h31, 8'h22, 8'h2a,
					8'hc3, 8'hc2, 8'hca, 8'hd2, 8'hda, 8'he2, 8'hea, 8'hf2, 8'hfa,
					8'hcd, 8'hc4, 8'hcc, 8'hd4, 8'hdc, 8'he4, 8'hec, 8'hf4, 8'hfc: begin        // 3 bytes
						fetch_stage <= THRER_BYTE_INST_TEMP;
						if_fsm_instr_finish <= 1'b0;
					end
					default: begin                                                // 1 bytes
						if_fsm_instr_finish <= 1'b1;
						fetch_stage <= FETCH_INST;
					end
				endcase	
			end
			TWO_BYTE_INST :begin
				if_fsm_num_bytes <= 3'd2;
				instruction[15:8] <= data_input;
				if_fsm_instr_finish <= 1'b1;
				fetch_stage <= FETCH_INST;
			end		
			TWO_BYTE_INST_OR_MORE:begin
				if_fsm_num_bytes <= 3'd2;
				instruction[15:8] <= data_input;
				case(data_input)
					8'h57, 8'h5f, 8'h47, 8'h4f, 8'he1, 8'he5, 8'hf9, 8'he3,
					8'h09, 8'h19, 8'h29, 8'h39, 8'h4a, 8'h5a, 8'h6a, 8'h7a,
					8'h42, 8'h52, 8'h62, 8'h23, 8'h2b, 8'h44,  // 8'h72 belong to 72ed(16bit-alu) or 72cb(bit-manipulation)
					8'h6f, 8'h67, 8'he9, 8'h4d, 8'h45,
					8'h40, 8'h48, 8'h50, 8'h58, 8'h60, 8'h68, 8'h78, 8'ha2, 8'hb2, 8'haa, 8'hba, // input group
					8'h41, 8'h49, 8'h51, 8'h59, 8'h61, 8'h69, 8'h79, 8'ha3, 8'hb3, 8'hab, 8'hbb, // output group
					8'ha0, 8'hb0, 8'ha8, 8'hb8,                                                  //block transfer group
					8'ha1, 8'hb1, 8'ha9, 8'hb9:begin   // 2 bytes                                //block search group
					//8'h46, 8'h56, 8'h5e:begin //cpu control: set int mode: belong to xxed(2 bytes)
						if_fsm_instr_finish <= 1'b1;
						fetch_stage <= FETCH_INST;
					end
					8'h7e, 8'h4e, 8'h66, 8'h6e,            //8'h5e, 8'h56, 8'h46, 
					8'h77, 8'h70, 8'h71, 8'h73, 8'h74, 8'h75,  //8'h72, 
					8'h86, 8'h8e, 8'h96, 8'h9e, 8'ha6, 8'hae,
					8'hb6, 8'hbe, 8'h34, 8'h35:begin // 3 bytes
						if_fsm_instr_finish <= 1'b0;
						fetch_stage <= THRER_BYTE_INST;
					end
					8'h72, 8'h46, 8'h56, 8'h5e:begin
						if(instruction[7:0] == 8'hed)begin    // 72ed, 46ed, 56ed, 5eed  -> 2 bytes
							if_fsm_instr_finish <= 1'b1;
							fetch_stage <= FETCH_INST;							
						end
						else begin                            // xx72dd, xx46dd, xx56dd, xx5edd  -> 3 bytes
							if_fsm_instr_finish <= 1'b0;      // xx72fd, xx46fd, xx56fd, xx5efd  -> 3 bytes
							fetch_stage <= THRER_BYTE_INST;							
						end
					end
					default:begin
						if_fsm_instr_finish <= 1'b0;
						fetch_stage <= FOUR_BYTE_INST_1;	              // 4 bytes				
					end
				endcase		
			end	
			THRER_BYTE_INST_TEMP:begin
				if_fsm_num_bytes <= 3'd2;
				instruction[15:8] <= data_input;
				if_fsm_instr_finish <= 1'b0;
				fetch_stage <= THRER_BYTE_INST;
			end
			THRER_BYTE_INST:begin
				if_fsm_num_bytes <= 3'd3;
				instruction[23:16] <= data_input;
				if_fsm_instr_finish <= 1'b1;
				fetch_stage <= FETCH_INST;
			end
			FOUR_BYTE_INST_1:begin
				if_fsm_num_bytes <= 3'd3;
				instruction[23:16] <= data_input;
				if_fsm_instr_finish <= 1'b0;
				fetch_stage <= FOUR_BYTE_INST_2;
			end
			FOUR_BYTE_INST_2:begin
				if_fsm_num_bytes <= 3'd4;
				instruction[31:24] <= data_input;
				if_fsm_instr_finish <= 1'b1;
				fetch_stage <= FETCH_INST;
			end
			default:begin
				if_fsm_num_bytes <= 3'd0;
				instruction <= 32'h00000000;
				if_fsm_instr_finish <= 1'b0;
				fetch_stage <= FETCH_INST;				
			end
		endcase			
	end
	else if(fsm_if_en == 1'b0) begin
		//if_fsm_num_bytes <= 3'd0;   need to keep until next instruction
		//instruction <= 32'h00000000;  need to keep until next instruction
		if_fsm_instr_finish <= 1'b0;  
		fetch_stage <= FETCH_INST;
	end
end

endmodule