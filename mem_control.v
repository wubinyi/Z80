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

module mem_control(
	m1,
	mreq,
	//rd,
	wr,
	address,
	pram_ce,
	dram_ce,
	dram_wr
	// m1_o,
	// mreq_o,
	// rd_o,
	// wr_o		
);

input        m1;
input        mreq;
//input        rd;
input        wr;
input [15:0] address;
output       pram_ce;
output       dram_ce;
output       dram_wr;
// output       m1_o;
// output       mreq_o;
// output       rd_o;
// output       wr_o;


parameter PRAM_SIZE = 16'b0000_1111_1111_1111; // 4095
parameter DRAM_SIZE = 16'b0000_0001_1111_1111; // 255

// address judgement 
// flag=false:  use internal memory
// flag=true : use external memory
wire pram_address_judge_flag;
wire dram_address_judge_flag;
assign pram_address_judge_flag = address > PRAM_SIZE;
assign dram_address_judge_flag = address > DRAM_SIZE;

// create signal to control internal memory
assign pram_ce = m1 | mreq | pram_address_judge_flag;
assign dram_ce = (~m1) | mreq | dram_address_judge_flag;
assign dram_wr = mreq | wr;

// output signal
// assign m1_o = m1;
// assign mreq_o = mreq;
// assign rd_o = rd;
// assign wr_o = wr;



endmodule