// Company           :   tud                      
// Author            :   wubi17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   z80_cpu.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Thu Aug 31 16:21:42 2017 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module z80_tb();

reg clk;
reg reset;
reg nmi;
reg int;
wire [7:0] data;
wire [15:0] address_out;
wire m1_out;
wire wr_out;
wire rd_out;
wire mreq_out;
wire iorq_out;
wire halt_out;

z80 z80_0(
	clk,
	reset,
	nmi,
	int,
	data,
	address_out,
	m1_out,
	wr_out,
	rd_out,
	mreq_out,
	iorq_out,
	halt_out
);

initial begin
	clk <= 1'b0;
	nmi <= 1'b1;
	#20 
	forever #20 clk <= ~clk;
end
initial begin
	reset = 1;
	#10 reset = 0;
	#10 reset = 1;
end

reg int_test;
initial begin
	//int_test <= 1'b0;
	int <= 1'b1;
	# 50620  //# 47340
	int <= 1'b0;
	# 40
	int <= 1'b1;
	// wait(iorq == 0) # 5  int_test <= 1'b1;
	// # 50
	// int_test <= 1'b0;
end
//assign data = ((!iorq && !rd) || (!iorq && int_test))? 8'hff : 8'hzz;       // int mode 2
//assign data = ((!iorq && !rd))? 8'hff : (!iorq && int_test) ? 8'h00 : 8'hzz;  // int mode 0

assign data = ((!iorq_out && !rd_out))? 8'hff : 8'hzz;
endmodule