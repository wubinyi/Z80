// Company           :   tud                      
// Author            :   wubi17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   opera_fetch_opera_store.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Thu Aug 31 12:47:38 2017 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module opera_fetch_opera_store(
	clk,
	reset,
	//----------  opera_fetch  ----------
	fsm_of_le_en,
	//fsm_of_pc_en,
	fsm_of_mem_rd,
	fsm_of_load_en,
	fsm_of_input,
	fsm_of_operation_type,
	fsm_of_des,
	fsm_of_sou,

	of_ie_operand_des,
	of_ie_operand_des_high,
	of_ie_operand_sou,
	of_ie_operand_sou_high,
	of_ie_flag_reg,
	of_ie_operation,

	address_input,
	address_bus_of,
	data_bus_of,
	if_of_pc,
	of_if_pc,

	//----------  opera_store  ----------
	//fsm_os_output, // unuseful
	fsm_os_mem_wr,
	fsm_os_IFF2,
	fsm_os_int,
	ie_os_result,
	ie_os_result_high,
	ie_os_flag_reg,
	address_output,
	address_bus_os,
	data_output,
	data_bus_os
);
// signal from system
input clk;
input reset;
//----------  opera_fetch  ----------
// signal from fsm_control
input fsm_of_le_en;
//input fsm_of_pc_en;
input fsm_of_mem_rd;
input fsm_of_load_en;
input fsm_of_input;
input [7:0] fsm_of_operation_type;
input [7:0] fsm_of_des;
input [7:0] fsm_of_sou;
// signal to instr_excute
output reg [7:0] of_ie_operand_des;
output reg [7:0] of_ie_operand_des_high;
output reg [7:0] of_ie_operand_sou;
output reg [7:0] of_ie_operand_sou_high;
output reg [7:0] of_ie_flag_reg;
output reg [4:0] of_ie_operation;
// signal to bus and memery
output reg [15:0] address_input;
output reg [15:0] address_bus_of;
input [7:0] data_bus_of;
// signal connect with if
input [15:0] if_of_pc;
output reg [15:0] of_if_pc;
//----------  opera_store  ----------
// signal from fsm_control
//input fsm_os_output;
input fsm_os_mem_wr;
input fsm_os_IFF2;
input fsm_os_int;
// signal from ie
input [7:0] ie_os_result;
input [7:0] ie_os_result_high;
input [7:0] ie_os_flag_reg;
// signal to bus and memery
output reg [15:0] address_output;
output reg [15:0] address_bus_os;
output reg [7:0] data_output;
output reg [7:0] data_bus_os;


//======================= registers =======================
reg [7:0] A;  // 0
reg [7:0] B;  // 1
reg [7:0] C;  // 2
reg [7:0] D;  // 3
reg [7:0] E;  // 4
reg [7:0] F;  // 5
reg [7:0] H;  // 6
reg [7:0] L;  // 7
reg [7:0] I;  // 8
reg [7:0] R;  // 9
reg [15:0] IX; // 10,A
reg [15:0] IY; // 11,B
reg [15:0] SP; // 12,C
reg [7:0] A_SKIM;  // 13,D
reg [7:0] B_SKIM;  // 14,E
reg [7:0] C_SKIM;  // 15,F
reg [7:0] D_SKIM;  // 16,10
reg [7:0] E_SKIM;  // 17,11
reg [7:0] F_SKIM;  // 18,12
reg [7:0] H_SKIM;  // 19,13
reg [7:0] L_SKIM;  // 20,14


always @* begin
	of_ie_flag_reg = F;
end

//======================= internal registers =======================
// input
reg [7:0] io_fetch_data;
// memory read block
reg [7:0] mem_fetch_data;
reg [7:0] mem_fetch_data_high;  // use for the 2nd byte of 16 bits
// register load and exchange
//reg [7:0] reg_load_temp;// the register can only write in "load and exchange always module"
//reg [7:0] reg_load_temp_high; // the register can only write in "load and exchange always module"
// load to ie
reg [7:0] ie_result_backup;
reg [7:0] ie_result_high_backup;

// OF operation types table
//=======================  load instruction =======================
//parameter NO_FUNCTION                = 8'd0;
// load: one byte
parameter LOAD_REG2REG               = 8'd1;
parameter LOAD_MEM2REG_REG_IND_HL    = 8'd2;
parameter LOAD_MEM2REG_REG_IND_BC    = 8'd3;            
parameter LOAD_MEM2REG_REG_IND_DE    = 8'd4;
parameter LOAD_REG2MEM_REG_IND_HL    = 8'd5;
parameter LOAD_REG2MEM_REG_IND_BC    = 8'd6;
parameter LOAD_REG2MEM_REG_IND_DE    = 8'd7;
// load: two byte
parameter LOAD_REG2IMP               = 8'd8;
parameter LOAD_IMP2REG               = 8'd9;
parameter LOAD_IMM2REG               = 8'd10;
parameter LOAD_IMM2MEM_REG_IND       = 8'd11;
// load: three byte
parameter LOAD_MEM2REG_INDEXED_IX    = 8'd12;
parameter LOAD_MEM2REG_INDEXED_IY    = 8'd13;
parameter LOAD_REG2MEM_INDEXED_IX    = 8'd14;
parameter LOAD_REG2MEM_INDEXED_IY    = 8'd15;
parameter LOAD_MEM2REG_EXT           = 8'd16;
parameter LOAD_REG2MEM_EXT           = 8'd17;
// load: four byte
parameter LOAD_IMM2MEM_INDEXED_IX    = 8'd18;
parameter LOAD_IMM2MEM_INDEXED_IY    = 8'd19;
//=======================  16-bit load instruction =======================
parameter LOAD_16_BIT_HL2SP          = 8'd20;
parameter LOAD_16_BIT_IX2SP          = 8'd21;
parameter LOAD_16_BIT_IY2SP		     = 8'd22;
parameter LOAD_16_BIT_IMM2BC         = 8'd23;
parameter LOAD_16_BIT_IMM2DE         = 8'd24;
parameter LOAD_16_BIT_IMM2HL         = 8'd25;
parameter LOAD_16_BIT_IMM2SP         = 8'd26;
parameter LOAD_16_BIT_IMM2IX         = 8'd27;
parameter LOAD_16_BIT_IMM2IY         = 8'd28;
parameter LOAD_16_BIT_MEM2BC_EXT     = 8'd29;
parameter LOAD_16_BIT_MEM2DE_EXT     = 8'd30;
parameter LOAD_16_BIT_MEM2HL_EXT     = 8'd31;
parameter LOAD_16_BIT_MEM2SP_EXT     = 8'd32;
parameter LOAD_16_BIT_MEM2IX_EXT     = 8'd33;
parameter LOAD_16_BIT_MEM2IY_EXT     = 8'd34;
parameter LOAD_16_BIT_BC2MEM_EXT     = 8'd35;
parameter LOAD_16_BIT_DE2MEM_EXT     = 8'd36;
parameter LOAD_16_BIT_HL2MEM_EXT     = 8'd37;
parameter LOAD_16_BIT_SP2MEM_EXT     = 8'd38;
parameter LOAD_16_BIT_IX2MEM_EXT     = 8'd39;
parameter LOAD_16_BIT_IY2MEM_EXT     = 8'd40;
parameter PUSH                       = 8'd41;
parameter POP                        = 8'd42;
parameter REG_AF                     = 8'd1;   // fsm_of_sou, fsm_of_des
parameter REG_BC                     = 8'd2;   // fsm_of_sou, fsm_of_des
parameter REG_DE                     = 8'd3;   // fsm_of_sou, fsm_of_des
parameter REG_HL                     = 8'd4;   // fsm_of_sou, fsm_of_des
parameter REG_IX                     = 8'd5;   // fsm_of_sou, fsm_of_des
parameter REG_IY                     = 8'd6;   // fsm_of_sou, fsm_of_des
//=======================  exchange instruction(16-bits) =======================
parameter EX_AF                      = 8'd43;
parameter EX_BC_DE_HL                = 8'd44;
parameter EX_HL_AND_DE               = 8'd45;
parameter EX_HL_AND_MEM_SP           = 8'd46;
parameter EX_IX_AND_MEM_SP           = 8'd47;
parameter EX_IY_AND_MEM_SP           = 8'd48;
//======================= arithmetic 8-bit =======================
parameter OE_REG                     = 8'd49;
parameter OE_MEM_HL                  = 8'd50;
parameter OE_MEM_HL_MEM              = 8'd51;
parameter OE_MEM_INDEX_IX            = 8'd52;
parameter OE_MEM_INDEX_IY            = 8'd53;
parameter OE_MEM_INDEX_MEM_IX        = 8'd54;
parameter OE_MEM_INDEX_MEM_IY        = 8'd55;
parameter OE_IMM                     = 8'd56;
//parameter ADD_OP                     = 8'd1;  // alu operation  
//parameter ADC_OP                     = 8'd2;  // alu operation  
//parameter SUB_OP                     = 8'd3;  // alu operation  
//parameter SBC_OP                     = 8'd4;  // alu operation  
//parameter AND_OP                     = 8'd5;  // alu operation  
//parameter XOR_OP                     = 8'd6;  // alu operation  
//parameter OR_OP                      = 8'd7;  // alu operation  
//parameter OP_OP                      = 8'd8;  // alu operation  
parameter INC_OP                     = 8'd9;  // alu operation  
parameter DEC_OP                     = 8'd10; // alu operation  
//======================= arithmetic 16-bit =======================
parameter OE_ADD_16_BIT              = 8'd57;
parameter OE_ADC_16_BIT              = 8'd58;
parameter OE_SBC_16_BIT              = 8'd59;
parameter OE_INC_16_BIT              = 8'd60;
parameter OE_DEC_16_BIT              = 8'd61;
parameter REG_SP                     = 8'd7;    // fsm_of_sou, fsm_of_des
//======================= Gerneral AF Operation =======================
parameter OE_CPL                     = 8'd62;
parameter OE_NEG                     = 8'd63;
parameter OE_CCF                     = 8'd64;
parameter OE_SCF                     = 8'd65;
//======================= Rotates and Shift =======================
parameter RS_REG_A                   = 8'd66;   
parameter RS_REG                     = 8'd67;
parameter RS_MEM_HL                  = 8'd68;
parameter RS_MEM_INDEX_IX            = 8'd69;
parameter RS_MEM_INDEX_IY            = 8'd70;
parameter RLC                        = 8'd17;  // alu operation  
parameter RRC                        = 8'd18;  // alu operation  
parameter RL                         = 8'd19;  // alu operation  
parameter RR                         = 8'd20;  // alu operation  
//parameter SLA_OP                     = 8'd21;  // alu operation  
//parameter SRA_OP                     = 8'd22;  // alu operation  
//parameter SRL_OP                     = 8'd23;  // alu operation  
parameter RLD_OP                     = 8'd24;  // alu operation  
parameter RRD_OP                     = 8'd25;  // alu operation  
//======================= bit manipulation =======================
parameter BM_SET                     = 8'd71;
parameter BM_RESET                   = 8'd72;
parameter BM_TEST                    = 8'd73;
parameter BM_SET_RESET_MEM_HL        = 8'd74;
parameter BM_TEST_MEM_HL             = 8'd75;
parameter BM_SET_MEM_IX              = 8'd76;
parameter BM_RESET_MEM_IX            = 8'd77;
parameter BM_TEST_MEM_IX             = 8'd78;
parameter BM_SET_MEM_IY              = 8'd79;
parameter BM_RESET_MEM_IY            = 8'd80;
parameter BM_TEST_MEM_IY             = 8'd81;
//parameter SET_BIT                    = 8'd26; // alu operation  
//parameter RESET_BIT                  = 8'd27; // alu operation  
//parameter TEST_BIT                   = 8'd28; // alu operation  
//======================= jump, call, return, reset =======================   
//parameter NO_JUMP                    = 8'd82;  // function_sel
parameter JUMP_IMM                   = 8'd83;
parameter JUMP_REG_IND               = 8'd84;
parameter JUMP_RELATIVE              = 8'd85;
parameter JUMP_DJNZ                  = 8'd86;
//parameter NO_CALL                    = 8'd87;  // function_sel
parameter CALL                       = 8'd88;
//parameter NO_RETURN                  = 8'd89;  // function_sel
parameter RETURN_FUNC                     = 8'd90;
parameter RST                        = 8'd91;
//======================= input group =======================
parameter IN_MEM_EXTEND              = 8'd92;
parameter IN_MEM_REG_IND             = 8'd93;
parameter INI                        = 8'd94;
parameter INIR                       = 8'd95;
parameter IND                        = 8'd96;
parameter INDR                       = 8'd97;
//======================= output group ======================= 
parameter OUT_MEM_EXTEND             = 8'd98;
parameter OUT_MEM_REG_IND            = 8'd99;
parameter OUTI                       = 8'd100;
parameter OTIR                       = 8'd101;
parameter OUTD                       = 8'd102;
parameter OTDR                       = 8'd103;
//======================= block transfer group ======================= 
parameter LDI                        = 8'd104;
parameter LDIR                       = 8'd105;
parameter LDD                        = 8'd106;
parameter LDDR                       = 8'd107;
//======================= block search group =======================
parameter CPI                        = 8'd108;
parameter CPIR                       = 8'd109;
parameter CPD                        = 8'd110;
parameter CPDR                       = 8'd111;
//======================= CPU control =======================
//parameter NOP                        = 8'd112;  // function_sel
//parameter HALT                       = 8'd113;  // function_sel
//parameter DINT                       = 8'd114;  // function_sel
//parameter EINT                       = 8'd115;  // function_sel
//parameter IM0                        = 8'd116;
//parameter IM1                        = 8'd117;
//parameter IM2                        = 8'd118;
//========================= interrupt =========================
parameter NMI_INTERRUPT              = 8'd119;  
parameter INTERRUPT_MODE_0           = 8'd120;
parameter INTERRUPT_MODE_1           = 8'd121;
parameter INTERRUPT_MODE_2           = 8'd122;
//========================= RETI RETN ========================= 
parameter RETI                       = 8'd123;
parameter RETN                       = 8'd124;   


