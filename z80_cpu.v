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

module z80_cpu(
	clk,
	reset,
	nmi,
	int,
	data_input,
	data_output_output,
	data_bus_os,
	address,
	m1,
	wr,
	rd,
	mreq,
	iorq,
	halt
);
input clk;
input reset;
input nmi;
input int;
input [7:0] data_input;
//output [7:0] data_output;
output [7:0] data_output_output;
output [7:0] data_bus_os;
output reg [15:0] address;
output reg m1;
output reg wr;
output reg rd;
output reg mreq;
output reg iorq;
output halt; 


//=====================================  fsm  =====================================
wire       fsm_if_en;
wire       fsm_if_pc_modify;
//wire [7:0] if_fsm_instr;
wire       if_fsm_instr_finish;
wire [2:0] if_fsm_num_bytes;

wire       fsm_of_le_en;
//wire       fsm_of_pc_en;
wire       fsm_of_mem_rd;
wire       fsm_of_load_en;
wire       fsm_of_input;
wire [7:0] fsm_of_operation_type;
wire [7:0] fsm_of_des;
wire [7:0] fsm_of_sou;

wire [7:0] ie_fsm_flag_reg;
wire fsm_ie_en;

wire fsm_os_output;
wire fsm_os_mem_wr;
wire fsm_os_IFF2;
wire fsm_os_int;

//=====================================  if  =====================================
wire [15:0] if_of_pc;
//wire        of_if_modify;
wire [15:0] of_if_pc;
wire [31:0] instruction;

//===================================  of_os  ====================================
//----------  opera_fetch  ----------
wire [7:0] of_ie_operand_des;
wire [7:0] of_ie_operand_des_high;
wire [7:0] of_ie_operand_sou;
wire [7:0] of_ie_operand_sou_high;
wire [7:0] of_ie_flag_reg;
wire [4:0] of_ie_operation;

//----------  opera_store  ----------
wire [7:0] ie_os_result;
wire [7:0] ie_os_result_high;
wire [7:0] ie_os_flag_reg;
//wire [7:0] data_output_output;
//wire [7:0] data_bus_os;

//====================================  ie  ======================================

//====================================  address  ======================================
wire [15:0] address_bus_if;
wire [15:0] address_bus_of;
wire [15:0] address_input;
wire [15:0] address_bus_os;
wire [15:0] address_output;


instr_fetch if_0(
	.clk(clk),
	.reset(reset),
	.data_input(data_input),

	.fsm_if_en(fsm_if_en),
	.fsm_if_pc_modify(fsm_if_pc_modify),
	.address_bus_if(address_bus_if),
	//.if_fsm_instr(if_fsm_instr),

	.if_of_pc(if_of_pc),
	.of_if_pc(of_if_pc),

	.if_fsm_num_bytes(if_fsm_num_bytes),
	.if_fsm_instr_finish(if_fsm_instr_finish),
	.instruction(instruction)
);

fsm_control fsm_0(
	.clk(clk),
	.reset(reset),
	.int(int),
	.nmi(nmi),
	.halt_o(halt),

	.fsm_if_en(fsm_if_en),
	//.if_fsm_instr(if_fsm_instr),
	.if_fsm_instr_finish(if_fsm_instr_finish),
	.if_fsm_num_bytes(if_fsm_num_bytes),
	.instruction(instruction),
	
	.ie_fsm_flag_reg(ie_fsm_flag_reg),
	.fsm_of_le_en(fsm_of_le_en),
	.fsm_if_pc_modify(fsm_if_pc_modify),
	.fsm_of_mem_rd(fsm_of_mem_rd),
	.fsm_of_load_en(fsm_of_load_en),
	.fsm_of_input(fsm_of_input),
	.fsm_of_operation_type(fsm_of_operation_type),
	.fsm_of_des(fsm_of_des),
	.fsm_of_sou(fsm_of_sou),	
	.fsm_ie_en(fsm_ie_en),
	.fsm_os_output(fsm_os_output),
	.fsm_os_mem_wr(fsm_os_mem_wr),
	.fsm_os_IFF2(fsm_os_IFF2),
	.fsm_os_int(fsm_os_int)

	//.fsm_mem_bus_int(fsm_mem_bus_int)
);

