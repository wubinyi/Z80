// Company           :   tud                      
// Author            :   wubi17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   data_bus.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Wed Sep  6 14:25:06 2017 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module data_bus(
	m1,
	mreq,
	rd,
	wr,
	cpu_data_input,
	cpu_data_output_output,
	cpu_data_os,

	pram_data,

	dram_input,
	dram_output,

	io_input,
	io_output
	);

input m1;
input mreq;
input rd;
input wr;
output reg [7:0] cpu_data_input;
input  [7:0] cpu_data_output_output;
input  [7:0] cpu_data_os;

input  [7:0] pram_data;

output [7:0] dram_input;
input  [7:0] dram_output;

output [7:0] io_input;
input  [7:0] io_output;

wire io_input_flag;
//assign io_input = cpu_data_output;
assign io_input_flag = m1 & (~wr) & rd & mreq;
assign io_input = io_input_flag ? cpu_data_output_output : 8'h00;
// assign io_input_flag = m1 & (~wr) & rd & mreq;
// assign io = io_input_flag ? io_input : 8'hzz;
// assign io_output = io;

wire dram_input_flag;
assign dram_input_flag = m1 & (~wr) & rd & (~mreq);
assign dram_input = dram_input_flag ? cpu_data_os : 8'h00;

always @(m1 or wr or rd or mreq or pram_data or dram_output or io_output) begin
	case({m1, wr, rd, mreq})
		4'b0100: cpu_data_input = pram_data;
		4'b1100: cpu_data_input = dram_output;
		4'b1101: cpu_data_input = io_output;
		default: cpu_data_input = 8'h00;
	endcase
end

endmodule