//=================================================================
//                  read one/two byte from data memory
//=================================================================

// read memory data
reg of_byte_counter;
reg mem_read_clock_counter;
// always @ (posedge clk or negedge reset) begin
// 	if (!reset) begin
// 		mem_fetch_data <= 8'b0;
// 		mem_fetch_data_high <= 8'b0;
// 		of_byte_counter <= 1'b0;
// 		mem_read_clock_counter <= 1'b0;
// 	end
// 	else if(fsm_of_mem_rd) begin
// 		case(mem_read_clock_counter)
// 			1'b0:begin
// 				mem_read_clock_counter <= 1'b1;
// 			end
// 			1'b1:begin
// 				mem_read_clock_counter <= 1'b0;
// 				case(of_byte_counter)
// 					1'b0: mem_fetch_data <= data_bus_of;
// 					1'b1: mem_fetch_data_high <= data_bus_of;
// 				endcase
// 				case(fsm_of_operation_type) // use for 16-bit data.
// 					LOAD_16_BIT_MEM2DE_EXT, LOAD_16_BIT_MEM2HL_EXT, LOAD_16_BIT_MEM2SP_EXT, 
// 					LOAD_16_BIT_MEM2IX_EXT, LOAD_16_BIT_MEM2IY_EXT, LOAD_16_BIT_MEM2BC_EXT,
// 					POP, EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP, EX_IY_AND_MEM_SP, RETURN_FUNC, RETI,
// 					RETN:begin
// 						case(of_byte_counter)
// 							1'b0: of_byte_counter <= 1'b1;
// 							1'b1: of_byte_counter <= 1'b0;
// 						endcase
// 					end
// 					default: of_byte_counter <= 1'b0;
// 				endcase
// 			end
// 		endcase
// 	end
// end
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		mem_read_clock_counter <= 1'b0;	
	end
	else if (fsm_of_mem_rd) begin
		mem_read_clock_counter <= ~mem_read_clock_counter;
	end
end
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		of_byte_counter <= 1'b0;
	end
	else if (mem_read_clock_counter) begin
		case(fsm_of_operation_type) // use for 16-bit data.
			LOAD_16_BIT_MEM2DE_EXT, LOAD_16_BIT_MEM2HL_EXT, LOAD_16_BIT_MEM2SP_EXT, 
			LOAD_16_BIT_MEM2IX_EXT, LOAD_16_BIT_MEM2IY_EXT, LOAD_16_BIT_MEM2BC_EXT,
			POP, EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP, EX_IY_AND_MEM_SP, RETURN_FUNC, RETI,
			RETN:begin
				case(of_byte_counter)
					1'b0: of_byte_counter <= 1'b1;
					1'b1: of_byte_counter <= 1'b0;
				endcase
			end
			default: of_byte_counter <= 1'b0;
		endcase		
	end
end

always @ (posedge clk or negedge reset) begin
	if (!reset) begin
		mem_fetch_data <= 8'b0;
		mem_fetch_data_high <= 8'b0;
		//of_byte_counter <= 1'b0;
		//mem_read_clock_counter <= 1'b0;
	end
	else if(mem_read_clock_counter) begin
		case(of_byte_counter)
			1'b0: mem_fetch_data <= data_bus_of;
			1'b1: mem_fetch_data_high <= data_bus_of;
		endcase
	end
end