opera_fetch_opera_store of_os_0(
	.clk(clk),
	.reset(reset),

	.fsm_of_le_en(fsm_of_le_en),
	//.fsm_of_pc_en(fsm_of_pc_en),
	.fsm_of_mem_rd(fsm_of_mem_rd),
	.fsm_of_load_en(fsm_of_load_en),
	.fsm_of_input(fsm_of_input),
	.fsm_of_operation_type(fsm_of_operation_type),
	.fsm_of_des(fsm_of_des),
	.fsm_of_sou(fsm_of_sou),

	.of_ie_operand_des(of_ie_operand_des),
	.of_ie_operand_des_high(of_ie_operand_des_high),
	.of_ie_operand_sou(of_ie_operand_sou),
	.of_ie_operand_sou_high(of_ie_operand_sou_high),
	.of_ie_flag_reg(of_ie_flag_reg),
	.of_ie_operation(of_ie_operation),

	.address_input(address_input),
	.address_bus_of(address_bus_of),
	.data_bus_of(data_input),
	.if_of_pc(if_of_pc),
	.of_if_pc(of_if_pc),

	//.fsm_os_output(fsm_os_output), // unuseful
	.fsm_os_mem_wr(fsm_os_mem_wr),
	.fsm_os_IFF2(fsm_os_IFF2),
	.fsm_os_int(fsm_os_int),
	.ie_os_result(ie_os_result),
	.ie_os_result_high(ie_os_result_high),
	.ie_os_flag_reg(ie_os_flag_reg),
	.address_output(address_output),
	.address_bus_os(address_bus_os),
	.data_output(data_output_output),
	.data_bus_os(data_bus_os)
);

instr_excute ie_0(
	.clk(clk),
	.reset(reset),
	.fsm_ie_en(fsm_ie_en),	
	.of_ie_operand_des(of_ie_operand_des),
	.of_ie_operand_des_high(of_ie_operand_des_high),
	.of_ie_operand_sou(of_ie_operand_sou),
	.of_ie_operand_sou_high(of_ie_operand_sou_high),
	.of_ie_flag_reg(of_ie_flag_reg),
	.of_ie_operation(of_ie_operation),
	.ie_os_result(ie_os_result),
	.ie_os_result_high(ie_os_result_high),
	.ie_os_flag_reg(ie_os_flag_reg),
	.ie_fsm_flag_reg(ie_fsm_flag_reg)
);

//===========================================================================================
//                                     internal bus
//===========================================================================================

//always @(fsm_if_en or fsm_of_mem_rd or fsm_of_input or fsm_os_mem_wr or fsm_os_output) begin
always @* begin
	case({fsm_if_en, fsm_of_mem_rd, fsm_of_input, fsm_os_mem_wr, fsm_os_output})
		5'b10000:begin  // instruction fetch
			iorq = 1'b1;  // IO or memory: not IO
			m1   = 1'b0;  // rom or ram: rom
			wr   = 1'b1;  // not write
			rd   = 1'b0;  // read
			mreq = 1'b0;  // IO or memory: memory
			address = address_bus_if;
		end
		5'b01000:begin  // read ram
			iorq = 1'b1;  // IO or memory: not IO
			m1   = 1'b1;  // rom or ram: ram
			wr   = 1'b1;  // not write
			rd   = 1'b0;  // read
			mreq = 1'b0;  // IO or memory: memory
			address = address_bus_of;
		end
		5'b00100:begin  // IO input-read
			iorq = 1'b0;  // IO or memory: IO
			m1   = 1'b1;  // rom or ram: xx
			wr   = 1'b1;  // not write
			rd   = 1'b0;  // read
			mreq = 1'b1;  // IO or memory: memory
			address = address_input;
		end
		5'b00010:begin  // write ram
			iorq = 1'b1;  // IO or memory: not IO
			m1   = 1'b1;  // rom or ram: ram
			wr   = 1'b0;  // write
			rd   = 1'b1;  // not read
			mreq = 1'b0;  // IO or memory: memory
			address = address_bus_os;
		end
		5'b00001:begin  // IO output-write
			iorq = 1'b0;  // IO or memory: IO
			m1   = 1'b1;  // rom or ram: xx
			wr   = 1'b0;  // write
			rd   = 1'b1;  // not read
			mreq = 1'b1;  // IO or memory: memory
			address = address_output;
		end
		default:begin
			iorq = 1'b1;  // IO or memory: xx
			m1   = 1'b1;  // rom or ram: xx
			wr   = 1'b1;  // write xx
			rd   = 1'b1;  // read  xx
			mreq = 1'b1;  // IO or memory: xx	
			address = 16'h0000;		
		end
	endcase
end

// data control
// wire write_flag;
// wire [7:0] data_output_temp;
// assign write_flag = m1 & (~wr) & rd;
// assign data_output_temp = mreq ? data_output_output : data_bus_os;
// assign data_output = write_flag ? data_output_temp : 8'h00;  // select output data
//assign data_output = iorq ? data_bus_os : data_output_output;  // select output data
//assign data = ~wr ? data_output : 8'hzz;         // output
//assign data_input = data;                   // input

endmodule