// place address
wire of_byte_order;
//assign of_byte_order = of_byte_counter ^ mem_read_clock_counter;
assign of_byte_order = of_byte_counter; // ^ mem_read_clock_counter;  useless
//always @ (posedge clk or negedge reset) begin
always @* begin
	//if (!reset) begin
	//	address_bus_of <= 16'b0;
	//end
	//else begin
		case(fsm_of_operation_type)
			LOAD_MEM2REG_REG_IND_DE:begin
				address_bus_of = {D, E};
			end 
			LOAD_MEM2REG_REG_IND_BC:begin
				address_bus_of = {B, C};
			end
			LOAD_MEM2REG_REG_IND_HL:begin
				address_bus_of = {H, L};
			end
			LOAD_MEM2REG_INDEXED_IX,
			LOAD_MEM2REG_INDEXED_IY:begin
				address_bus_of  = {ie_os_result_high, ie_os_result};
			end
			LOAD_MEM2REG_EXT:begin
				address_bus_of = {fsm_of_des, fsm_of_sou};
			end
			LOAD_16_BIT_MEM2DE_EXT, LOAD_16_BIT_MEM2HL_EXT, LOAD_16_BIT_MEM2SP_EXT, 
			LOAD_16_BIT_MEM2IX_EXT, LOAD_16_BIT_MEM2IY_EXT,					
			LOAD_16_BIT_MEM2BC_EXT:begin
				case(of_byte_order)
					1'b0: address_bus_of = {fsm_of_des, fsm_of_sou};
					1'b1: address_bus_of = {ie_os_result_high, ie_os_result};
				endcase
			end
			POP:begin
				case(of_byte_order)
					1'b0:begin
						address_bus_of = SP;
					end
					1'b1:begin
						address_bus_of = {ie_os_result_high, ie_os_result}; // sp + 1
					end
				endcase
			end
			EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP,
			EX_IY_AND_MEM_SP:begin
				case(of_byte_order)
					1'b0:begin
						address_bus_of = SP;
					end
					1'b1:begin
						address_bus_of = {ie_os_result_high, ie_os_result}; // sp + 1
					end
				endcase						
			end
			OE_MEM_HL:begin
				address_bus_of = {H, L};
			end
			OE_MEM_HL_MEM:begin
				address_bus_of = {H, L};
			end
			OE_MEM_INDEX_IX, OE_MEM_INDEX_IY, OE_MEM_INDEX_MEM_IX,
			OE_MEM_INDEX_MEM_IY:begin
				address_bus_of = {ie_os_result_high, ie_os_result};
			end
			RS_MEM_HL:begin
				address_bus_of = {H, L};
			end
			RS_MEM_INDEX_IX, 
			RS_MEM_INDEX_IY:begin
				address_bus_of = {ie_os_result_high, ie_os_result};
			end
			BM_SET_RESET_MEM_HL,
			BM_TEST_MEM_HL:begin
				address_bus_of = {H, L};
			end
			BM_SET_MEM_IX, BM_RESET_MEM_IX, BM_SET_MEM_IY,
			BM_RESET_MEM_IY:begin
				address_bus_of = {ie_os_result_high, ie_os_result};
			end
			BM_TEST_MEM_IX,
			BM_TEST_MEM_IY:begin
				address_bus_of = {ie_os_result_high, ie_os_result};
			end
			RETURN_FUNC:begin
				case(of_byte_order)
					1'b0:begin
						address_bus_of = SP;
					end
					1'b1:begin
						address_bus_of = {ie_os_result_high, ie_os_result}; // sp + 1
					end
				endcase						
			end
			OUTI, OTIR, OUTD,
			OTDR:begin
				address_bus_of = {H, L};
			end
			LDI, LDIR, LDD, 
			LDDR:begin
				address_bus_of = {H, L};
			end
			CPI, CPIR, CPD,
			CPDR:begin
				address_bus_of = {H, L};
			end
			RETI,
			RETN:begin
				case(of_byte_order)
					1'b0:begin
						address_bus_of = SP;
					end
					1'b1:begin
						address_bus_of = {ie_os_result_high, ie_os_result}; // sp + 1
					end
				endcase							
			end
			default: address_bus_of = 16'h0000; 
		endcase
	//end
end

//=================================================================
//                 write one/two byte to data memory
//                   load reg/imm. to memory
//=================================================================

// byte counter
reg os_byte_counter;
reg mem_write_clock_counter;
always @ (posedge clk or negedge reset) begin
	if (!reset) begin
		mem_write_clock_counter <= 1'b0;
	end
	else if(fsm_os_mem_wr) begin
		mem_write_clock_counter <= ~mem_write_clock_counter;
	end
end
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		os_byte_counter <= 1'b0;
	end
	else if (mem_write_clock_counter) begin
		case(fsm_of_operation_type) // use for 16-bit
			LOAD_16_BIT_BC2MEM_EXT, LOAD_16_BIT_DE2MEM_EXT, LOAD_16_BIT_HL2MEM_EXT, 
			LOAD_16_BIT_SP2MEM_EXT, LOAD_16_BIT_IX2MEM_EXT, LOAD_16_BIT_IY2MEM_EXT,
			PUSH, EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP, EX_IY_AND_MEM_SP, CALL, RST,
			NMI_INTERRUPT, INTERRUPT_MODE_1, INTERRUPT_MODE_2,
			INTERRUPT_MODE_0:begin
				case(os_byte_counter)
					1'b0: os_byte_counter <= 1'b1;
					1'b1: os_byte_counter <= 1'b0;
				endcase
			end
			default: os_byte_counter <= 1'b0;
		endcase		
	end
end

// place address and data
wire os_byte_order;
//assign os_byte_order = os_byte_counter ^ mem_write_clock_counter;
assign os_byte_order = os_byte_counter;  // ^ mem_write_clock_counter; is useless
//always @ (posedge clk or negedge reset) begin
always @* begin
	//if (!reset) begin
	//	address_bus_os <= 16'b0;
	//	data_bus_os <= 8'b0;
	//end
	//else begin
		case(fsm_of_operation_type)
			LOAD_REG2MEM_REG_IND_DE:begin
				address_bus_os = {D, E};
				data_bus_os = A;
			end
			LOAD_REG2MEM_REG_IND_BC:begin
				address_bus_os = {B, C};
				data_bus_os = A;
			end
			LOAD_REG2MEM_REG_IND_HL:begin
				address_bus_os = {H, L};
				case(fsm_of_sou)
					8'd0: data_bus_os = A;
					8'd1: data_bus_os = B;
					8'd2: data_bus_os = C;
					8'd3: data_bus_os = D;
					8'd4: data_bus_os = E;
					8'd6: data_bus_os = H;
					8'd7: data_bus_os = L;
					default: data_bus_os = 8'd0;
				endcase						
			end
			LOAD_IMM2MEM_REG_IND:begin
				address_bus_os = {H, L};
				data_bus_os = fsm_of_sou;
			end
			LOAD_REG2MEM_INDEXED_IX,
			LOAD_REG2MEM_INDEXED_IY:begin
				address_bus_os = {ie_os_result_high, ie_os_result};
				case(fsm_of_sou)
					8'd0: data_bus_os = A;
					8'd1: data_bus_os = B;
					8'd2: data_bus_os = C;
					8'd3: data_bus_os = D;
					8'd4: data_bus_os = E;
					8'd6: data_bus_os = H;
					8'd7: data_bus_os = L;
					default: data_bus_os = 8'd0;
				endcase	 
			end
			LOAD_REG2MEM_EXT:begin
				address_bus_os = {fsm_of_des, fsm_of_sou};
				data_bus_os = A;
			end
			LOAD_IMM2MEM_INDEXED_IX, 
			LOAD_IMM2MEM_INDEXED_IY:begin
				address_bus_os = {ie_os_result_high, ie_os_result};
				data_bus_os = fsm_of_sou;						
			end
			LOAD_16_BIT_BC2MEM_EXT:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {fsm_of_des, fsm_of_sou};
						data_bus_os = C;
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = B;								
					end
				endcase
			end
			LOAD_16_BIT_DE2MEM_EXT:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {fsm_of_des, fsm_of_sou};
						data_bus_os = E;
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = D;								
					end
				endcase
			end
			LOAD_16_BIT_HL2MEM_EXT:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {fsm_of_des, fsm_of_sou};
						data_bus_os = L;
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = H;								
					end
				endcase
			end
			LOAD_16_BIT_SP2MEM_EXT:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {fsm_of_des, fsm_of_sou};
						data_bus_os = SP[7:0];
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = SP[15:8];								
					end
				endcase
			end
			LOAD_16_BIT_IX2MEM_EXT:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {fsm_of_des, fsm_of_sou};
						data_bus_os = IX[7:0];
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = IX[15:8];								
					end
				endcase
			end
			LOAD_16_BIT_IY2MEM_EXT:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {fsm_of_des, fsm_of_sou};
						data_bus_os = IY[7:0];
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = IY[15:8];								
					end
				endcase
			end
			PUSH:begin
				address_bus_os = {ie_os_result_high, ie_os_result};
				case(os_byte_order)
					1'b0:begin
						case(fsm_of_sou)
							REG_AF: data_bus_os = A;
							REG_BC: data_bus_os = B;
							REG_DE: data_bus_os = D;
							REG_HL: data_bus_os = H;
							REG_IX: data_bus_os = IX[15:8];
							REG_IY: data_bus_os = IY[15:8];
							default: data_bus_os = 8'd0;									
						endcase
					end
					1'b1:begin
						case(fsm_of_sou)
							REG_AF: data_bus_os = F;
							REG_BC: data_bus_os = C;
							REG_DE: data_bus_os = E;
							REG_HL: data_bus_os = L;
							REG_IX: data_bus_os = IX[7:0];
							REG_IY: data_bus_os = IY[7:0];	
							default: data_bus_os = 8'd0;								
						endcase								
					end
				endcase
			end
			EX_HL_AND_MEM_SP:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = SP;
						data_bus_os = L;
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result}; // SP + 1
						data_bus_os = H;								
					end
				endcase
			end
			EX_IX_AND_MEM_SP:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = SP;
						data_bus_os = IX[7:0];
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result}; // SP + 1
						data_bus_os = IX[15:8];								
					end
				endcase
			end
			EX_IY_AND_MEM_SP:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = SP;
						data_bus_os = IY[7:0];
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result}; // SP + 1
						data_bus_os = IY[15:8];								
					end
				endcase						
			end
			OE_MEM_HL_MEM:begin
				address_bus_os = {H, L};
				data_bus_os = ie_os_result;
			end
			OE_MEM_INDEX_MEM_IX, 
			OE_MEM_INDEX_MEM_IY:begin
				address_bus_os = {ie_result_high_backup, ie_result_backup};
				data_bus_os = ie_os_result;
			end
			RS_MEM_HL:begin
				address_bus_os = {H, L};
				data_bus_os = ie_os_result;						
			end
			RS_MEM_INDEX_IX, 
			RS_MEM_INDEX_IY:begin
				address_bus_os = {ie_result_high_backup, ie_result_backup};
				data_bus_os = ie_os_result;
			end
			BM_SET_RESET_MEM_HL:begin
				address_bus_os = {H, L};
				data_bus_os = ie_os_result;						
			end
			BM_SET_MEM_IX, BM_RESET_MEM_IX, BM_SET_MEM_IY, 
			BM_RESET_MEM_IY:begin
				address_bus_os = {ie_result_high_backup, ie_result_backup};
				data_bus_os = ie_os_result;						
			end
			CALL:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = if_of_pc[15:8]; // PC high
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = if_of_pc[7:0]; // PC low							
					end
				endcase
			end
			RST:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = if_of_pc[15:8]; // PC high
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = if_of_pc[7:0]; // PC low							
					end
				endcase						
			end
			INI, INIR, IND,
			INDR:begin
				address_bus_os = {H, L};
				data_bus_os = io_fetch_data;						
			end
			LDI, LDIR, LDD,
			LDDR:begin
				address_bus_os = {D, E};
				data_bus_os = mem_fetch_data;						
			end
			NMI_INTERRUPT, INTERRUPT_MODE_1, INTERRUPT_MODE_2,
			INTERRUPT_MODE_0:begin
				case(os_byte_order)
					1'b0:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = if_of_pc[15:8]; // PC high
					end
					1'b1:begin
						address_bus_os = {ie_os_result_high, ie_os_result};
						data_bus_os = if_of_pc[7:0]; // PC low							
					end
				endcase						
			end
			default:begin
				address_bus_os = 16'h0000;
				data_bus_os = 8'h00;
			end
		endcase
	//end
end

//=================================================================
//                             input
//=================================================================

// read io data
parameter FIRST_CLOCK  = 2'b00;
parameter SECOND_CLOCK = 2'b01;
parameter THIRD_CLOCK  = 2'b10;
parameter FOURTH_CLOCK = 2'b11;

reg [1:0] input_cycles_counter;
reg [1:0] input_cycles_counter_next;
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		input_cycles_counter <= FIRST_CLOCK;
	end
	else if(fsm_of_input) begin
		input_cycles_counter <= input_cycles_counter_next;
	end
end
always @* begin
	case(input_cycles_counter)
		FIRST_CLOCK:begin
			input_cycles_counter_next = SECOND_CLOCK;
			io_fetch_data = 8'b0;
		end
		SECOND_CLOCK:begin
			input_cycles_counter_next = THIRD_CLOCK;
			io_fetch_data = 8'b0;
		end
		THIRD_CLOCK:begin
			input_cycles_counter_next = FOURTH_CLOCK;
			io_fetch_data = data_bus_of;
		end
		FOURTH_CLOCK:begin
			input_cycles_counter_next = FIRST_CLOCK;
			io_fetch_data = 8'b0;
		end
	endcase	
end
// always @(posedge clk or negedge reset) begin
// 	if (!reset) begin
// 		io_fetch_data <= data_bus_of;
// 	end
// 	else if (input_cycles_counter == 2'b10) begin
// 		io_fetch_data <= data_bus_of;
// 	end
// end

// place address
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		address_input <= 16'b0;		
	end
	else begin
		case(fsm_of_operation_type)
			IN_MEM_EXTEND: address_input <= {A, fsm_of_sou};
			IN_MEM_REG_IND: address_input <= {B, C};
			INI, INIR, IND, 
			INDR: address_input <= {B, C};
			default: address_input <= 16'h0000;
		endcase
	end
end


//=================================================================
//                             output
//=================================================================

// place address
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		address_output <= 16'b0;	
	end
	else begin
		case(fsm_of_operation_type)
			OUT_MEM_EXTEND: address_output <= {A, fsm_of_des};
			OUT_MEM_REG_IND: address_output <= {B, C};
			OUTI, OTIR, OUTD, 
			OTDR: address_output <= {B, C};
			default: address_output <= 16'h0000;
		endcase
	end
end

// place data
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		data_output <= 8'b0;
	end
	else begin
		case(fsm_of_operation_type)
			OUT_MEM_EXTEND: data_output <= A;
			OUT_MEM_REG_IND: begin
				case(fsm_of_sou)
						8'd0: data_output <= A;
						8'd1: data_output <= B;
						8'd2: data_output <= C;
						8'd3: data_output <= D;
						8'd4: data_output <= E;
						8'd6: data_output <= H;  // H <-- F
						8'd7: data_output <= L;
						default: data_output <= 8'd0;
				endcase
			end
			OUTI, OTIR, OUTD, 
			OTDR: data_output <= mem_fetch_data;
			default: data_output <= 8'h00;
		endcase
	end
end

//=================================================================
//                    load data to IF
//=================================================================
//always @(posedge clk or negedge reset) begin
always @* begin
		case(fsm_of_operation_type)
			JUMP_REG_IND:begin
				case(fsm_of_sou)
					REG_HL: of_if_pc = {H, L};
					REG_IX: of_if_pc = IX;
					REG_IY: of_if_pc = IY;
					default: of_if_pc = 16'h0000;
				endcase
			end
			JUMP_RELATIVE,
			JUMP_DJNZ:begin
				of_if_pc = {ie_os_result_high, ie_os_result};
			end
			JUMP_IMM:begin
				of_if_pc = {fsm_of_des, fsm_of_sou};
			end
			CALL:begin
				of_if_pc = {fsm_of_des, fsm_of_sou};
			end
			RETURN_FUNC:begin
				of_if_pc = {mem_fetch_data_high, mem_fetch_data};
			end
			RST:begin
				of_if_pc = {8'h00, fsm_of_sou};
			end
			INIR:begin
				of_if_pc = {ie_os_result_high, ie_os_result};
			end			
			INDR:begin
				of_if_pc = {ie_os_result_high, ie_os_result};
			end
			OTIR,
			OTDR:begin
				of_if_pc = {ie_os_result_high, ie_os_result};
			end
			LDIR,
			LDDR:begin
				of_if_pc = {ie_os_result_high, ie_os_result};
			end
			CPIR,
			CPDR:begin
				of_if_pc = {ie_os_result_high, ie_os_result};
			end
			NMI_INTERRUPT:begin
				of_if_pc = 16'h0066;
			end
			INTERRUPT_MODE_1:begin
				of_if_pc = 16'h0038;
			end
			INTERRUPT_MODE_2:begin
				of_if_pc = {I, io_fetch_data};
			end
			RETI,
			RETN:begin
				of_if_pc = {mem_fetch_data_high, mem_fetch_data};
			end
			default: of_if_pc = 16'h0000;
		endcase
end

//=================================================================
//                    load data to IE
//=================================================================
// OE operation function table
//parameter ADD_ALU                    = 5'd1;
//parameter ADC_ALU                    = 5'd2;
parameter SUB_ALU                    = 5'd3;
//parameter SBC_ALU                    = 5'd4;
//parameter AND_ALU                    = 5'd5;
//parameter XOR_ALU                    = 5'd6;
//parameter OR_ALU                     = 5'd7;
//parameter CP_ALU                     = 5'd8;
//parameter INC_ALU                    = 5'd9;
//parameter DEC_ALU                    = 5'd10;
parameter ADD_16BIT_ALU              = 5'd11;
parameter ADC_16BIT_ALU              = 5'd12;
parameter SBC_16BIT_ALU              = 5'd13;
parameter INC_16BIT_ALU              = 5'd14;  // not used
parameter DEC_16BIT_ALU              = 5'd15;  // not used
parameter SUB_AF_ALU                 = 5'd16;
//parameter RLC_ALU                    = 5'd17;
//parameter RRC_ALU                    = 5'd18;
//parameter RL_ALU                     = 5'd19;
//parameter RR_ALU                     = 5'd20;
//parameter SLA_ALU                    = 5'd21;
//parameter SRA_ALU                    = 5'd22;
//parameter SRL_ALU                    = 5'd23;
//parameter RLD_ALU                    = 5'd24;
//parameter RRD_ALU                    = 5'd25;
parameter SET_BIT_ALU                = 5'd26;
parameter RESET_BIT_ALU              = 5'd27;
parameter TEST_BIT_ALU               = 5'd28;
parameter ADD_16BIT_NONE_AFFECT_ALU  = 5'd29;
parameter ADD_16BIT_BLOCK_TRANS_ALU  = 5'd30;
parameter BLOCK_SEARCH_COMPARE_ALU   = 5'd31;

reg load_ie_counter;
reg load_ie_counter_2;
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		of_ie_operand_des <= 8'b0;
		of_ie_operand_sou <= 8'b0;
		of_ie_operand_des_high <= 8'b0;
		of_ie_operand_sou_high <= 8'b0;
		of_ie_operation <= 5'b0;
		load_ie_counter <= 1'b0;
		load_ie_counter_2 <= 1'b0;
		ie_result_backup <= 8'b0;
		ie_result_high_backup <= 8'b0;
	end
	else if(fsm_of_load_en) begin
		case(fsm_of_operation_type)
			LOAD_MEM2REG_INDEXED_IX:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= IX;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};
			end
			LOAD_MEM2REG_INDEXED_IY:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= IY;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};				
			end
			LOAD_REG2MEM_INDEXED_IX:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= IX;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};				
			end
			LOAD_REG2MEM_INDEXED_IY:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= IY;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};				
			end
			LOAD_IMM2MEM_INDEXED_IX:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= IX;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};
			end
			LOAD_IMM2MEM_INDEXED_IY:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= IY;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};				
			end
			LOAD_16_BIT_MEM2DE_EXT, LOAD_16_BIT_MEM2HL_EXT, LOAD_16_BIT_MEM2SP_EXT, 
			LOAD_16_BIT_MEM2IX_EXT, LOAD_16_BIT_MEM2IY_EXT, LOAD_16_BIT_MEM2BC_EXT,
			LOAD_16_BIT_BC2MEM_EXT, LOAD_16_BIT_DE2MEM_EXT, LOAD_16_BIT_HL2MEM_EXT, 
			LOAD_16_BIT_SP2MEM_EXT, LOAD_16_BIT_IX2MEM_EXT, 
			LOAD_16_BIT_IY2MEM_EXT:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= {fsm_of_des, fsm_of_sou};
				{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'd1;
			end
			PUSH:begin
				of_ie_operation <= ADD_16BIT_ALU;
				case(load_ie_counter)
					1'b0:begin  // sp + (-1)
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff;   // equals -1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin  // sp + (-2)
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe;   // equals -2	
						load_ie_counter <= 1'b0;					
					end
				endcase
			end
			POP:begin
				of_ie_operation <= ADD_16BIT_ALU;
				case(load_ie_counter)
					1'b0:begin  // sp + 1
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;   // equals 1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin  // sp + 2
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0002;   // equals 2	
						load_ie_counter <= 1'b0;					
					end
				endcase				
			end
			EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP,
			EX_IY_AND_MEM_SP:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= SP;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;   // equals 1
			end
			OE_REG:begin
				of_ie_operation <= fsm_of_des[4:0];
				of_ie_operand_des <= A;
				case(fsm_of_sou)
					8'd0: of_ie_operand_sou <= A;
					8'd1: of_ie_operand_sou <= B;
					8'd2: of_ie_operand_sou <= C;
					8'd3: of_ie_operand_sou <= D;
					8'd4: of_ie_operand_sou <= E;
					8'd6: of_ie_operand_sou <= H;
					8'd7: of_ie_operand_sou <= L;
				endcase	
			end
			OE_MEM_HL:begin
				of_ie_operation <= fsm_of_des[4:0];
				of_ie_operand_des <= A;
				of_ie_operand_sou <= mem_fetch_data;			
			end
			OE_MEM_HL_MEM:begin
				of_ie_operation <= fsm_of_des[4:0];   // INC_OP or DEC_OP
				of_ie_operand_sou <= mem_fetch_data;
				//of_ie_operand_sou <= 8'd1;				
			end
			OE_MEM_INDEX_IX,
			OE_MEM_INDEX_MEM_IX:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IX;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operand_sou <= mem_fetch_data;
						of_ie_operand_des <= A;  // when fsm_of_des equals INC_OP or DEC_OP, it is useless
						of_ie_operation <= fsm_of_des[4:0];
						load_ie_counter <= 1'b0;
					end
				endcase
			end
			OE_MEM_INDEX_IY,
			OE_MEM_INDEX_MEM_IY:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IY;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operand_sou <= mem_fetch_data;
						of_ie_operand_des <= A; // when fsm_of_des equals INC_OP or DEC_OP, it is useless
						of_ie_operation <= fsm_of_des[4:0];
						load_ie_counter <= 1'b0;
					end
				endcase
			end
			OE_IMM:begin
				of_ie_operation <= fsm_of_des[4:0];
				of_ie_operand_sou <= fsm_of_sou;
				of_ie_operand_des <= A;
			end
			OE_ADD_16_BIT:begin
				of_ie_operation <= ADD_16BIT_ALU;
				case(fsm_of_sou)
					REG_BC: {of_ie_operand_sou_high, of_ie_operand_sou} <= {B, C};
					REG_DE: {of_ie_operand_sou_high, of_ie_operand_sou} <= {D, E};
					REG_HL: {of_ie_operand_sou_high, of_ie_operand_sou} <= {H, L};
					REG_SP: {of_ie_operand_sou_high, of_ie_operand_sou} <= SP;
					REG_IX: {of_ie_operand_sou_high, of_ie_operand_sou} <= IX;
					REG_IY: {of_ie_operand_sou_high, of_ie_operand_sou} <= IY;
				endcase
				case(fsm_of_des)
					REG_HL: {of_ie_operand_des_high, of_ie_operand_des} <= {H, L};	
					REG_IX: {of_ie_operand_des_high, of_ie_operand_des} <= {IX};	
					REG_IY: {of_ie_operand_des_high, of_ie_operand_des} <= {IY};	
				endcase		
			end
			OE_ADC_16_BIT:begin
				of_ie_operation <= ADC_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
				case(fsm_of_sou)
					REG_BC: {of_ie_operand_sou_high, of_ie_operand_sou} <= {B, C};
					REG_DE: {of_ie_operand_sou_high, of_ie_operand_sou} <= {D, E};
					REG_HL: {of_ie_operand_sou_high, of_ie_operand_sou} <= {H, L};
					REG_SP: {of_ie_operand_sou_high, of_ie_operand_sou} <= SP;
				endcase
			end
			OE_SBC_16_BIT:begin
				of_ie_operation <= SBC_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
				case(fsm_of_sou)
					REG_BC: {of_ie_operand_sou_high, of_ie_operand_sou} <= {B, C};
					REG_DE: {of_ie_operand_sou_high, of_ie_operand_sou} <= {D, E};
					REG_HL: {of_ie_operand_sou_high, of_ie_operand_sou} <= {H, L};
					REG_SP: {of_ie_operand_sou_high, of_ie_operand_sou} <= SP;
				endcase
			end
			OE_INC_16_BIT:begin
				of_ie_operation <= INC_16BIT_ALU;
				case(fsm_of_sou)
					REG_BC: {of_ie_operand_sou_high, of_ie_operand_sou} <= {B, C};
					REG_DE: {of_ie_operand_sou_high, of_ie_operand_sou} <= {D, E};
					REG_HL: {of_ie_operand_sou_high, of_ie_operand_sou} <= {H, L};
					REG_SP: {of_ie_operand_sou_high, of_ie_operand_sou} <= SP;
					REG_IX: {of_ie_operand_sou_high, of_ie_operand_sou} <= IX;
					REG_IY: {of_ie_operand_sou_high, of_ie_operand_sou} <= IY;
				endcase				
			end
			OE_DEC_16_BIT:begin
				of_ie_operation <= DEC_16BIT_ALU;
				case(fsm_of_sou)
					REG_BC: {of_ie_operand_sou_high, of_ie_operand_sou} <= {B, C};
					REG_DE: {of_ie_operand_sou_high, of_ie_operand_sou} <= {D, E};
					REG_HL: {of_ie_operand_sou_high, of_ie_operand_sou} <= {H, L};
					REG_SP: {of_ie_operand_sou_high, of_ie_operand_sou} <= SP;
					REG_IX: {of_ie_operand_sou_high, of_ie_operand_sou} <= IX;
					REG_IY: {of_ie_operand_sou_high, of_ie_operand_sou} <= IY;
				endcase				
			end
			// AF Operation
			OE_NEG:begin
				of_ie_operation <= SUB_AF_ALU;
				of_ie_operand_des <= 8'b0;
				of_ie_operand_sou <= A;
			end
			// Rotates and Shifts
			RS_REG:begin
				of_ie_operation <= fsm_of_des[4:0];
				case(fsm_of_sou)
					8'd0: of_ie_operand_des <= A;  // IE operates of_ie_operand_des
					8'd1: of_ie_operand_des <= B;
					8'd2: of_ie_operand_des <= C;
					8'd3: of_ie_operand_des <= D;
					8'd4: of_ie_operand_des <= E;
					8'd6: of_ie_operand_des <= H;
					8'd7: of_ie_operand_des <= L;
				endcase
			end
			RS_MEM_HL:begin
				of_ie_operation <= fsm_of_des[4:0];
				of_ie_operand_sou <= A;   // only useful for operation RLD_OP and RRD_OP
				of_ie_operand_des <= mem_fetch_data;
			end
			RS_MEM_INDEX_IX:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IX;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operation <= fsm_of_des[4:0];
						load_ie_counter <= 1'b0;
					end
				endcase
			end
			RS_MEM_INDEX_IY:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IY;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operation <= fsm_of_des[4:0];
						load_ie_counter <= 1'b0;
					end
				endcase				
			end
			// bit manipulation
			BM_TEST:begin
				of_ie_operation <= TEST_BIT_ALU;
				of_ie_operand_sou <= fsm_of_sou;  // bit 'fsm_of_sou' in register 'fsm_of_des'
				//of_ie_operand_des <= fsm_of_des;
				case(fsm_of_des)
					8'd0: of_ie_operand_des <= A; 
					8'd1: of_ie_operand_des <= B;
					8'd2: of_ie_operand_des <= C;
					8'd3: of_ie_operand_des <= D;
					8'd4: of_ie_operand_des <= E;
					8'd6: of_ie_operand_des <= H;
					8'd7: of_ie_operand_des <= L;
				endcase
			end
			BM_SET:begin
				of_ie_operation <= SET_BIT_ALU;
				of_ie_operand_sou <= fsm_of_sou;  // bit 'fsm_of_sou' in register 'fsm_of_des'
				//of_ie_operand_des <= fsm_of_des;	
				case(fsm_of_des)
					8'd0: of_ie_operand_des <= A; 
					8'd1: of_ie_operand_des <= B;
					8'd2: of_ie_operand_des <= C;
					8'd3: of_ie_operand_des <= D;
					8'd4: of_ie_operand_des <= E;
					8'd6: of_ie_operand_des <= H;
					8'd7: of_ie_operand_des <= L;
				endcase						
			end
			BM_RESET:begin
				of_ie_operation <= RESET_BIT_ALU;
				of_ie_operand_sou <= fsm_of_sou;  // bit 'fsm_of_sou' in register 'fsm_of_des'
				//of_ie_operand_des <= fsm_of_des;
				case(fsm_of_des)
					8'd0: of_ie_operand_des <= A; 
					8'd1: of_ie_operand_des <= B;
					8'd2: of_ie_operand_des <= C;
					8'd3: of_ie_operand_des <= D;
					8'd4: of_ie_operand_des <= E;
					8'd6: of_ie_operand_des <= H;
					8'd7: of_ie_operand_des <= L;
				endcase
			end
			BM_SET_RESET_MEM_HL:begin
				of_ie_operation <= fsm_of_des[4:0];
				of_ie_operand_des <= mem_fetch_data;
				of_ie_operand_sou <= fsm_of_sou;  // bit 'fsm_of_sou' in register 'fsm_of_des'
			end
			BM_TEST_MEM_HL:begin
				of_ie_operation <= TEST_BIT_ALU;
				of_ie_operand_des <= mem_fetch_data;
				of_ie_operand_sou <= fsm_of_sou;  // bit 'fsm_of_sou' in register 'fsm_of_des'
			end
			BM_SET_MEM_IX:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IX;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operation <= SET_BIT_ALU;
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operand_sou <= fsm_of_sou;
						load_ie_counter <= 1'b0;
					end
				endcase
			end
			BM_RESET_MEM_IX:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IX;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operation <= RESET_BIT_ALU;
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operand_sou <= fsm_of_sou;
						load_ie_counter <= 1'b0;
					end
				endcase
			end
			BM_SET_MEM_IY:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IY;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operation <= SET_BIT_ALU;
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operand_sou <= fsm_of_sou;
						load_ie_counter <= 1'b0;
					end
				endcase				
			end
			BM_RESET_MEM_IY:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IY;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operation <= RESET_BIT_ALU;
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operand_sou <= fsm_of_sou;
						load_ie_counter <= 1'b0;
					end
				endcase				
			end
			BM_TEST_MEM_IX:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IX;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operation <= TEST_BIT_ALU;
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operand_sou <= fsm_of_sou;
						load_ie_counter <= 1'b0;
					end
				endcase				
			end
			BM_TEST_MEM_IY:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= IY;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_des};
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						// INC_OP and DEC_OP use the result of IE as address twice, backup it for the second time
						//{ie_result_high_backup, ie_result_backup} <= {ie_os_result_high, ie_os_result};
						of_ie_operation <= TEST_BIT_ALU;
						of_ie_operand_des <= mem_fetch_data; 
						of_ie_operand_sou <= fsm_of_sou;
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			// jump call return reset
			JUMP_RELATIVE:begin
				of_ie_operation <= ADD_16BIT_ALU;
				{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};
			end
			JUMP_DJNZ:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1;
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= {8'b0, fsm_of_sou};
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			CALL:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff;  // -1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe;  // -2
						load_ie_counter <= 1'b0;
					end
				endcase				
			end
			RETURN_FUNC:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;  // 1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0002;  // 2
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			RST:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff;  // -1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe;  // -2
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			INI:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			INIR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
					default:begin
						of_ie_operation <= 5'd0;
						{of_ie_operand_des_high, of_ie_operand_des} <= 16'h0000; 
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0000; 	
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			IND:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff;  //-1
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			INDR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; //-1
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			OUTI:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			OTIR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			OUTD:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff;  //-1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			OTDR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; //-1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= SUB_ALU;
						of_ie_operand_des <= B;
						of_ie_operand_sou <= 8'd1; 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			LDI:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001; // 1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {D, E};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001; // 1
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			LDIR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001; // 1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {D, E};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001; // 1
						{load_ie_counter_2, load_ie_counter} <= 2'b11;						
					end
					2'b11:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			LDD:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {D, E};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			LDDR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {D, E};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b11;						
					end
					2'b11:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			CPI:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001; // 1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= BLOCK_SEARCH_COMPARE_ALU;
						of_ie_operand_des <= A;
						of_ie_operand_sou <= mem_fetch_data;
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			CPIR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001; // 1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= BLOCK_SEARCH_COMPARE_ALU;
						of_ie_operand_des <= A;
						of_ie_operand_sou <= mem_fetch_data;
						{load_ie_counter_2, load_ie_counter} <= 2'b11;						
					end
					2'b11:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			CPD:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= BLOCK_SEARCH_COMPARE_ALU;
						of_ie_operand_des <= A;
						of_ie_operand_sou <= mem_fetch_data;
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			CPDR:begin
				case({load_ie_counter_2, load_ie_counter})
					2'b00:begin
						of_ie_operation <= ADD_16BIT_BLOCK_TRANS_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {B, C};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1
						{load_ie_counter_2, load_ie_counter} <= 2'b01;
					end
					2'b01:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= {H, L};
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff; // -1 						
						{load_ie_counter_2, load_ie_counter} <= 2'b10;
					end
					2'b10:begin
						of_ie_operation <= BLOCK_SEARCH_COMPARE_ALU;
						of_ie_operand_des <= A;
						of_ie_operand_sou <= mem_fetch_data;
						{load_ie_counter_2, load_ie_counter} <= 2'b11;						
					end
					2'b11:begin
						of_ie_operation <= ADD_16BIT_NONE_AFFECT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= if_of_pc;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe; // -2
						{load_ie_counter_2, load_ie_counter} <= 2'b00;						
					end
				endcase				
			end
			NMI_INTERRUPT, INTERRUPT_MODE_1, INTERRUPT_MODE_2,
			INTERRUPT_MODE_0:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hffff;  // -1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'hfffe;  // -2
						load_ie_counter <= 1'b0;
					end
				endcase				
			end
			RETI,
			RETN:begin
				case(load_ie_counter)
					1'b0:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0001;  // 1
						load_ie_counter <= 1'b1;
					end
					1'b1:begin
						of_ie_operation <= ADD_16BIT_ALU;
						{of_ie_operand_des_high, of_ie_operand_des} <= SP;
						{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0002;  // 2
						load_ie_counter <= 1'b0;
					end
				endcase					
			end
			default:begin
				of_ie_operation <= 5'd0;
				{of_ie_operand_des_high, of_ie_operand_des} <= 16'h0000;
				{of_ie_operand_sou_high, of_ie_operand_sou} <= 16'h0000;  
			end
 		endcase
	end
end




//=================================================================
//                  OF load and exchange block
//=================================================================
reg le_counter;
reg le_counter_2;
//always @(negedge reset or posedge fsm_of_le_en or posedge fsm_os_int) begin  
always @(posedge clk or negedge reset) begin  
	if (!reset) begin
		A <= 8'd0;
		B <= 8'd1;
		C <= 8'd2;
		D <= 8'd3;
		E <= 8'd4;
		F <= 8'd0;
		H <= 8'd6;
		L <= 8'd7;
		I <= 8'd8;
		R <= 8'd9;
		IX <= 16'b0;
		IY <= 16'b0;
		SP <= 16'b0;
		A_SKIM <= 8'd0;
		B_SKIM <= 8'd1;
		C_SKIM <= 8'd2;
		D_SKIM <= 8'd3;
		E_SKIM <= 8'd4;
		F_SKIM <= 8'd0;
		H_SKIM <= 8'd6;
		L_SKIM <= 8'd7;
		le_counter <= 1'b0;
		le_counter_2 <= 1'b0;
	end
	// else if(fsm_os_int) begin
	// 	if (fsm_of_operation_type == LOAD_IMP2REG) begin
	// 		F[2] <= 0;    // config parity
	// 	end
	// end
	else if(fsm_of_le_en || fsm_os_int) begin
		case(fsm_of_operation_type)
			// load 8 bits
			LOAD_REG2REG:begin
				case({fsm_of_des[3:0], fsm_of_sou[3:0]})
					8'h00: A <= A;
					8'h01: A <= B;
					8'h02: A <= C;
					8'h03: A <= D;
					8'h04: A <= E;
					8'h06: A <= H;
					8'h07: A <= L;

					8'h10: B <= A;
					8'h11: B <= B;
					8'h12: B <= C;
					8'h13: B <= D;
					8'h14: B <= E;
					8'h16: B <= H;
					8'h17: B <= L;

				    8'h20: C <= A;
					8'h21: C <= B;
					8'h22: C <= C;
					8'h23: C <= D;
					8'h24: C <= E;
					8'h26: C <= H;
					8'h27: C <= L;

					8'h30: D <= A;
					8'h31: D <= B;
					8'h32: D <= C;
					8'h33: D <= D;
					8'h34: D <= E;
					8'h36: D <= H;
					8'h37: D <= L;

					8'h40: E <= A;
					8'h41: E <= B;
					8'h42: E <= C;
					8'h43: E <= D;
					8'h44: E <= E;
					8'h46: E <= H;
					8'h47: E <= L;

					8'h60: H <= A;
					8'h61: H <= B;
					8'h62: H <= C;
					8'h63: H <= D;
					8'h64: H <= E;
					8'h66: H <= H;
					8'h67: H <= L;

					8'h70: L <= A;
					8'h71: L <= B;
					8'h72: L <= C;
					8'h73: L <= D;
					8'h74: L <= E;
					8'h76: L <= H;
					8'h77: L <= L;
					default:begin
						A <= 8'd0;
						B <= 8'd0;
						C <= 8'd0;
						D <= 8'd0;
						E <= 8'd0;
						F <= 8'd0;
						H <= 8'd0;
						L <= 8'd0;						
					end
				endcase
			end
			LOAD_MEM2REG_REG_IND_DE,
			LOAD_MEM2REG_REG_IND_BC:begin
				A <= mem_fetch_data;
			end
			LOAD_MEM2REG_REG_IND_HL:begin
				case(fsm_of_des)
					8'd0: A <= mem_fetch_data;
					8'd1: B <= mem_fetch_data;
					8'd2: C <= mem_fetch_data;
					8'd3: D <= mem_fetch_data;
					8'd4: E <= mem_fetch_data;
					8'd6: H <= mem_fetch_data;
					8'd7: L <= mem_fetch_data;
				endcase
			end
			LOAD_REG2IMP:begin
				case(fsm_of_des)
					8'd8: I <= A;
					8'd9: R <= A;
					default:begin
						I <= 8'h00;
						R <= 8'h00;
					end
				endcase
			end
			LOAD_IMP2REG:begin
				case(fsm_of_sou)
					8'd8:begin
						A <= I;
						F[7] <= I[7];           // config S
						F[6] <= (I == 8'b0);    // config Z
						F[4] <= 1'b0;           // reset H flag
						F[2] <= fsm_os_IFF2 & (~fsm_os_int);    // config parity
						F[1] <= 1'b0;           // reset N flag
						//F[0] <= A[7];         // C flag (NOT affected)
					end 
					8'd9:begin
						A <= R;
						F[7] <= R[7];           // config S
						F[6] <= (R == 8'b0);    // config Z
						F[4] <= 1'b0;           // reset H flag
						F[2] <= fsm_os_IFF2 & (~fsm_os_int);    // config parity
						F[1] <= 1'b0;           // reset N flag
						//F[0] <= A[7];         // C flag (NOT affected)
					end 
				endcase		
			end
			LOAD_IMM2REG:begin
				case(fsm_of_des)
					8'd0: A <= fsm_of_sou;
					8'd1: B <= fsm_of_sou;
					8'd2: C <= fsm_of_sou;
					8'd3: D <= fsm_of_sou;
					8'd4: E <= fsm_of_sou;
					8'd6: H <= fsm_of_sou;
					8'd7: L <= fsm_of_sou;
				endcase				
			end
			LOAD_MEM2REG_INDEXED_IX,
			LOAD_MEM2REG_INDEXED_IY:begin
				case(fsm_of_des)
					8'd0: A <= mem_fetch_data;
					8'd1: B <= mem_fetch_data;
					8'd2: C <= mem_fetch_data;
					8'd3: D <= mem_fetch_data;
					8'd4: E <= mem_fetch_data;
					8'd6: H <= mem_fetch_data;
					8'd7: L <= mem_fetch_data;
				endcase	
			end
			LOAD_MEM2REG_EXT:begin
				A <= mem_fetch_data;
			end
			// load 16-bits
			LOAD_16_BIT_HL2SP:begin
				SP <= {H, L};
			end   
			LOAD_16_BIT_IX2SP:begin
				SP <= IX;
			end
			LOAD_16_BIT_IY2SP:begin
				SP <= IY;
			end
			LOAD_16_BIT_IMM2BC:begin
				{B, C} <= {fsm_of_des, fsm_of_sou};
			end 
			LOAD_16_BIT_IMM2DE:begin
				{D, E} <= {fsm_of_des, fsm_of_sou};
			end  
			LOAD_16_BIT_IMM2HL:begin
				{H, L} <= {fsm_of_des, fsm_of_sou};
			end 
			LOAD_16_BIT_IMM2SP:begin
				SP <= {fsm_of_des, fsm_of_sou};
			end 
			LOAD_16_BIT_IMM2IX:begin
				IX <= {fsm_of_des, fsm_of_sou};
			end 
			LOAD_16_BIT_IMM2IY :begin
				IY <= {fsm_of_des, fsm_of_sou};
			end
			LOAD_16_BIT_MEM2BC_EXT:begin
				{B, C} <= {mem_fetch_data_high, mem_fetch_data};
			end	
			LOAD_16_BIT_MEM2DE_EXT:begin
				{D, E} <= {mem_fetch_data_high, mem_fetch_data};
			end 
			LOAD_16_BIT_MEM2HL_EXT:begin
				{H, L} <= {mem_fetch_data_high, mem_fetch_data};
			end 
			LOAD_16_BIT_MEM2SP_EXT:begin
				SP <= {mem_fetch_data_high, mem_fetch_data};
			end 
			LOAD_16_BIT_MEM2IX_EXT:begin
				IX <= {mem_fetch_data_high, mem_fetch_data};
			end 
			LOAD_16_BIT_MEM2IY_EXT:begin
				IY <= {mem_fetch_data_high, mem_fetch_data};
			end	
			PUSH:begin
				SP <= {ie_os_result_high, ie_os_result};
			end	
			POP:begin
				SP <= {ie_os_result_high, ie_os_result};
				case(fsm_of_des)
					REG_AF: {A, F} <= {mem_fetch_data_high, mem_fetch_data};
					REG_BC: {B, C} <= {mem_fetch_data_high, mem_fetch_data};
					REG_DE: {D, E} <= {mem_fetch_data_high, mem_fetch_data};
					REG_HL: {H, L} <= {mem_fetch_data_high, mem_fetch_data};
					REG_IX: IX <= {mem_fetch_data_high, mem_fetch_data};
					REG_IY: IY <= {mem_fetch_data_high, mem_fetch_data};
					default:begin
						{A, F} <= {mem_fetch_data_high, mem_fetch_data};
						{B, C} <= {mem_fetch_data_high, mem_fetch_data};
						{D, E} <= {mem_fetch_data_high, mem_fetch_data};
						{H, L} <= {mem_fetch_data_high, mem_fetch_data};
						IX <= {mem_fetch_data_high, mem_fetch_data};
						IY <= {mem_fetch_data_high, mem_fetch_data};
						//{le_counter_2, le_counter} <= 2'b00;					
					end					
				endcase
			end
			// exchange
			EX_AF:begin
				{A,F} <= {A_SKIM,F_SKIM};
				{A_SKIM,F_SKIM} <= {A,F};
			end
			EX_BC_DE_HL:begin
				{B,C} <= {B_SKIM,C_SKIM};
				{B_SKIM,C_SKIM} <= {B,C};	
				{D,E} <= {D_SKIM,E_SKIM};
				{D_SKIM,E_SKIM} <= {D,E};
				{H,L} <= {H_SKIM,L_SKIM};
				{H_SKIM,L_SKIM} <= {H,L};			
			end
			EX_HL_AND_DE:begin
				{D,E} <= {H,L};
				{H,L} <= {D,E};				
			end	
			EX_HL_AND_MEM_SP:begin
				{H, L} <= {mem_fetch_data_high, mem_fetch_data};
			end
			EX_IX_AND_MEM_SP:begin
				IX <= {mem_fetch_data_high, mem_fetch_data};
			end
			EX_IY_AND_MEM_SP:begin
				IY <= {mem_fetch_data_high, mem_fetch_data};
			end
			// 8-bit arithmetic and logic
			OE_REG:begin
				case(fsm_of_des)
					INC_OP,
					DEC_OP:begin
						case(fsm_of_sou)
							8'd0: A <= ie_os_result;
							8'd1: B <= ie_os_result;
							8'd2: C <= ie_os_result;
							8'd3: D <= ie_os_result;
							8'd4: E <= ie_os_result;
							8'd6: H <= ie_os_result;
							8'd7: L <= ie_os_result;
						endcase
					end
					//ADD_OP, ADC_OP, SUB_OP, SBC_OP, AND, XOR, 
					//OR: A <= ie_os_result;
					// OP_OP: 
					default: A <= ie_os_result;
				endcase
				F <= ie_os_flag_reg;
			end
			OE_MEM_HL:begin
				//A <= ie_os_result;
				//case(fsm_of_des)
				//	ADD_OP, ADC_OP, SUB_OP, SBC_OP, AND, XOR, 
				//	OR: A <= ie_os_result;
				//	// OP_OP:
				//endcase
				A <= ie_os_result;
				F <= ie_os_flag_reg;
			end
			OE_MEM_HL_MEM:begin
				F <= ie_os_flag_reg;
			end
			OE_MEM_INDEX_IX,
			OE_MEM_INDEX_IY:begin
				//case(fsm_of_des)
				//	ADD_OP, ADC_OP, SUB_OP, SBC_OP, AND, XOR, 
				//	OR: A <= ie_os_result;
				//	// OP_OP:
				//endcase
				A <= ie_os_result;
				F <= ie_os_flag_reg;
			end
			OE_MEM_INDEX_MEM_IX,
			OE_MEM_INDEX_MEM_IY:begin
				F <= ie_os_flag_reg;
			end
			OE_IMM:begin
				//case(fsm_of_des)
				//	ADD_OP, ADC_OP, SUB_OP, SBC_OP, AND, XOR, 
				//	OR: A <= ie_os_result;
				//	// OP_OP:
				//endcase
				A <= ie_os_result;
				F <= ie_os_flag_reg;
			end
			// 16-bit arithmetic
			OE_ADD_16_BIT:begin
				case(fsm_of_des)
					REG_HL: {H, L} <= {ie_os_result_high, ie_os_result};	
					REG_IX: {IX} <= {ie_os_result_high, ie_os_result};
					REG_IY: {IY} <= {ie_os_result_high, ie_os_result};	
				endcase	
				F <= ie_os_flag_reg;				
			end
			OE_ADC_16_BIT:begin
				{H, L} <= {ie_os_result_high, ie_os_result};
				F <= ie_os_flag_reg;
			end
			OE_SBC_16_BIT:begin
				{H, L} <= {ie_os_result_high, ie_os_result};
				F <= ie_os_flag_reg;				
			end
			OE_INC_16_BIT, 
			OE_DEC_16_BIT:begin
				case(fsm_of_sou)
					REG_BC: {B, C} <= {ie_os_result_high, ie_os_result};
					REG_DE: {D, E} <= {ie_os_result_high, ie_os_result};
					REG_HL: {H, L} <= {ie_os_result_high, ie_os_result};
					REG_SP: SP <= {ie_os_result_high, ie_os_result};
					REG_IX: IX <= {ie_os_result_high, ie_os_result};
					REG_IY: IY <= {ie_os_result_high, ie_os_result};
				endcase					
			end
			// AF Operation
			OE_CPL:begin
				A <= ~A;
				F[4] <= 1'b1;  // set H flag
				F[1] <= 1'b1;  // set N flag				
			end
			OE_CCF:begin
				F[4] <= F[0];  // copy C to H
				F[1] <= 1'b0;  // reset N flag
				F[0] <= ~F[0]; // invert C flag
			end
			OE_SCF:begin
				F[4] <= 1'b0;  // reset H flag
				F[1] <= 1'b0;  // reset N flag	
				F[0] <= 1'b1;  // set C flag				
			end
			OE_NEG:begin
				F <= ie_os_flag_reg;
				A <= ie_os_result;				
			end
			RS_REG_A:begin
				case(fsm_of_des)
					RLC: A <= {A[6:0], A[7]};
					RRC: A <= {A[0], A[7:1]};
					RL:  A <= {A[6:0], F[0]};
					RR:  A <= {F[0], A[7:1]};
				endcase
				case(fsm_of_des)
					RLC, 
					RL:begin
						F[0] <= A[7];     // C flag
						F[4] <= 1'b0;  // reset H flag
						F[1] <= 1'b0;  // reset N flag						
					end
					RRC,
					RR:begin
						F[0] <= A[0];    // C flag
						F[4] <= 1'b0;  // reset H flag
						F[1] <= 1'b0;  // reset N flag						
					end
				endcase
			end
			RS_REG:begin
				case(fsm_of_sou)
					8'd0: A <= ie_os_result;
					8'd1: B <= ie_os_result;
					8'd2: C <= ie_os_result;
					8'd3: D <= ie_os_result;
					8'd4: E <= ie_os_result;
					8'd6: H <= ie_os_result;
					8'd7: L <= ie_os_result;
				endcase
				F <= ie_os_flag_reg;
			end
			RS_MEM_HL:begin
				case(fsm_of_des)
					RLD_OP,
					RRD_OP:begin
						A <= ie_os_result_high;
					end
				endcase
				F <= ie_os_flag_reg;
			end
			RS_MEM_INDEX_IX,
			RS_MEM_INDEX_IY:begin
				F <= ie_os_flag_reg;
			end
			BM_TEST:begin
				F <= ie_os_flag_reg; 
			end
			BM_RESET, 
			BM_SET:begin
				case(fsm_of_des)
					8'd0: A <= ie_os_result;
					8'd1: B <= ie_os_result;
					8'd2: C <= ie_os_result;
					8'd3: D <= ie_os_result;
					8'd4: E <= ie_os_result;
					8'd6: H <= ie_os_result;
					8'd7: L <= ie_os_result;
				endcase				
			end
			BM_TEST_MEM_HL, BM_TEST_MEM_IX,
			BM_TEST_MEM_IY:begin
				F <= ie_os_flag_reg;
			end
			JUMP_DJNZ:begin
				B <= ie_os_result;
			end
			CALL:begin
				SP <= {ie_os_result_high, ie_os_result};
			end
			RETURN_FUNC:begin
				SP <= {ie_os_result_high, ie_os_result};
			end
			IN_MEM_EXTEND:begin
				A <= io_fetch_data;
			end
			IN_MEM_REG_IND:begin
				case(fsm_of_des)
					8'd0: A <= io_fetch_data;
					8'd1: B <= io_fetch_data;
					8'd2: C <= io_fetch_data;
					8'd3: D <= io_fetch_data;
					8'd4: E <= io_fetch_data;
					8'd6: H <= io_fetch_data;
					8'd7: L <= io_fetch_data;
				endcase	
			end
			INI, INIR, IND,
			INDR:begin
				case(le_counter)
					1'b0:begin
						B <= ie_os_result;
						F <= ie_os_flag_reg;
						le_counter <= 1'b1;
					end 
					1'b1:begin
						{H, L} <= {ie_os_result_high, ie_os_result};
						le_counter <= 1'b0;
					end 
				endcase
			end
			OUTI, OTIR, OUTD,
			OTDR:begin
				case(le_counter)
					1'b0:begin
						{H, L} <= {ie_os_result_high, ie_os_result};
						le_counter <= 1'b1;
					end 
					1'b1:begin
						B <= ie_os_result;
						F <= ie_os_flag_reg;
						le_counter <= 1'b0;
					end 
				endcase
			end
			LDI, LDIR, LDD,
			LDDR:begin
				case({le_counter_2, le_counter})
					2'b00:begin
						{B, C} <= {ie_os_result_high, ie_os_result};
						F <= ie_os_flag_reg;
						{le_counter_2, le_counter} <= 2'b01;
					end
					2'b01:begin
						{H, L} <= {ie_os_result_high, ie_os_result};
						{le_counter_2, le_counter} <= 2'b10;
					end
					2'b10:begin
						{D, E} <= {ie_os_result_high, ie_os_result};
						{le_counter_2, le_counter} <= 2'b00;
					end
					default:begin
						{le_counter_2, le_counter} <= 2'b00;
					end
				endcase
			end
			CPI, CPIR, CPD,
			CPDR:begin
				case({le_counter_2, le_counter})
					2'b00:begin
						{B, C} <= {ie_os_result_high, ie_os_result};
						F <= ie_os_flag_reg;
						{le_counter_2, le_counter} <= 2'b01;
					end
					2'b01:begin
						{H, L} <= {ie_os_result_high, ie_os_result};
						{le_counter_2, le_counter} <= 2'b10;
					end
					2'b10:begin
						F <= ie_os_flag_reg;
						{le_counter_2, le_counter} <= 2'b00;
					end
					default:begin
						{le_counter_2, le_counter} <= 2'b00;
					end
				endcase
			end
			NMI_INTERRUPT, INTERRUPT_MODE_1, INTERRUPT_MODE_2,
			INTERRUPT_MODE_0:begin
				SP <= {ie_os_result_high, ie_os_result};
			end
			RETI,
			RETN:begin
				SP <= {ie_os_result_high, ie_os_result};
			end
			default:begin
				le_counter <= 1'b0;
				le_counter_2 <= 1'b0;				
			end
		endcase
	end
end
//{S, Z, X_1, H, X_2, P_V, N, C};

endmodule

