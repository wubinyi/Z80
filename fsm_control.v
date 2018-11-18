// Company           :   tud                      
// Author            :   wubi17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   fsm_control.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Thu Aug 31 11:47:19 2017 
// Last Change       :   $Date: 2017-08-31 14:47:42 +0200 (Thu, 31 Aug 2017) $
// by                :   $Author: wubi17 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module fsm_control(
	clk,
	reset,
	int,
	nmi,
	halt_o,

	fsm_if_en,
	//if_fsm_instr,
	if_fsm_instr_finish,
	if_fsm_num_bytes,
	instruction,

	fsm_of_le_en,
	fsm_if_pc_modify,
	fsm_of_mem_rd,
	fsm_of_load_en,
	fsm_of_input,
	fsm_of_operation_type,
	fsm_of_des,
	fsm_of_sou,

	ie_fsm_flag_reg,
	fsm_ie_en,
	
	fsm_os_output,  // can not be deleted, used for cpu output signal
	fsm_os_mem_wr,
	fsm_os_IFF2,
	fsm_os_int

	//fsm_mem_bus_int
);
parameter FUN_WIDTH = 8;
// signal from system(outside)
input clk;
input reset;
input int;
input nmi;
output reg halt_o;
// signal connect with IF_DRIVER
output reg fsm_if_en;
input if_fsm_instr_finish;
//input [7:0] if_fsm_instr;
input [2:0] if_fsm_num_bytes;
input [31:0] instruction;
// signal connect with OF
output reg fsm_of_le_en;
output reg fsm_if_pc_modify;
output reg fsm_of_mem_rd;
output reg fsm_of_load_en;
output reg fsm_of_input;
output reg [7:0] fsm_of_operation_type;
output reg [7:0] fsm_of_des;
output reg [7:0] fsm_of_sou;
// signal connect with IE
output reg fsm_ie_en;
input [7:0] ie_fsm_flag_reg;
// signal connect with OS
output reg fsm_os_output;
output reg fsm_os_mem_wr;
output reg fsm_os_IFF2;
output reg fsm_os_int;
// signal connect with MEM
//output reg fsm_mem_bus_int; // pull down M1 signal in "mem_control" module, and control bus module

//----------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------
//=================================================================
//                         interrupt
//=================================================================
reg IFF1;            // internal reg
reg IFF2;            // internal reg
reg [1:0] int_mode;  // internal reg

parameter INT_MODE_0 = 2'd0;
parameter INT_MODE_1 = 2'd1;
parameter INT_MODE_2 = 2'd2;
//reg IFF_en;
reg nonmaskable_int;
reg maskable_int;
parameter NO_INTERRUPT  = 1'b0;
parameter NON_MASK_INT  = 1'b1;
parameter MASK_INT  = 1'b1;

//=================================================================
//                         flag register
//=================================================================
reg carry;  // carry
//reg N;  // add/substrate
reg parity; // parity/overflow flag
//reg H;  //half carry falg
reg zero;  // zero flag
reg sign;  // sign flag
//{S, Z, X_1, H, X_2, P_V, N, C};
always @* begin
	sign   = ie_fsm_flag_reg[7];
	parity = ie_fsm_flag_reg[2];
	zero   = ie_fsm_flag_reg[6];
	carry  = ie_fsm_flag_reg[0];
end

//=================================================================
//                  instruction combine (fetch)
//=================================================================
// always @(if_fsm_num_bytes or if_fsm_instr) begin
// 	case(if_fsm_num_bytes)
// 		3'd1:begin
// 			//instruction[31:8] <= 24'b0;
// 			//instruction[7:0] <= if_fsm_instr;
// 			instruction <= instruction | {24'h000000,if_fsm_instr};
// 		end
// 		3'd2: instruction <= instruction | {16'h0000,if_fsm_instr,8'h00};   //instruction[15:8] if_fsm_instr
// 		3'd3: instruction <= instruction | {8'h00,if_fsm_instr,16'h0000};   //instruction[23:16] if_fsm_instr;
// 		3'd4: instruction <= instruction | {if_fsm_instr,24'h000000};       //instruction[31:24] if_fsm_instr;
// 		default: instruction <= 32'h00000000;
// 	endcase
// end
// always @(if_fsm_num_bytes or if_fsm_instr) begin
// 	case(if_fsm_num_bytes)
// 		3'd1:begin
// 			//instruction[31:8] <= 24'b0;
// 			instruction[7:0] = if_fsm_instr;
// 		end
// 		3'd2: instruction[15:8] = if_fsm_instr;
// 		3'd3: instruction[23:16] = if_fsm_instr;
// 		3'd4: instruction[31:24] = if_fsm_instr;
// 		default: instruction = 32'h00000000;
// 	endcase
// end

//=================================================================================================================================
//=================================================================================================================================
//                                                    instruction decoder
//=================================================================================================================================
//=================================================================================================================================
// instruction table
parameter NO_FUNCTION                = 8'd0;
//=======================  8-bit load instruction =======================
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
parameter ADD_OP                     = 8'd1;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter ADC_OP                     = 8'd2;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter SUB_OP                     = 8'd3;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter SBC_OP                     = 8'd4;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter AND_OP                     = 8'd5;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter XOR_OP                     = 8'd6;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter OR_OP                      = 8'd7;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter CP_OP                      = 8'd8;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter INC_OP                     = 8'd9;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter DEC_OP                     = 8'd10; // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
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
parameter RLC_OP                     = 8'd17;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter RRC_OP                     = 8'd18;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter RL_OP                      = 8'd19;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter RR_OP                      = 8'd20;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter SLA_OP                     = 8'd21;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter SRA_OP                     = 8'd22;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter SRL_OP                     = 8'd23;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter RLD_OP                     = 8'd24;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter RRD_OP                     = 8'd25;  // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
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
parameter SET_BIT                    = 8'd26; // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
parameter RESET_BIT                  = 8'd27; // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
//parameter TEST_BIT                   = 8'd28; // same as operation table in "opera_fetch_opera_store"-'load to ie',  fsm_of_des
//======================= jump, call, return, reset =======================   
parameter NO_JUMP                    = 8'd82;  // function_sel
parameter JUMP_IMM                   = 8'd83;
parameter JUMP_REG_IND               = 8'd84;
parameter JUMP_RELATIVE              = 8'd85;
parameter JUMP_DJNZ                  = 8'd86;
parameter NO_CALL                    = 8'd87;  // function_sel
parameter CALL                       = 8'd88;
parameter NO_RETURN                  = 8'd89;  // function_sel
parameter RETURN_FUNC                = 8'd90;
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
parameter NOP                        = 8'd112;  // function_sel
parameter HALT                       = 8'd113;  // function_sel
parameter DINT                       = 8'd114;  // function_sel
parameter EINT                       = 8'd115;  // function_sel
parameter IM0                        = 8'd116;  // function_sel
parameter IM1                        = 8'd117;  // function_sel
parameter IM2                        = 8'd118;  // function_sel
//========================= interrupt =========================
parameter NMI_INTERRUPT              = 8'd119;  
parameter INTERRUPT_MODE_0           = 8'd120;
parameter INTERRUPT_MODE_1           = 8'd121;
parameter INTERRUPT_MODE_2           = 8'd122;
//========================= RETI RETN ========================= 
parameter RETI                       = 8'd123;
parameter RETN                       = 8'd124;     

reg [7:0] ofos_operation_type;
reg [FUN_WIDTH-1:0] function_sel;
always @(instruction or if_fsm_num_bytes or zero or carry or parity or sign) begin
// 	function_sel <= NO_FUNCTION;
// 	ofos_operation_type <= NO_FUNCTION;
// 	fsm_of_des <= 8'b0;
// 	fsm_of_sou <= 8'b0;
	case(if_fsm_num_bytes)
		//------------------------------------------------------------------------------------------------------------------------
		// *******************************  one byte instruction  ****************************************************************
		//------------------------------------------------------------------------------------------------------------------------
		3'd1: begin
			case(instruction[7:0])
				// =============   8-bit load: register to register =============
				8'h40,8'h41,8'h42,8'h43,8'h44,8'h45,8'h47,
				8'h48,8'h49,8'h4a,8'h4b,8'h4c,8'h4d,8'h4f,
				8'h50,8'h51,8'h52,8'h53,8'h54,8'h55,8'h57,
				8'h58,8'h59,8'h5a,8'h5b,8'h5c,8'h5d,8'h5f,
				8'h60,8'h61,8'h62,8'h63,8'h64,8'h65,8'h67,
				8'h68,8'h69,8'h6a,8'h6b,8'h6c,8'h6d,8'h6f,
				8'h78,8'h79,8'h7a,8'h7b,8'h7c,8'h7d,8'h7f: 
				begin
					ofos_operation_type = LOAD_REG2REG;
					function_sel = LOAD_REG2REG;
					case(instruction[5:3])
						3'b111: fsm_of_des = 8'd0;  // A
						3'b000: fsm_of_des = 8'd1;  // B
						3'b001: fsm_of_des = 8'd2;  // C
						3'b010: fsm_of_des = 8'd3;  // D
						3'b011: fsm_of_des = 8'd4;  // E
						3'b100: fsm_of_des = 8'd6;  // H
						3'b101: fsm_of_des = 8'd7;  // L
						default: fsm_of_des = 8'd0;
					endcase
					case(instruction[2:0])
						3'b111: fsm_of_sou = 8'd0;    // A
						3'b000: fsm_of_sou = 8'd1;    // B
						3'b001: fsm_of_sou = 8'd2;    // C
						3'b010: fsm_of_sou = 8'd3;    // D
						3'b011: fsm_of_sou = 8'd4;    // E
						3'b100: fsm_of_sou = 8'd6;    // H <-- F
						3'b101: fsm_of_sou = 8'd7;    // L
						default: fsm_of_sou = 8'd0;
					endcase
				end
				// ============   8-bit load: reg indirect(mem) to reg ============
				8'h7e,8'h46,8'h4e,8'h56,8'h5e,8'h66,8'h6e: 
				begin
					ofos_operation_type = LOAD_MEM2REG_REG_IND_HL;
					function_sel = LOAD_MEM2REG_REG_IND_HL;
					case(instruction[5:3])
						3'b111: fsm_of_des = 8'd0;  // A
						3'b000: fsm_of_des = 8'd1;  // B
						3'b001: fsm_of_des = 8'd2;  // C
						3'b010: fsm_of_des = 8'd3;  // D
						3'b011: fsm_of_des = 8'd4;  // E
						3'b100: fsm_of_des = 8'd6;  // H
						3'b101: fsm_of_des = 8'd7;  // L
						default: fsm_of_des = 8'd0;
					endcase	
					fsm_of_sou = 8'd0;   // unuseful
				end
				8'h0a: 
				begin
					ofos_operation_type = LOAD_MEM2REG_REG_IND_BC;
					function_sel = LOAD_MEM2REG_REG_IND_BC;
					fsm_of_des = 8'd0;  // A
					fsm_of_sou = 8'd0;   // unuseful
				end
				8'h1a: 
				begin
					ofos_operation_type = LOAD_MEM2REG_REG_IND_DE;
					function_sel = LOAD_MEM2REG_REG_IND_DE;
					fsm_of_des = 8'd0;  // A
					fsm_of_sou = 8'd0;   // unuseful
				end
				// ============   8-bit load: reg to reg indirect(mem) ============
				8'h70,8'h71,8'h72,8'h73,8'h74,8'h75,8'h77:
				begin
					ofos_operation_type = LOAD_REG2MEM_REG_IND_HL;
					function_sel = LOAD_REG2MEM_REG_IND_HL;
					case(instruction[2:0])
						3'b111: fsm_of_sou = 8'd0;    // A
						3'b000: fsm_of_sou = 8'd1;    // B
						3'b001: fsm_of_sou = 8'd2;    // C
						3'b010: fsm_of_sou = 8'd3;    // D
						3'b011: fsm_of_sou = 8'd4;    // E
						3'b100: fsm_of_sou = 8'd6;    // H <-- F
						3'b101: fsm_of_sou = 8'd7;    // L
						default: fsm_of_sou = 8'd0;
					endcase
					fsm_of_des = 8'd0;   // unuseful
				end
				8'h02: begin
					ofos_operation_type = LOAD_REG2MEM_REG_IND_BC;
					function_sel = LOAD_REG2MEM_REG_IND_BC;
					fsm_of_sou = 8'd0;  // A
					fsm_of_des = 8'd0;   // unuseful
				end
				8'h12:begin
					ofos_operation_type = LOAD_REG2MEM_REG_IND_DE;
					function_sel = LOAD_REG2MEM_REG_IND_DE;
					fsm_of_sou = 8'd0;  // A
					fsm_of_des = 8'd0;   // unuseful						
				end
				// ============   16-bit load: HL to SP ============
				8'hf9:begin
					ofos_operation_type = LOAD_16_BIT_HL2SP;
					function_sel = LOAD_16_BIT_HL2SP;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful						
				end
				// ============ 16-bit load: PUSH ============
				8'hf5,8'hc5,8'hd5,8'he5:begin
					case(instruction[5:4])
						2'b00: fsm_of_sou = REG_BC;
						2'b01: fsm_of_sou = REG_DE;
						2'b10: fsm_of_sou = REG_HL;
						2'b11: fsm_of_sou = REG_AF;
					endcase
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = PUSH;
					function_sel = PUSH;
				end
				// ============ 16-bit load: POP ============
				8'hf1,8'hc1,8'hd1,8'he1:begin
					case(instruction[5:4])
						2'b00: fsm_of_des = REG_BC;
						2'b01: fsm_of_des = REG_DE;
						2'b10: fsm_of_des = REG_HL;
						2'b11: fsm_of_des = REG_AF;
					endcase
					fsm_of_sou = 8'd0;   // unuseful
					ofos_operation_type = POP;
					function_sel = POP;
				end
				// ==================  exchange  ==================
				8'h08:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = EX_AF;
					function_sel = EX_AF;						
				end	
				8'hd9:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = EX_BC_DE_HL;
					function_sel = EX_BC_DE_HL;						
				end	
				8'heb:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = EX_HL_AND_DE;
					function_sel = EX_HL_AND_DE;						
				end	
				8'he3:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = EX_HL_AND_MEM_SP;
					function_sel = EX_HL_AND_MEM_SP;						
				end
				// ====================  arithmetic reg  ====================	
				8'h87, 8'h80, 8'h81, 8'h82, 8'h83, 8'h84, 8'h85,
				8'h8f, 8'h88, 8'h89, 8'h8a, 8'h8b, 8'h8c, 8'h8d,
				8'h97, 8'h90, 8'h91, 8'h92, 8'h93, 8'h94, 8'h95,
				8'h9f, 8'h98, 8'h99, 8'h9a, 8'h9b, 8'h9c, 8'h9d,
				8'ha7, 8'ha0, 8'ha1, 8'ha2, 8'ha3, 8'ha4, 8'ha5,
				8'haf, 8'ha8, 8'ha9, 8'haa, 8'hab, 8'hac, 8'had,
				8'hb7, 8'hb0, 8'hb1, 8'hb2, 8'hb3, 8'hb4, 8'hb5,
				8'hbf, 8'hb8, 8'hb9, 8'hba, 8'hbb, 8'hbc, 8'hbd:begin
					ofos_operation_type = OE_REG;
					function_sel = OE_REG;
					// here use fsm_of_des as operation indicator
					case(instruction[5:3])
						3'b000: fsm_of_des = ADD_OP;
						3'b001: fsm_of_des = ADC_OP;
						3'b010: fsm_of_des = SUB_OP;
						3'b011: fsm_of_des = SBC_OP;
						3'b100: fsm_of_des = AND_OP;
						3'b101: fsm_of_des = XOR_OP;
						3'b110: fsm_of_des = OR_OP;
						3'b111: fsm_of_des = CP_OP;
					endcase
					case(instruction[2:0])
						3'b111: fsm_of_sou = 8'd0;    // A
						3'b000: fsm_of_sou = 8'd1;    // B
						3'b001: fsm_of_sou = 8'd2;    // C
						3'b010: fsm_of_sou = 8'd3;    // D
						3'b011: fsm_of_sou = 8'd4;    // E
						3'b100: fsm_of_sou = 8'd6;    // H <-- F
						3'b101: fsm_of_sou = 8'd7;    // L
						default: fsm_of_sou = 8'd0;
					endcase
				end
				8'h3c, 8'h04, 8'h0c, 8'h14, 8'h1c, 8'h24, 8'h2c,
				8'h3d, 8'h05, 8'h0d, 8'h15, 8'h1d, 8'h25, 8'h2d:begin
					ofos_operation_type = OE_REG;
					function_sel = OE_REG;
					// here use fsm_of_des as operation indicator
					case(instruction[0])
						1'b0: fsm_of_des = INC_OP;
						1'b1: fsm_of_des = DEC_OP;
					endcase
					case(instruction[5:3])
						3'b111: fsm_of_sou = 8'd0;    // A 
						3'b000: fsm_of_sou = 8'd1;    // B
						3'b001: fsm_of_sou = 8'd2;    // C
						3'b010: fsm_of_sou = 8'd3;    // D
						3'b011: fsm_of_sou = 8'd4;    // E
						3'b100: fsm_of_sou = 8'd6;    // H <-- F
						3'b101: fsm_of_sou = 8'd7;    // L
						default: fsm_of_sou = 8'd0;   
					endcase
				end
				// ====================  arithmetic mem HL  ====================
				8'h86, 8'h8e, 8'h96, 8'h9e, 8'ha6, 8'hae, 8'hb6, 
				8'hbe:begin
					ofos_operation_type = OE_MEM_HL;
					function_sel = OE_MEM_HL;
					fsm_of_sou = 8'd0;   // unuseful
					// here use fsm_of_des as operation indicator
					case(instruction[5:3])
						3'b000: fsm_of_des = ADD_OP;
						3'b001: fsm_of_des = ADC_OP;
						3'b010: fsm_of_des = SUB_OP;
						3'b011: fsm_of_des = SBC_OP;
						3'b100: fsm_of_des = AND_OP;
						3'b101: fsm_of_des = XOR_OP;
						3'b110: fsm_of_des = OR_OP;
						3'b111: fsm_of_des = CP_OP;
					endcase
				end
				8'h34, 8'h35:begin
					ofos_operation_type = OE_MEM_HL_MEM;
					function_sel = OE_MEM_HL_MEM;
					fsm_of_sou = 8'd0;   // unuseful
					// here use fsm_of_des as operation indicator
					case(instruction[0])
						1'b0: fsm_of_des = INC_OP;
						1'b1: fsm_of_des = DEC_OP;
					endcase						
				end
				// ====================  16-BIT arithmetic ADD_OP ====================
				8'h09, 8'h19, 8'h29, 8'h39:begin
					ofos_operation_type = OE_ADD_16_BIT;
					function_sel = OE_ADD_16_BIT;
					case(instruction[5:4])
						2'b00: fsm_of_sou = REG_BC;
						2'b01: fsm_of_sou = REG_DE;
						2'b10: fsm_of_sou = REG_HL;
						2'b11: fsm_of_sou = REG_SP;
					endcase
					fsm_of_des = REG_HL;                    // HL
				end
				// ====================  16-BIT arithmetic INC_OP ====================
				8'h03, 8'h13, 8'h23, 8'h33:begin
					ofos_operation_type = OE_INC_16_BIT;
					function_sel = OE_INC_16_BIT;
					case(instruction[5:4])
						2'b00:begin
							fsm_of_sou = REG_BC;
							fsm_of_des = REG_BC;
						end 
						2'b01:begin
							fsm_of_sou = REG_DE;
							fsm_of_des = REG_DE;
						end 
						2'b10:begin
							fsm_of_sou = REG_HL;
							fsm_of_des = REG_HL;
						end 
						2'b11:begin
							fsm_of_sou = REG_SP;
							fsm_of_des = REG_SP;
						end 
					endcase
					//fsm_of_sou <= {6'b0, instruction[5:4]};   // BC, DE, HL, SP
					//fsm_of_des <= {6'b0, instruction[5:4]};   // BC, DE, HL, SP
				end
				// ====================  16-BIT arithmetic DEC_OP ====================
				8'h0b, 8'h1b, 8'h2b, 8'h3b:begin
					ofos_operation_type = OE_DEC_16_BIT;
					function_sel = OE_DEC_16_BIT;
					case(instruction[5:4])
						2'b00:begin
							fsm_of_sou = REG_BC;
							fsm_of_des = REG_BC;
						end 
						2'b01:begin
							fsm_of_sou = REG_DE;
							fsm_of_des = REG_DE;
						end 
						2'b10:begin
							fsm_of_sou = REG_HL;
							fsm_of_des = REG_HL;
						end 
						2'b11:begin
							fsm_of_sou = REG_SP;
							fsm_of_des = REG_SP;
						end 
					endcase
					//fsm_of_sou <= {6'b0, instruction[5:4]};   // BC, DE, HL, SP
					//fsm_of_des <= {6'b0, instruction[5:4]};   // BC, DE, HL, SP
				end
				// ====================  gerneral AF operation ====================
				8'h2f:begin // CPL
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = OE_CPL;
					function_sel = OE_CPL;
				end
				8'h3f:begin // CCF
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = OE_CCF;
					function_sel = OE_CCF;
				end
				8'h37:begin // SCF
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = OE_SCF;
					function_sel = OE_SCF;
				end
				// ====================== RLCA RRCA RLA RRA =======================
				8'h07, 8'h0f, 8'h17, 8'h1f:begin
					fsm_of_sou = 8'd0;   // unuseful
					case(instruction[4:3])
						2'b00: fsm_of_des = RLC_OP;
						2'b01: fsm_of_des = RRC_OP;
						2'b10: fsm_of_des = RL_OP;
						2'b11: fsm_of_des = RR_OP;
					endcase
					ofos_operation_type = RS_REG_A;
					function_sel = RS_REG_A;
				end
				// ====================== jump HL ======================= 
				8'he9:begin
					ofos_operation_type = JUMP_REG_IND;
					function_sel = JUMP_REG_IND;
					fsm_of_sou = REG_HL;
					fsm_of_des = 8'd0;   // unuseful
				end
				// ====================== return ======================= 
				8'hc9:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = RETURN_FUNC;
					function_sel = RETURN_FUNC;
				end
				8'hc0, 8'hc8:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					case({instruction[3], zero})
						2'b01, 2'b10:begin  // no jump
							function_sel = NO_RETURN;
							ofos_operation_type = NO_FUNCTION; // unuseful
						end
						2'b00, 2'b11:begin
							ofos_operation_type = RETURN_FUNC;
							function_sel = RETURN_FUNC;
						end
					endcase	
				end
				8'hd0, 8'hd8:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					case({instruction[3], carry})
						2'b01, 2'b10:begin  // no jump
							function_sel = NO_RETURN;
							ofos_operation_type = NO_FUNCTION; // unuseful
						end
						2'b00, 2'b11:begin
							ofos_operation_type = RETURN_FUNC;
							function_sel = RETURN_FUNC;
						end
					endcase	
				end
				8'he0, 8'he8:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					case({instruction[3], parity})
						2'b01, 2'b10:begin  // no jump
							function_sel = NO_RETURN;
							ofos_operation_type = NO_FUNCTION; // unuseful
						end
						2'b00, 2'b11:begin
							ofos_operation_type = RETURN_FUNC;
							function_sel = RETURN_FUNC;
						end
					endcase	
				end
				8'hf0, 8'hf8:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					case({instruction[3], sign})
						2'b01, 2'b10:begin  // no jump
							function_sel = NO_RETURN;
							ofos_operation_type = NO_FUNCTION; // unuseful
						end
						2'b00, 2'b11:begin
							ofos_operation_type = RETURN_FUNC;
							function_sel = RETURN_FUNC;
						end
					endcase	
				end
				// ====================== reset =======================
				8'hc7, 8'hcf, 8'hd7, 8'hdf, 8'he7, 8'hef, 8'hf7, 8'hff:begin
					ofos_operation_type = RST;
					function_sel = RST;
					case(instruction[5:3])
						3'b000: fsm_of_sou = 8'h00;
						3'b001: fsm_of_sou = 8'h08;
						3'b010: fsm_of_sou = 8'h10;
						3'b011: fsm_of_sou = 8'h18;
						3'b100: fsm_of_sou = 8'h20;
						3'b101: fsm_of_sou = 8'h28;
						3'b110: fsm_of_sou = 8'h30;
						3'b111: fsm_of_sou = 8'h38;
					endcase
					fsm_of_des = 8'd0;   // unuseful
				end
				// ====================== cpu control =======================
				8'h00:begin
					//ofos_operation_type = NOP;
					ofos_operation_type = NO_FUNCTION; // unuseful
					function_sel = NOP;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				8'h76:begin
					//ofos_operation_type = HALT;
					ofos_operation_type = NO_FUNCTION; // unuseful
					function_sel = HALT;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				8'hf3:begin
					//ofos_operation_type = DINT;
					ofos_operation_type = NO_FUNCTION; // unuseful
					function_sel = DINT;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					//IFF_en = 1'b0;
				end
				8'hfb:begin
					//ofos_operation_type = DINT;
					ofos_operation_type = NO_FUNCTION; // unuseful
					function_sel = EINT;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					//IFF_en = 1'b1;
				end
				default:begin
					function_sel = NO_FUNCTION;
					ofos_operation_type = NO_FUNCTION;
					fsm_of_des = 8'b0;
					fsm_of_sou = 8'b0;
				end
			endcase
		end
		//-------------------------------------------------------------------------------------------------------------------------
		// *******************************  two byte instruction  *****************************************************************
		//-------------------------------------------------------------------------------------------------------------------------
		3'd2:begin
			case(instruction[15:0])
				// ============   8-bit load group: register to Implied  ============
				16'h47ed:begin
					fsm_of_sou = 8'd0; // A
					fsm_of_des = 8'd8; // I
					ofos_operation_type = LOAD_REG2IMP;
					function_sel = LOAD_REG2IMP;
				end
				16'h4fed:begin
					fsm_of_sou = 8'd0; // A
					fsm_of_des = 8'd9; // R
					ofos_operation_type = LOAD_REG2IMP;
					function_sel = LOAD_REG2IMP;
				end
				// ===============   8-bit load: Implied to register ================
				16'h57ed:begin
					fsm_of_sou = 8'd8; // I
					fsm_of_des = 8'd0; // A
					ofos_operation_type = LOAD_IMP2REG;
					function_sel = LOAD_IMP2REG;
				end	
				16'h5fed:begin
					fsm_of_sou = 8'd9; // R
					fsm_of_des = 8'd0; // A
					ofos_operation_type = LOAD_IMP2REG;
					function_sel = LOAD_IMP2REG;
				end	
				// ============   16-bit load: IX to SP ============
				16'hf9dd:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = LOAD_16_BIT_IX2SP;
					function_sel = LOAD_16_BIT_IX2SP;
				end
				// ============   16-bit load: IY to SP ============
				16'hf9fd:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = LOAD_16_BIT_IY2SP;
					function_sel = LOAD_16_BIT_IY2SP;
				end
				// ============   16-bit PUSH: IX or IY to (SP) ============
				16'he5dd, 16'he5fd:begin
					case(instruction[5])
						1'b0: fsm_of_sou = REG_IX;
						1'b1: fsm_of_sou = REG_IY;
					endcase
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = PUSH;
					function_sel = PUSH;
				end
				// ============   16-bit POP: (SP) to IX or IY ============
				16'he1dd, 16'he1fd:begin
					case(instruction[5])
						1'b0: fsm_of_des = REG_IX;
						1'b1: fsm_of_des = REG_IY;
					endcase
					fsm_of_sou = 8'd0;   // unuseful
					ofos_operation_type = POP;
					function_sel = POP;
				end
				// ==================  exchange  ==================
				16'he3dd:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = EX_IX_AND_MEM_SP;
					function_sel = EX_IX_AND_MEM_SP;
				end
				16'he3fd:begin
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = EX_IY_AND_MEM_SP;
					function_sel = EX_IY_AND_MEM_SP;
				end
				// ====================  16-BIT arithmetic ADD_OP ====================
				16'h09dd, 16'h19dd, 16'h29dd, 16'h39dd:begin
					ofos_operation_type = OE_ADD_16_BIT;
					function_sel = OE_ADD_16_BIT;
					fsm_of_des = REG_IX; 	//IX// dd
					case(instruction[13:12])
						2'b00: fsm_of_sou = REG_BC; // BC
						2'b01: fsm_of_sou = REG_DE; // DE
						2'b10: fsm_of_sou = REG_IX; // IX
						2'b11: fsm_of_sou = REG_SP; // SP
					endcase
				end
				16'h09fd, 16'h19fd, 16'h29fd, 16'h39fd:begin
					ofos_operation_type = OE_ADD_16_BIT;
					function_sel = OE_ADD_16_BIT; 
					fsm_of_des = REG_IY; 	//IY// fd							
					case(instruction[13:12])
						2'b00: fsm_of_sou = REG_BC; // BC
						2'b01: fsm_of_sou = REG_DE; // DE
						2'b10: fsm_of_sou = REG_IY; // IY
						2'b11: fsm_of_sou = REG_SP; // SP
					endcase
				end
				// ====================  16-BIT arithmetic ADC_OP ====================
				16'h4aed, 16'h5aed, 16'h6aed, 16'h7aed:begin
					ofos_operation_type = OE_ADC_16_BIT;
					function_sel = OE_ADC_16_BIT;
					fsm_of_des = REG_HL;
					case(instruction[13:12])
						2'b00: fsm_of_sou = REG_BC; // BC
						2'b01: fsm_of_sou = REG_DE; // DE
						2'b10: fsm_of_sou = REG_HL; // HL
						2'b11: fsm_of_sou = REG_SP; // SP
					endcase
				end	
				// ====================  16-BIT arithmetic SBC_OP ====================				
				16'h42ed, 16'h52ed, 16'h62ed, 16'h72ed:begin
					ofos_operation_type = OE_SBC_16_BIT;
					function_sel = OE_SBC_16_BIT;
					fsm_of_des = REG_HL;
					case(instruction[13:12])
						2'b00: fsm_of_sou = REG_BC; // BC
						2'b01: fsm_of_sou = REG_DE; // DE
						2'b10: fsm_of_sou = REG_HL; // HL
						2'b11: fsm_of_sou = REG_SP; // SP
					endcase						
				end
				// ====================  16-BIT arithmetic INC_OP ====================
				16'h23dd, 16'h23fd:begin
					ofos_operation_type = OE_INC_16_BIT;
					function_sel = OE_INC_16_BIT;
					case(instruction[5])
						1'b0:begin
							fsm_of_des = REG_IX; // IX
							fsm_of_sou = REG_IX; // IX
						end 
						1'b1:begin
							fsm_of_des = REG_IY; // IY
							fsm_of_sou = REG_IY; // IY
						end 
					endcase						
				end
				// ====================  16-BIT arithmetic DEC_OP ====================
				16'h2bdd, 16'h2bfd:begin
					ofos_operation_type = OE_DEC_16_BIT;
					function_sel = OE_DEC_16_BIT;
					case(instruction[5])
						1'b0:begin
							fsm_of_des = REG_IX; // IX
							fsm_of_sou = REG_IX; // IX
						end 
						1'b1:begin
							fsm_of_des = REG_IY; // IY
							fsm_of_sou = REG_IY; // IY
						end 
					endcase						
				end
				// ====================  General Purpose AF Operation ====================
				16'h44ed:begin
					ofos_operation_type = OE_NEG;
					function_sel = OE_NEG;
					//fsm_ie_oper_sel = SUB_AF;
					//fsm_of_sou = 8'd0;
					//fsm_of_des = 8'd0;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				// ================  rotates and shift: mem HL  ===================
				16'h06cb, 16'h0ecb, 16'h16cb, 16'h1ecb,
				16'h26cb, 16'h2ecb, 16'h3ecb:begin
					ofos_operation_type = RS_MEM_HL;
					function_sel = RS_MEM_HL;
					case(instruction[13:11])
						3'b000: fsm_of_des = RLC_OP;
						3'b001: fsm_of_des = RRC_OP;
						3'b010: fsm_of_des = RL_OP;
						3'b011: fsm_of_des = RR_OP;
						3'b100: fsm_of_des = SLA_OP;
						3'b101: fsm_of_des = SRA_OP;
						//3'b110:
						3'b111: fsm_of_des = SRL_OP;
						default: fsm_of_des = 8'd0;
					endcase	
					fsm_of_sou = 8'd0;   // unuseful					
				end
				16'h6fed, 16'h67ed:begin
					ofos_operation_type = RS_MEM_HL;
					function_sel = RS_MEM_HL;
					case(instruction[11])
						1'b0: fsm_of_des = RRD_OP;
						1'b1: fsm_of_des = RLD_OP;
					endcase
					fsm_of_sou = 8'd0;   // unuseful
				end
				// ===========  bit manipulation group: test set reset, reg and (HL) ============
				16'h40cb, 16'h41cb, 16'h42cb, 16'h43cb, 16'h44cb, 16'h45cb, 16'h47cb,
				16'h48cb, 16'h49cb, 16'h4acb, 16'h4bcb, 16'h4ccb, 16'h4dcb, 16'h4fcb,
				16'h50cb, 16'h51cb, 16'h52cb, 16'h53cb, 16'h54cb, 16'h55cb, 16'h57cb,
				16'h58cb, 16'h59cb, 16'h5acb, 16'h5bcb, 16'h5ccb, 16'h5dcb, 16'h5fcb,
				16'h60cb, 16'h61cb, 16'h62cb, 16'h63cb, 16'h64cb, 16'h65cb, 16'h67cb,
				16'h68cb, 16'h69cb, 16'h6acb, 16'h6bcb, 16'h6ccb, 16'h6dcb, 16'h6fcb,
				16'h70cb, 16'h71cb, 16'h72cb, 16'h73cb, 16'h74cb, 16'h75cb, 16'h77cb,
				16'h78cb, 16'h79cb, 16'h7acb, 16'h7bcb, 16'h7ccb, 16'h7dcb, 16'h7fcb,
				16'h80cb, 16'h81cb, 16'h82cb, 16'h83cb, 16'h84cb, 16'h85cb, 16'h87cb,
				16'h88cb, 16'h89cb, 16'h8acb, 16'h8bcb, 16'h8ccb, 16'h8dcb, 16'h8fcb,
				16'h90cb, 16'h91cb, 16'h92cb, 16'h93cb, 16'h94cb, 16'h95cb, 16'h97cb,
				16'h98cb, 16'h99cb, 16'h9acb, 16'h9bcb, 16'h9ccb, 16'h9dcb, 16'h9fcb,
				16'ha0cb, 16'ha1cb, 16'ha2cb, 16'ha3cb, 16'ha4cb, 16'ha5cb, 16'ha7cb,
				16'ha8cb, 16'ha9cb, 16'haacb, 16'habcb, 16'haccb, 16'hadcb, 16'hafcb,
				16'hb0cb, 16'hb1cb, 16'hb2cb, 16'hb3cb, 16'hb4cb, 16'hb5cb, 16'hb7cb,
				16'hb8cb, 16'hb9cb, 16'hbacb, 16'hbbcb, 16'hbccb, 16'hbdcb, 16'hbfcb,
				16'hc0cb, 16'hc1cb, 16'hc2cb, 16'hc3cb, 16'hc4cb, 16'hc5cb, 16'hc7cb,
				16'hc8cb, 16'hc9cb, 16'hcacb, 16'hcbcb, 16'hcccb, 16'hcdcb, 16'hcfcb,
				16'hd0cb, 16'hd1cb, 16'hd2cb, 16'hd3cb, 16'hd4cb, 16'hd5cb, 16'hd7cb,
				16'hd8cb, 16'hd9cb, 16'hdacb, 16'hdbcb, 16'hdccb, 16'hddcb, 16'hdfcb,
				16'he0cb, 16'he1cb, 16'he2cb, 16'he3cb, 16'he4cb, 16'he5cb, 16'he7cb,
				16'he8cb, 16'he9cb, 16'heacb, 16'hebcb, 16'heccb, 16'hedcb, 16'hefcb,
				16'hf0cb, 16'hf1cb, 16'hf2cb, 16'hf3cb, 16'hf4cb, 16'hf5cb, 16'hf7cb,
				16'hf8cb, 16'hf9cb, 16'hfacb, 16'hfbcb, 16'hfccb, 16'hfdcb, 16'hffcb:begin
					case(instruction[15:14])
						2'b01:begin
							function_sel = BM_TEST;
							ofos_operation_type = BM_TEST;
							//fsm_ie_oper_sel = TEST_BIT;
						end 
						2'b10:begin
							function_sel = BM_RESET;
							ofos_operation_type = BM_RESET;
							//fsm_ie_oper_sel = RESET_BIT;
						end 
						2'b11:begin
							function_sel = BM_SET;
							ofos_operation_type = BM_SET;
							//fsm_ie_oper_sel = SET_BIT;
						end 
						default:begin
							function_sel = NO_FUNCTION;
							ofos_operation_type = NO_FUNCTION;							
						end
					endcase
					case(instruction[10:8])
						3'b111: fsm_of_des = 8'd0;    // A
						3'b000: fsm_of_des = 8'd1;    // B
						3'b001: fsm_of_des = 8'd2;    // C
						3'b010: fsm_of_des = 8'd3;    // D
						3'b011: fsm_of_des = 8'd4;    // E
						3'b100: fsm_of_des = 8'd6;    // H <-- F
						3'b101: fsm_of_des = 8'd7;    // L
						default: fsm_of_des = 8'd0;
					endcase
					fsm_of_sou = {5'b00000, instruction[13:11]};
					/*case(instruction[13:11])
						3'b000: fsm_of_sou = 8'd0;    // bit 0
						3'b001: fsm_of_sou = 8'd1;    // bit 1
						3'b010: fsm_of_sou = 8'd2;    // bit 2
						3'b011: fsm_of_sou = 8'd3;    // bit 3
						3'b100: fsm_of_sou = 8'd4;    // bit 4
						3'b101: fsm_of_sou = 8'd5;    // bit 5
						3'b110: fsm_of_sou = 8'd6;    // bit 6
						3'b111: fsm_of_sou = 8'd7;    // bit 7
					endcase*/
				end
				16'h46cb, 16'h4ecb, 16'h56cb, 16'h5ecb, 16'h66cb, 16'h6ecb, 16'h76cb, 16'h7ecb,
				16'h86cb, 16'h8ecb, 16'h96cb, 16'h9ecb, 16'ha6cb, 16'haecb, 16'hb6cb, 16'hbecb,
				16'hc6cb, 16'hcecb, 16'hd6cb, 16'hdecb, 16'he6cb, 16'heecb, 16'hf6cb, 16'hfecb:begin
					case(instruction[15:14])
						2'b01:begin
							function_sel = BM_TEST_MEM_HL;
							ofos_operation_type = BM_TEST_MEM_HL;
							//fsm_ie_oper_sel = TEST_BIT;
							fsm_of_des = 8'd0;   // unuseful
						end 
						2'b10:begin
							function_sel = BM_SET_RESET_MEM_HL;
							ofos_operation_type = BM_SET_RESET_MEM_HL;
							fsm_of_des = RESET_BIT;
						end 
						2'b11:begin
							function_sel = BM_SET_RESET_MEM_HL;
							ofos_operation_type = BM_SET_RESET_MEM_HL;
							fsm_of_des = SET_BIT;
						end 
						default:begin
							function_sel = NO_FUNCTION;
							ofos_operation_type = NO_FUNCTION;
							fsm_of_des = 8'd0;							
						end
					endcase	
					fsm_of_sou = {5'b00000, instruction[13:11]};					
				end
				// ============= jump: IX IY =============
				16'he9fd, 16'he9dd:begin
					ofos_operation_type = JUMP_REG_IND;
					function_sel = JUMP_REG_IND;
					case(instruction[5])
						1'b0: fsm_of_sou = REG_IX;
						1'b1: fsm_of_sou = REG_IY;
					endcase
					fsm_of_des = 8'd0;   // unuseful
				end
				// =============  input group: input reg ind. to reg  ==============
				16'h40ed, 16'h48ed, 16'h50ed, 16'h58ed, 16'h60ed, 16'h68ed, 16'h78ed:begin
					ofos_operation_type = IN_MEM_REG_IND;
					function_sel = IN_MEM_REG_IND;
					case(instruction[13:11])
						3'b111: fsm_of_des = 8'd0;    // A
						3'b000: fsm_of_des = 8'd1;    // B
						3'b001: fsm_of_des = 8'd2;    // C
						3'b010: fsm_of_des = 8'd3;    // D
						3'b011: fsm_of_des = 8'd4;    // E
						3'b100: fsm_of_des = 8'd6;    // H <-- F
						3'b101: fsm_of_des = 8'd7;    // L
						default: fsm_of_des = 8'd0;
					endcase
					fsm_of_sou = 8'd0;   // unuseful
				end
				// =============  input group: ini,inir,ind,indr  ============== 
				16'ha2ed:begin
					ofos_operation_type = INI;
					function_sel = INI;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'hb2ed:begin
					ofos_operation_type = INIR;
					function_sel = INIR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'haaed:begin
					ofos_operation_type = IND;
					function_sel = IND;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'hbaed:begin
					ofos_operation_type = INDR;
					function_sel = INDR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				// =============  output group: reg to input reg ind.  ==============
				16'h41ed, 16'h49ed, 16'h51ed, 16'h59ed, 16'h61ed, 16'h69ed, 16'h79ed:begin
					ofos_operation_type = OUT_MEM_REG_IND;
					function_sel = OUT_MEM_REG_IND;
					case(instruction[13:11])
						3'b111: fsm_of_sou = 8'd0;    // A
						3'b000: fsm_of_sou = 8'd1;    // B
						3'b001: fsm_of_sou = 8'd2;    // C
						3'b010: fsm_of_sou = 8'd3;    // D
						3'b011: fsm_of_sou = 8'd4;    // E
						3'b100: fsm_of_sou = 8'd6;    // H <-- F
						3'b101: fsm_of_sou = 8'd7;    // L
						default: fsm_of_sou = 8'd0;
					endcase	
					fsm_of_des = 8'd0;   // unuseful					
				end
				// =============  output group: outi,otir,outd,otdr  ============== 
				16'ha3ed:begin
					ofos_operation_type = OUTI;
					function_sel = OUTI;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'hb3ed:begin
					ofos_operation_type = OTIR;
					function_sel = OTIR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'habed:begin
					ofos_operation_type = OUTD;
					function_sel = OUTD;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'hbbed:begin
					ofos_operation_type = OTDR;
					function_sel = OTDR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				// ========  block transfer group: lidi,ldir,ldd,lddr  =========
				16'ha0ed:begin
					ofos_operation_type = LDI;
					function_sel = LDI;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'hb0ed:begin
					ofos_operation_type = LDIR;
					function_sel = LDIR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'ha8ed:begin
					ofos_operation_type = LDD;
					function_sel = LDD;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				16'hb8ed:begin
					ofos_operation_type = LDDR;
					function_sel = LDDR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				// ========  block search group: cpi, cpir, cpd, cpdr  =========
				16'ha1ed:begin
					ofos_operation_type = CPI;
					function_sel = CPI;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					//fsm_ie_oper_sel = BS_COMPARE;
				end
				16'hb1ed:begin
					ofos_operation_type = CPIR;
					function_sel = CPIR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					//fsm_ie_oper_sel = BS_COMPARE;
				end
				16'ha9ed:begin
					ofos_operation_type = CPD;
					function_sel = CPD;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					//fsm_ie_oper_sel = BS_COMPARE;
				end
				16'hb9ed:begin
					ofos_operation_type = CPDR;
					function_sel = CPDR;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					//fsm_ie_oper_sel = BS_COMPARE;
				end
				// ====================== cpu control =======================
				16'h46ed:begin
					function_sel = IM0;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = NO_FUNCTION; //unuseful
					//int_mode = INT_MODE_0;
				end
				16'h56ed:begin
					function_sel = IM1;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = NO_FUNCTION; //unuseful
					//int_mode = INT_MODE_1;
				end
				16'h5eed:begin
					function_sel = IM2;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = NO_FUNCTION; //unuseful
					//int_mode = INT_MODE_2;
				end
				// ====================== RETI RETN =======================
				16'h4ded:begin
					function_sel = RETI;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
					ofos_operation_type = RETI;
				end
				16'h45ed:begin
					function_sel = RETN;
					ofos_operation_type = RETN;
					fsm_of_sou = 8'd0;   // unuseful
					fsm_of_des = 8'd0;   // unuseful
				end
				default:begin
					case(instruction[7:0])
						// =============   8-bit load: imm. to register =============
						8'h3e,8'h06,8'h0e,8'h16,8'h1e,8'h26,8'h2e:
						begin
							ofos_operation_type = LOAD_IMM2REG;
							function_sel = LOAD_IMM2REG;
							case(instruction[5:3])
								3'b111: fsm_of_des = 8'd0;    // A
								3'b000: fsm_of_des = 8'd1;    // B
								3'b001: fsm_of_des = 8'd2;    // C
								3'b010: fsm_of_des = 8'd3;    // D
								3'b011: fsm_of_des = 8'd4;    // E
								3'b100: fsm_of_des = 8'd6;    // H
								3'b101: fsm_of_des = 8'd7;    // L
								default: fsm_of_des = 8'd0;
							endcase
							fsm_of_sou = instruction[15:8];
						end
						// =============   8-bit load: imm. to reg indirect =============
						8'h36:begin
							ofos_operation_type = LOAD_IMM2MEM_REG_IND;
							function_sel = LOAD_IMM2MEM_REG_IND;
							fsm_of_sou = instruction[15:8];
							fsm_of_des = 8'd0;   // unuseful
						end
						// =====================   8-bit arithmetic ======================
						8'hc6, 8'hce, 8'hd6, 8'hde, 8'he6, 8'hee, 8'hf6, 8'hfe:begin
							ofos_operation_type = OE_IMM;
							function_sel = OE_IMM;			
							fsm_of_sou = instruction[15:8];
							case(instruction[5:3])
								3'b000: fsm_of_des = ADD_OP;
								3'b001: fsm_of_des = ADC_OP;
								3'b010: fsm_of_des = SUB_OP;
								3'b011: fsm_of_des = SBC_OP;
								3'b100: fsm_of_des = AND_OP;
								3'b101: fsm_of_des = XOR_OP;
								3'b110: fsm_of_des = OR_OP;
								3'b111: fsm_of_des = CP_OP;
							endcase					
						end
						// =================  rotates and shift: reg  ====================
						8'hcb:begin
							ofos_operation_type = RS_REG;
							function_sel = RS_REG;
							case(instruction[13:11])
								3'b000: fsm_of_des = RLC_OP;
								3'b001: fsm_of_des = RRC_OP;
								3'b010: fsm_of_des = RL_OP;
								3'b011: fsm_of_des = RR_OP;
								3'b100: fsm_of_des = SLA_OP;
								3'b101: fsm_of_des = SRA_OP;
								//3'b110:
								3'b111: fsm_of_des = SRL_OP;
								default: fsm_of_des = 8'd0;
							endcase
							case(instruction[10:8])
								3'b111: fsm_of_sou = 8'd0;    // A
								3'b000: fsm_of_sou = 8'd1;    // B
								3'b001: fsm_of_sou = 8'd2;    // C
								3'b010: fsm_of_sou = 8'd3;    // D
								3'b011: fsm_of_sou = 8'd4;    // E
								3'b100: fsm_of_sou = 8'd6;    // H
								3'b101: fsm_of_sou = 8'd7;    // L
								default: fsm_of_sou = 8'd0;
							endcase
						end
						// =================  jump relative  ====================
						8'h18:begin  // unconditional jump
							ofos_operation_type = JUMP_RELATIVE;
							function_sel = JUMP_RELATIVE;
							fsm_of_sou = instruction[15:8];
							fsm_of_des = 8'd0;   // unuseful
							//fsm_ie_oper_sel = ADD_16BIT_NONE_AFFECT;
						end
						8'h20, 8'h28, 8'h30, 8'h38:begin
							case({instruction[4:3], carry, zero})
								4'b0000, 4'b0010,
								4'b0101, 4'b0111,
								4'b1000, 4'b1001,
								4'b1110, 4'b1111:begin  // jump
									ofos_operation_type = JUMP_RELATIVE;
									function_sel = JUMP_RELATIVE;
									fsm_of_sou = instruction[15:8];
									fsm_of_des = 8'd0;   // unuseful
									//fsm_ie_oper_sel = ADD_16BIT_NONE_AFFECT;
								end
								4'b0001, 4'b0011,
								4'b0100, 4'b0110,
								4'b1010, 4'b1011,
								4'b1100, 4'b1101:begin  // do not jump
									ofos_operation_type = NO_JUMP;
									function_sel = NO_JUMP;
									fsm_of_sou = 8'd0;   // unuseful
									fsm_of_des = 8'd0;   // unuseful
								end
							endcase
						end
						// =================  jump djnz  ====================
						8'h10:begin
							ofos_operation_type = JUMP_DJNZ;
							function_sel = JUMP_DJNZ;
							fsm_of_sou = instruction[15:8];
							//fsm_ie_oper_sel = ADD_16BIT_NONE_AFFECT;	
							fsm_of_des = 8'd0;   // unuseful							
						end
						// =============  input group: input mem. extend to A  ==============
						8'hdb:begin
							ofos_operation_type = IN_MEM_EXTEND;
							function_sel = IN_MEM_EXTEND;
							fsm_of_sou = instruction[15:8];
							fsm_of_des = 8'd0;   // unuseful
						end
						// =============  output group: A to input mem. extend  ==============
						8'hd3:begin
							ofos_operation_type = OUT_MEM_EXTEND;
							function_sel = OUT_MEM_EXTEND;
							fsm_of_des = instruction[15:8];
							fsm_of_sou = 8'd0;   // unuseful
						end
						default:begin
							function_sel = NO_FUNCTION;
							ofos_operation_type = NO_FUNCTION;
							fsm_of_des = 8'b0;
							fsm_of_sou = 8'b0;
						end
					endcase			
				end		
			endcase
			
		end
		//--------------------------------------------------------------------------------------------------------------------------
		// ******************************  three byte instruction  *****************************************************************
		//--------------------------------------------------------------------------------------------------------------------------
		3'd3: begin
			case(instruction[15:0])
				// =============   8-bit load: indexed(mem) to reg ============
				16'h7edd,16'h46dd,16'h4edd,16'h56dd,16'h5edd,16'h66dd,16'h6edd:begin
					fsm_of_sou = instruction[23:16]; // d
					case(instruction[13:11])
						3'b111: fsm_of_des = 8'd0;    // A
						3'b000: fsm_of_des = 8'd1;    // B
						3'b001: fsm_of_des = 8'd2;    // C
						3'b010: fsm_of_des = 8'd3;    // D
						3'b011: fsm_of_des = 8'd4;    // E
						3'b100: fsm_of_des = 8'd6;    // H
						3'b101: fsm_of_des = 8'd7;    // L
						default: fsm_of_des = 8'd0; 
					endcase
					ofos_operation_type = LOAD_MEM2REG_INDEXED_IX;
					function_sel = LOAD_MEM2REG_INDEXED_IX;
				end
				16'h7efd,16'h46fd,16'h4efd,16'h56fd,16'h5efd,16'h66fd,16'h6efd:begin
					fsm_of_sou = instruction[23:16]; // d
					case(instruction[13:11])
						3'b111: fsm_of_des = 8'd0;    // A
						3'b000: fsm_of_des = 8'd1;    // B
						3'b001: fsm_of_des = 8'd2;    // C
						3'b010: fsm_of_des = 8'd3;    // D
						3'b011: fsm_of_des = 8'd4;    // E
						3'b100: fsm_of_des = 8'd6;    // H
						3'b101: fsm_of_des = 8'd7;    // L
						default: fsm_of_des = 8'd0; 
					endcase
					ofos_operation_type = LOAD_MEM2REG_INDEXED_IY;
					function_sel = LOAD_MEM2REG_INDEXED_IY;		
				end
				// =============   8-bit load: reg to indexed(mem)============
				16'h77dd,16'h70dd,16'h71dd,16'h72dd,16'h73dd,16'h74dd,16'h75dd:begin
					ofos_operation_type = LOAD_REG2MEM_INDEXED_IX;
					function_sel = LOAD_REG2MEM_INDEXED_IX;
					fsm_of_des = instruction[23:16]; // d	
					case(instruction[10:8])
						3'b111: fsm_of_sou = 8'd0;    // A
						3'b000: fsm_of_sou = 8'd1;    // B
						3'b001: fsm_of_sou = 8'd2;    // C
						3'b010: fsm_of_sou = 8'd3;    // D
						3'b011: fsm_of_sou = 8'd4;    // E
						3'b100: fsm_of_sou = 8'd6;    // H <-- F
						3'b101: fsm_of_sou = 8'd7;    // L
						default: fsm_of_sou = 8'd0; 
					endcase					
				end
				16'h77fd,16'h70fd,16'h71fd,16'h72fd,16'h73fd,16'h74fd,16'h75fd:begin
					ofos_operation_type = LOAD_REG2MEM_INDEXED_IY;
					function_sel = LOAD_REG2MEM_INDEXED_IY;
					fsm_of_des = instruction[23:16]; // d	
					case(instruction[10:8])
						3'b111: fsm_of_sou = 8'd0;    // A
						3'b000: fsm_of_sou = 8'd1;    // B
						3'b001: fsm_of_sou = 8'd2;    // C
						3'b010: fsm_of_sou = 8'd3;    // D
						3'b011: fsm_of_sou = 8'd4;    // E
						3'b100: fsm_of_sou = 8'd6;    // H <-- F
						3'b101: fsm_of_sou = 8'd7;    // L
						default: fsm_of_sou = 8'd0; 
					endcase					
				end
				// =========================   8-bit arithmetic ======================== 
				16'h86dd,16'h8edd,16'h96dd,16'h9edd,16'ha6dd,16'haedd,16'hb6dd,16'hbedd:begin
					ofos_operation_type = OE_MEM_INDEX_IX;
					function_sel = OE_MEM_INDEX_IX;
					fsm_of_sou = instruction[23:16]; // d
					// use fsm_of_des as indicator
					case(instruction[13:11])
						3'b000: fsm_of_des = ADD_OP;
						3'b001: fsm_of_des = ADC_OP;
						3'b010: fsm_of_des = SUB_OP;
						3'b011: fsm_of_des = SBC_OP;
						3'b100: fsm_of_des = AND_OP;
						3'b101: fsm_of_des = XOR_OP;
						3'b110: fsm_of_des = OR_OP;
						3'b111: fsm_of_des = CP_OP;
					endcase
				end
				16'h86fd,16'h8efd,16'h96fd,16'h9efd,16'ha6fd,16'haefd,16'hb6fd,16'hbefd:begin
					ofos_operation_type = OE_MEM_INDEX_IY;
					function_sel = OE_MEM_INDEX_IY;
					fsm_of_sou = instruction[23:16]; // d
					// use fsm_of_des as indicator
					case(instruction[13:11])
						3'b000: fsm_of_des = ADD_OP;
						3'b001: fsm_of_des = ADC_OP;
						3'b010: fsm_of_des = SUB_OP;
						3'b011: fsm_of_des = SBC_OP;
						3'b100: fsm_of_des = AND_OP;
						3'b101: fsm_of_des = XOR_OP;
						3'b110: fsm_of_des = OR_OP;
						3'b111: fsm_of_des = CP_OP;
					endcase
				end
				16'h34dd, 16'h35dd:begin
					ofos_operation_type = OE_MEM_INDEX_MEM_IX;
					function_sel = OE_MEM_INDEX_MEM_IX;
					fsm_of_sou = instruction[23:16]; // d	
					// use fsm_of_des as indicator
					if (instruction[8]) begin
						fsm_of_des = DEC_OP;
					end
					else begin
						fsm_of_des = INC_OP;
					end	
				end
				16'h34fd, 16'h35fd:begin
					ofos_operation_type = OE_MEM_INDEX_MEM_IY;
					function_sel = OE_MEM_INDEX_MEM_IY;
					fsm_of_sou = instruction[23:16]; // d	
					// use fsm_of_des as indicator
					if (instruction[8]) begin
						fsm_of_des = DEC_OP;
					end
					else begin
						fsm_of_des = INC_OP;
					end					
				end
				default:begin
					fsm_of_sou = instruction[15:8];  // n  low
					fsm_of_des = instruction[23:16]; // n  high						
					case(instruction[7:0])
						// =============   8-bit load: ext.(mem) to reg  ============
						8'h3a: begin
							//fsm_of_sou = instruction[15:8];  // n  low
							//fsm_of_des = instruction[23:16]; // n  high
							ofos_operation_type = LOAD_MEM2REG_EXT;
							function_sel = LOAD_MEM2REG_EXT;
						end
						// =============   8-bit load: reg(A) to indexed(mem)  ============
						8'h32: begin
							//fsm_of_sou = instruction[15:8];  // n  low
							//fsm_of_des = instruction[23:16]; // n  high
							ofos_operation_type = LOAD_REG2MEM_EXT;
							function_sel = LOAD_REG2MEM_EXT;
						end
						// =================   16-bit load: imm. to BC  ===================
						8'h01: begin
							//fsm_of_sou = instruction[15:8];  // n  low
							//fsm_of_des = instruction[23:16]; // n  high
							ofos_operation_type = LOAD_16_BIT_IMM2BC;
							function_sel = LOAD_16_BIT_IMM2BC;
						end
						// =================   16-bit load: imm. to DE  ===================
						8'h11: begin
							//fsm_of_sou = instruction[15:8];  // n  low
							//fsm_of_des = instruction[23:16]; // n  high
							ofos_operation_type = LOAD_16_BIT_IMM2DE;
							function_sel = LOAD_16_BIT_IMM2DE;
						end
						// =================   16-bit load: imm. to HL  ===================
						8'h21: begin
							//fsm_of_sou = instruction[15:8];  // n  low
							//fsm_of_des = instruction[23:16]; // n  high
							ofos_operation_type = LOAD_16_BIT_IMM2HL;
							function_sel = LOAD_16_BIT_IMM2HL;
						end
						// =================   16-bit load: imm. to SP  ===================
						8'h31: begin
							//fsm_of_sou = instruction[15:8];  // n  low
							//fsm_of_des = instruction[23:16]; // n  high
							ofos_operation_type = LOAD_16_BIT_IMM2SP;
							function_sel = LOAD_16_BIT_IMM2SP;
						end
						// =================   16-bit load: ext.(mem) to HL  ===================
						8'h2a: begin
							//fsm_of_sou = instruction[15:8];  // n  low
							//fsm_of_des = instruction[23:16]; // n  high
							ofos_operation_type = LOAD_16_BIT_MEM2HL_EXT;
							function_sel = LOAD_16_BIT_MEM2HL_EXT;
						end
						// =================   16-bit load:HL to ext.(mem)   ===================
						8'h22:begin
							ofos_operation_type = LOAD_16_BIT_HL2MEM_EXT;
							function_sel = LOAD_16_BIT_HL2MEM_EXT;
						end
						// =================   jump imm.   ===================
						8'hc3:begin
							ofos_operation_type = JUMP_IMM;
							function_sel = JUMP_IMM;
						end
						8'hc2, 8'hca:begin
							case({instruction[3], zero})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = JUMP_IMM;
									function_sel = JUMP_IMM;
								end
							endcase
						end
						8'hd2, 8'hda:begin
							case({instruction[3], carry})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = JUMP_IMM;
									function_sel = JUMP_IMM;
								end
							endcase								
						end
						8'he2, 8'hea:begin
							case({instruction[3], parity})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = JUMP_IMM;
									function_sel = JUMP_IMM;
								end
							endcase								
						end
						8'hf2, 8'hfa:begin
							case({instruction[3], sign})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = JUMP_IMM;
									function_sel = JUMP_IMM;
								end
							endcase								
						end
						// =================   call imm.   ===================
						8'hcd:begin
							ofos_operation_type = CALL;
							function_sel = CALL;
							//fsm_ie_oper_sel = SUB_OP;
						end
						8'hc4, 8'hcc:begin
							case({instruction[3], zero})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = CALL;
									function_sel = CALL;
									//fsm_ie_oper_sel = SUB_OP;
								end
							endcase								
						end
						8'hd4, 8'hdc:begin
							case({instruction[3], carry})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = CALL;
									function_sel = CALL;
									//fsm_ie_oper_sel = SUB_OP;
								end
							endcase								
						end
						8'he4, 8'hec:begin
							case({instruction[3], parity})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = CALL;
									function_sel = CALL;
									//fsm_ie_oper_sel = SUB_OP;
								end
							endcase								
						end	
						8'hf4, 8'hfc:begin
							case({instruction[3], sign})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type = NO_FUNCTION;  // unuseful
									function_sel = NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type = CALL;
									function_sel = CALL;
									//fsm_ie_oper_sel = SUB_OP;
								end
							endcase								
						end
						default:begin
							function_sel = NO_FUNCTION;
							ofos_operation_type = NO_FUNCTION;
						end	
					endcase
				end				
			endcase
		end
		//---------------------------------------------------------------------------------------------------------------------------
		// *******************************  four byte instruction  ******************************************************************
		//---------------------------------------------------------------------------------------------------------------------------
		3'd4: begin
			case(instruction[15:0])
				// =============   8-bit load: imm. to index.(mem)  ============
				16'h36dd, 16'h36fd:begin
					fsm_of_sou = instruction[31:24];
					fsm_of_des = instruction[23:16];						
				end
				16'hcbdd, 16'hcbfd:begin   
					case(instruction[31:30])
						2'b00:begin// rotates and shift
							fsm_of_sou = instruction[23:16];
							case(instruction[29:27])
								3'b000: fsm_of_des = RLC_OP;
								3'b001: fsm_of_des = RRC_OP;
								3'b010: fsm_of_des = RL_OP;
								3'b011: fsm_of_des = RR_OP;
								3'b100: fsm_of_des = SLA_OP;
								3'b101: fsm_of_des = SRA_OP;
								//3'b110:
								3'b111: fsm_of_des = SRL_OP;
								default: fsm_of_des = 8'd0;
							endcase								
						end
						2'b01, 2'b10,
						2'b11:begin 
							fsm_of_sou = {5'b00000, instruction[29:27]};
							fsm_of_des = instruction[23:16];									
						end
					endcase	
				end
				default:begin
					fsm_of_sou = instruction[23:16];
					fsm_of_des = instruction[31:24];
				end
			endcase
			case(instruction[15:0])
				// =============   8-bit load: imm. to indexed(mem)============
				16'h36dd:begin
					//fsm_of_sou = instruction[31:24];
					//fsm_of_des = instruction[23:16];
					ofos_operation_type = LOAD_IMM2MEM_INDEXED_IX;
					function_sel = LOAD_IMM2MEM_INDEXED_IX;
				end
				16'h36fd:begin
					//fsm_of_sou = instruction[31:24];
					//fsm_of_des = instruction[23:16];
					ofos_operation_type = LOAD_IMM2MEM_INDEXED_IY;
					function_sel = LOAD_IMM2MEM_INDEXED_IY;
				end
				// =================   16-bit load: imm. to indexed(mem)  ===================
				16'h21dd:begin
					//fsm_of_sou = instruction[23:16];
					//fsm_of_des = instruction[31:24];
					ofos_operation_type = LOAD_16_BIT_IMM2IX;
					function_sel = LOAD_16_BIT_IMM2IX;
				end
				16'h21fd:begin
					//fsm_of_sou = instruction[23:16];
					//fsm_of_des = instruction[31:24];
					ofos_operation_type = LOAD_16_BIT_IMM2IY;
					function_sel = LOAD_16_BIT_IMM2IY;
				end
				// =================   16-bit load: ext.(mem) to reg(BC, DE, SP, IX, IY)  ===================
				16'h4bed:begin
					ofos_operation_type = LOAD_16_BIT_MEM2BC_EXT;
					function_sel = LOAD_16_BIT_MEM2BC_EXT;
				end 
				16'h5bed:begin
					ofos_operation_type = LOAD_16_BIT_MEM2DE_EXT;
					function_sel = LOAD_16_BIT_MEM2DE_EXT;
				end 
				16'h7bed:begin
					ofos_operation_type = LOAD_16_BIT_MEM2SP_EXT;
					function_sel = LOAD_16_BIT_MEM2SP_EXT;
				end 
				16'h2add:begin
					ofos_operation_type = LOAD_16_BIT_MEM2IX_EXT;
					function_sel = LOAD_16_BIT_MEM2IX_EXT;
				end 
				16'h2afd:begin
					ofos_operation_type = LOAD_16_BIT_MEM2IY_EXT;
					function_sel = LOAD_16_BIT_MEM2IY_EXT;
				end
				// =================   16-bit load: reg(BC, DE, SP, IX, IY) to ext.(mem)  ===================
				16'h43ed:begin
					ofos_operation_type = LOAD_16_BIT_BC2MEM_EXT;
					function_sel = LOAD_16_BIT_BC2MEM_EXT;
				end 
				16'h53ed:begin
					ofos_operation_type = LOAD_16_BIT_DE2MEM_EXT;
					function_sel = LOAD_16_BIT_DE2MEM_EXT;
				end 
				16'h73ed:begin
					ofos_operation_type = LOAD_16_BIT_SP2MEM_EXT;
					function_sel = LOAD_16_BIT_SP2MEM_EXT;
				end 
				16'h22dd:begin
					ofos_operation_type = LOAD_16_BIT_IX2MEM_EXT;
					function_sel = LOAD_16_BIT_IX2MEM_EXT;
				end 
				16'h22fd:begin
					ofos_operation_type = LOAD_16_BIT_IY2MEM_EXT;
					function_sel = LOAD_16_BIT_IY2MEM_EXT;
				end
				// ==================================   rotates and shift  ====================================
				16'hcbdd:begin
					case(instruction[31:30])
						2'b00:begin
							ofos_operation_type = RS_MEM_INDEX_IX;
							function_sel = RS_MEM_INDEX_IX;								
						end
						2'b01:begin
							ofos_operation_type = BM_TEST_MEM_IX;
							function_sel = BM_TEST_MEM_IX;
						end
						2'b10:begin
							ofos_operation_type = BM_RESET_MEM_IX;
							function_sel = BM_RESET_MEM_IX;
						end 
						2'b11:begin
							ofos_operation_type = BM_SET_MEM_IX;
							function_sel = BM_SET_MEM_IX;
						end
					endcase
				end
				16'hcbfd:begin
					case(instruction[31:30])
						2'b00:begin
							ofos_operation_type = RS_MEM_INDEX_IY;
							function_sel = RS_MEM_INDEX_IY;								
						end
						2'b01:begin
							ofos_operation_type = BM_TEST_MEM_IY;
							function_sel = BM_TEST_MEM_IY;								
						end
						2'b10:begin
							ofos_operation_type = BM_RESET_MEM_IY;
							function_sel = BM_RESET_MEM_IY;								
						end 
						2'b11:begin
							ofos_operation_type = BM_SET_MEM_IY;
							function_sel = BM_SET_MEM_IY;									
						end
					endcase

				end
				default:begin
					function_sel = NO_FUNCTION;
					ofos_operation_type = NO_FUNCTION;					
				end
			endcase
		end
		default:begin
			function_sel = NO_FUNCTION;
			ofos_operation_type = NO_FUNCTION;
			fsm_of_des = 8'b0;
			fsm_of_sou = 8'b0;
		end
	endcase
end

reg [7:0] nmi_int_ofos_operation_type;
reg fsm_nmi_int;
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		nmi_int_ofos_operation_type <= 8'b0;
		fsm_nmi_int <= 1'b0;		
	end
	else begin
		case({nonmaskable_int, maskable_int})
			2'b00:begin
				if(fsm_nmi_int == 1'b1) begin
					if (if_fsm_instr_finish) begin
						fsm_nmi_int <= 1'b0;
					end
				end
				else begin
					fsm_nmi_int <= 1'b0;
				end
			end 
			2'b01:begin
				fsm_nmi_int <= 1'b1;
				case(int_mode)
					INT_MODE_0:begin
						nmi_int_ofos_operation_type <= INTERRUPT_MODE_0;
					end
					INT_MODE_1:begin
						nmi_int_ofos_operation_type <= INTERRUPT_MODE_1;
					end
					INT_MODE_2:begin
						nmi_int_ofos_operation_type <= INTERRUPT_MODE_2;
					end
					default: nmi_int_ofos_operation_type <= NO_FUNCTION;
				endcase
			end
			2'b10,2'b11:begin
				fsm_nmi_int <= 1'b1;
				nmi_int_ofos_operation_type <= NMI_INTERRUPT;
			end
		endcase
	end
end
always @(ofos_operation_type or nmi_int_ofos_operation_type or fsm_nmi_int) begin
	case(fsm_nmi_int)
		1'b0: fsm_of_operation_type = ofos_operation_type;
		1'b1: fsm_of_operation_type = nmi_int_ofos_operation_type;
	endcase
end

//=================================================================================================================================
//=================================================================================================================================
//                                                  fsm control
//=================================================================================================================================
//=================================================================================================================================
// internal register
reg [7:0] current_state;
reg [7:0] next_state;
// state table
parameter RESET_STATE                     = 8'd0;
parameter INS_FETCH_INITIAL               = 8'd1;
parameter INS_FETCH_DECODE                = 8'd2;
//parameter INS_DECODE                      = 8'd3;
parameter REGISTER_LOAD                   = 8'd4;
parameter MEM_READ_1_1                    = 8'd5;
parameter MEM_READ_1_2                    = 8'd6;
parameter MEM_WRITE_1_1                   = 8'd7;
parameter MEM_WRITE_1_2                   = 8'd8;
parameter LOAD_OPERAND                    = 8'd9;
parameter ALU_EXCUTION                    = 8'd10;
// add with 16-bit load instruction
parameter MEM_READ_2_1_AND_ALU_EXCUTION   = 8'd11;
parameter MEM_READ_2_2_AND_LOAD_OPERAND   = 8'd12;
parameter MEM_WRITE_2_1_AND_ALU_EXCUTION  = 8'd13;
parameter MEM_WRITE_2_2_AND_LOAD_OPERAND  = 8'd14;
parameter MEM_WRITE_1_2_AND_REGISTER_LOAD = 8'd15;  // especially for push, oe_mem_hl_mem
parameter MEM_READ_1_1_AND_ALU_EXCUTION   = 8'd16;
parameter MEM_READ_1_2_AND_LOAD_OPERAND   = 8'd17;
// add with exchange
parameter MEM_READ_2_2                    = 8'd18;
parameter MEM_READ_2_1                    = 8'd19;
parameter MEM_WRITE_1_1_AND_REGISTER_LOAD = 8'd20;
// add with 8-bit arithmetic ang logic
parameter LOAD_OPERAND_AGAIN              = 8'd21;
parameter ALU_EXCUTION_AGAIN              = 8'd22;
// add with jump call return and reset
parameter REGISTER_PC_LOAD                = 8'd23;
parameter REGISTER_LOAD_AND_ZERO_JUDGE    = 8'd24;
parameter LOAD_OPERAND_CLEAR              = 8'd25;
parameter MEM_WRITE_1_2_AND_REG_LOAD      = 8'd26;
parameter MEM_WRITE_1_1_AND_REG_PC_LOAD   = 8'd27;
parameter REG_PC_LOAD_AND_REG_LOAD        = 8'd28;
// add with input group
parameter INPUT_4                         = 8'd29;
parameter INPUT_3                         = 8'd30;
parameter INPUT_2                         = 8'd31;
parameter INPUT_1                         = 8'd32;
parameter INPUT_3_AND_LOAD_OPERAND        = 8'd33;
parameter INPUT_2_AND_ALU_EXCUTION        = 8'd34;
parameter INPUT_1_AND_REGISTER_LOAD       = 8'd35;
parameter MEM_WRITE_1_2_AND_LOAD_OPERAND  = 8'd36;
parameter MEM_WRITE_1_1_AND_ALU_EXCUTION  = 8'd37;
parameter REGISTER_LOAD_AND_REPEAT_JUDGE  = 8'd38;
// add with output group
parameter OUTPUT_4                        = 8'd39;
parameter OUTPUT_3                        = 8'd40;
parameter OUTPUT_2                        = 8'd41;
parameter OUTPUT_1                        = 8'd42;
parameter OUTPUT_4_AND_REGISTER_LOAD      = 8'd43;
parameter OUTPUT_3_AND_LOAD_OPERAND       = 8'd44;
parameter OUTPUT_2_AND_ALU_EXCUTION       = 8'd45;
parameter OUTPUT_1_AND_REGISTER_LOAD      = 8'd46;
parameter OUTPUT_1_AND_REG_LOAD_AND_REPEAT_JUDGE            = 8'd47;
// add with block transfer group
parameter MEM_READ_1_1_AND_ALU_EXCUTION_AND_LOAD_OPERAND    = 8'd48;
parameter MEM_WRITE_1_2_AND_REGISTER_LOAD_AND_ALU_EXCUTION  = 8'd49;
parameter MEM_WRITE_1_1_AND_REGISTER_LOAD_AND_LOAD_OPERAND  = 8'd50;
parameter ALU_EXCUTION_THIRD_TIME                           = 8'd51;
parameter REGISTER_LOAD_THIRD_TIME                          = 8'd52;
parameter REGISTER_LOAD_AND_REPEAT_JUDGE_AND_LOAD_OPERAND   = 8'd53;
parameter ALU_EXCUTION_FOURTH_TIME                          = 8'd54;
// add with block search group
parameter REGISTER_LOAD_AND_ALU_EXCUTION                    = 8'd55;
parameter REGISTER_LOAD_AND_LOAD_OPERAND                    = 8'd56;
// add with CPU control
parameter NOP_STATE                                         = 8'd57;
parameter HALT_STATE                                        = 8'd58;
parameter RESET_IFF                                         = 8'd59;
parameter SET_IFF                                           = 8'd60;
// state about interrupt
              // nmi
parameter NMI_LOAD_OPERAND                                  = 8'd61;
parameter NMI_ALU_EXCUTION_AND_IFF                          = 8'd62;
parameter NMI_INT_MEM_WRITE_2_2_AND_LOAD_OPERAND            = 8'd63;
parameter NMI_INT_MEM_WRITE_2_1_AND_ALU_EXCUTION            = 8'd64;
parameter NMI_INT_MEM_WRITE_1_2_AND_REGISTER_LOAD           = 8'd65;
parameter NMI_INT_MEM_WRITE_1_1_AND_REGISTER_PC_LOAD        = 8'd66;  
              // int mode 1
parameter INT_LOAD_OPERAND                                  = 8'd67;  
parameter INT_ALU_EXCUTION_AND_IFF                          = 8'd68; 
              // int mode 2
parameter INT_LOAD_OPERAND_AND_INPUT_4                      = 8'd69;
parameter INT_ALU_EXCUTION_AND_INPUT_3_AND_IFF              = 8'd70;
parameter INT_MEM_WRITE_2_2_AND_LOAD_OPERAND_AND_INPUT_2    = 8'd71;
parameter INT_MEM_WRITE_2_1_AND_ALU_EXCUTION_AND_INPUT_1    = 8'd72; 
              // int mode 0
parameter INT_INS_FETCH_INITIAL                             = 8'd73; 
//parameter INT_INS_FETCH                                     = 8'd74; 
parameter INT_MEM_WRITE_1_1                                 = 8'd74;   
parameter MEM_READ_2_2_AND_LOAD_OPERAND_AND_IFF             = 8'd75;  
              // int for LD A I and LD A R
//parameter INT_LOAD_OPERAND_AND_LOAD_A_IR                    = 8'd77;
//parameter INT_LOAD_OPERAND_AND_INPUT_4_AND_LOAD_A_IR        = 8'd78;  
//parameter NMI_LOAD_OPERAND_AND_LOAD_A_IR                    = 8'd79;              


//  {fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output}
parameter IDLE                 = 9'b0_00000_0_00;
parameter IF_DRIVER            = 9'b1_00000_0_00;
parameter ID                   = 9'b0_00000_0_00;
parameter AL                   = 9'b0_00000_1_00;   // arithmetic and logic
parameter DATA2IE              = 9'b0_00010_0_00;   // load data to IE
parameter MEMWR                = 9'b0_00000_0_10;   // write memory
parameter MEMRD                = 9'b0_00100_0_00;   // read memory
parameter REGWR                = 9'b0_01000_0_00;   // write register
parameter MEMRD_DATA2IE        = 9'b0_00110_0_00;   // read memory and load data to IE
parameter MEMRD_AL             = 9'b0_00100_1_00;   // read memory and (arithmetic and logic)
parameter MEMWR_DATA2IE        = 9'b0_00010_0_10;   // write memory and load data to IE
parameter MEMWR_AL             = 9'b0_00000_1_10;   // write memory and (arithmetic and logic) 
parameter MEMWR_REGWR          = 9'b0_01000_0_10;   // write memory and register
parameter DATA2IF              = 9'b0_10000_0_00;   // load data to IF_DRIVER
parameter MEMWR_DATA2IF        = 9'b0_11000_0_10;   // write memory, (load data to IF_DRIVER)change PC, write registers
parameter DATA2IF_REGWR        = 9'b0_11000_0_00;   // load data to IF_DRIVER, write registers
parameter IN_DRIVER            = 9'b0_00001_0_00;   // input
parameter IN_DATA2IE           = 9'b0_00011_0_00;   // input and load data to IE
parameter IN_AL                = 9'b0_00001_1_00;   // input and arithmetic and logic
parameter IN_REGWR             = 9'b0_01001_0_00;   // input and write register
parameter OUT_DRIVER           = 9'b0_00000_0_01;   // output
parameter OUT_REGWR            = 9'b0_01000_0_01;   // output and write register
parameter OUT_DATA2IE          = 9'b0_00010_0_01;   // output and load data to IE
parameter OUT_AL               = 9'b0_00000_1_01;   // output and arithmetic and logic
parameter MEMRD_AL_DATA2IE     = 9'b0_00110_1_00;   // read memory and (arithmetic and logic) and load data to IE
parameter MEMWR_REGWR_AL       = 9'b0_01000_1_10;   // write memory and register and (arithmetic and logic)
parameter MEMWR_REGWR_DATA2IE  = 9'b0_01010_0_10;   // write memory and register
parameter REGWR_DATA2IE        = 9'b0_01010_0_00;   // write register and load data to IE  
parameter REGWR_AL             = 9'b0_01000_1_00;   // write register and (arithmetic and logic)
parameter DATA2IE_IN           = 9'b0_00011_0_00;   // load data to IE and input
parameter AL_IN                = 9'b0_00001_1_00;   // arithmetic and logic and input
parameter MEMWR_DATA2IE_IN     = 9'b0_00011_0_10;   // write memory and load data to IE and input
parameter MEMWR_AL_IN          = 9'b0_00001_1_10;   // write memory and arithmetic and logic and input
parameter NO_MEM_RD            = 9'b1_11111_1_11;   // do not read memory
parameter NO_MEM_WR            = 9'b1_11111_1_11;   // do not write memory


always @(posedge clk or negedge reset) begin
	if(!reset) begin
		current_state <= RESET_STATE;
		//current_state_pos <= RESET_STATE;
	end
	else begin
		case({nonmaskable_int, maskable_int})
			2'b00:begin
				current_state <= next_state;
				//current_state_pos <= next_state;
			end 
			2'b01:begin
				case(int_mode)
					INT_MODE_0:begin
						current_state <= INT_LOAD_OPERAND;
						//current_state_pos <= INT_LOAD_OPERAND;
					end
					INT_MODE_1:begin
						current_state <= INT_LOAD_OPERAND;
						//current_state_pos <= INT_LOAD_OPERAND;
					end
					INT_MODE_2:begin
						current_state <= INT_LOAD_OPERAND_AND_INPUT_4;
						//current_state_pos <= INT_LOAD_OPERAND_AND_INPUT_4;
					end
				endcase
			end
			2'b10,2'b11:begin
				current_state <= NMI_LOAD_OPERAND;
				//current_state_pos <= NMI_LOAD_OPERAND;
			end
		endcase
	end
end

wire decode_en;
assign decode_en = if_fsm_instr_finish;
always @(current_state or decode_en or function_sel or zero or parity or nmi_int_ofos_operation_type) begin
	case(current_state)
		RESET_STATE:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IDLE;
			next_state = INS_FETCH_INITIAL;		
		end
		INS_FETCH_INITIAL:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IF_DRIVER;
			next_state = INS_FETCH_DECODE;				
		end
		INS_FETCH_DECODE: begin
			case (decode_en)
			1'b1:begin
				{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = ID;
				//next_state = INS_DECODE;
				case(function_sel)
					// 8-bit load
					LOAD_REG2REG, LOAD_REG2IMP, LOAD_IMP2REG,
					LOAD_IMM2REG:begin
						next_state = REGISTER_LOAD;
					end
					LOAD_MEM2REG_REG_IND_DE, LOAD_MEM2REG_REG_IND_BC, LOAD_MEM2REG_REG_IND_HL,
					LOAD_MEM2REG_EXT:begin
						next_state = MEM_READ_1_2;
					end
					LOAD_REG2MEM_REG_IND_DE, LOAD_REG2MEM_REG_IND_BC, LOAD_REG2MEM_REG_IND_HL,
					LOAD_IMM2MEM_REG_IND,
					LOAD_REG2MEM_EXT:begin
						next_state = MEM_WRITE_1_2;
					end
					LOAD_MEM2REG_INDEXED_IX, 
					LOAD_MEM2REG_INDEXED_IY:begin
						next_state = LOAD_OPERAND;
					end
					LOAD_REG2MEM_INDEXED_IX, LOAD_REG2MEM_INDEXED_IY, LOAD_IMM2MEM_INDEXED_IX,
					LOAD_IMM2MEM_INDEXED_IY:begin
						next_state = LOAD_OPERAND;
					end
					// 16-bit load
					LOAD_16_BIT_HL2SP, LOAD_16_BIT_IX2SP, LOAD_16_BIT_IY2SP, LOAD_16_BIT_IMM2BC,
					LOAD_16_BIT_IMM2DE, LOAD_16_BIT_IMM2HL, LOAD_16_BIT_IMM2SP, LOAD_16_BIT_IMM2IX,
					LOAD_16_BIT_IMM2IY:begin
						next_state = REGISTER_LOAD;
					end
					LOAD_16_BIT_MEM2BC_EXT, LOAD_16_BIT_MEM2DE_EXT, LOAD_16_BIT_MEM2HL_EXT, 
					LOAD_16_BIT_MEM2SP_EXT, LOAD_16_BIT_MEM2IX_EXT, 
					LOAD_16_BIT_MEM2IY_EXT:begin
						next_state = MEM_READ_2_2_AND_LOAD_OPERAND;
					end
					LOAD_16_BIT_BC2MEM_EXT, LOAD_16_BIT_DE2MEM_EXT, LOAD_16_BIT_HL2MEM_EXT, 
					LOAD_16_BIT_SP2MEM_EXT, LOAD_16_BIT_IX2MEM_EXT, 
					LOAD_16_BIT_IY2MEM_EXT:begin
						next_state = MEM_WRITE_2_2_AND_LOAD_OPERAND;
					end	
					PUSH:begin
						next_state = LOAD_OPERAND;
					end	
					POP:begin
						next_state = MEM_READ_2_2_AND_LOAD_OPERAND;
					end
					// exchange
					EX_AF, EX_BC_DE_HL, 
					EX_HL_AND_DE:begin
						next_state = REGISTER_LOAD;
					end	
					EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP,
					EX_IY_AND_MEM_SP:begin
						next_state = MEM_READ_2_2;
					end
					// 8-bit arithmetic and logic
					OE_REG:begin
						next_state = LOAD_OPERAND;
					end	
					OE_MEM_HL:begin
						next_state = MEM_READ_1_2;
					end	
					OE_MEM_HL_MEM:begin
						next_state = MEM_READ_1_2;
					end
					OE_MEM_INDEX_IX,
					OE_MEM_INDEX_IY:begin
						next_state = LOAD_OPERAND;
					end
					OE_MEM_INDEX_MEM_IX, 
					OE_MEM_INDEX_MEM_IY:begin
						next_state = LOAD_OPERAND;
					end
					OE_IMM:begin
						next_state = LOAD_OPERAND;
					end
					// 16-bit arithmetic
					OE_ADD_16_BIT, OE_ADC_16_BIT, OE_SBC_16_BIT, OE_INC_16_BIT,
					OE_DEC_16_BIT:begin
						next_state = LOAD_OPERAND;
					end
					// Gerneral Purpose AF Operation
					OE_CPL, OE_CCF,
					OE_SCF:begin
						next_state = REGISTER_LOAD;
					end
					OE_NEG: next_state = LOAD_OPERAND;
					// Rotates and Shifts
					RS_REG_A:begin
						next_state = REGISTER_LOAD;
					end
					RS_REG:begin
						next_state = LOAD_OPERAND;
					end
					RS_MEM_HL:begin
						next_state = MEM_READ_1_2;
					end
					RS_MEM_INDEX_IX,
					RS_MEM_INDEX_IY:begin
						next_state = LOAD_OPERAND;
					end
					// bit manipulation
					BM_SET, BM_RESET,
					BM_TEST:begin
						next_state = LOAD_OPERAND;
					end
					BM_SET_RESET_MEM_HL:begin
						next_state = MEM_READ_1_2;
					end
					BM_TEST_MEM_HL:begin
						next_state = MEM_READ_1_2;
					end
					BM_SET_MEM_IX, BM_RESET_MEM_IX, BM_SET_MEM_IY,
					BM_RESET_MEM_IY:begin
						next_state = LOAD_OPERAND;
					end
					BM_TEST_MEM_IX, 
					BM_TEST_MEM_IY:begin
						next_state = LOAD_OPERAND;
					end
					// jump call return reset
					NO_JUMP,
					NO_CALL,
					NO_RETURN:begin
						next_state = INS_FETCH_INITIAL;
					end	
					JUMP_IMM:begin
						next_state = REGISTER_PC_LOAD;
					end
					JUMP_REG_IND:begin
						next_state = REGISTER_PC_LOAD;
					end	
					JUMP_RELATIVE:begin
						next_state = LOAD_OPERAND;
					end	
					JUMP_DJNZ:begin
						next_state = LOAD_OPERAND;
					end
					CALL:begin
						next_state = LOAD_OPERAND;
					end
					RETURN_FUNC:begin
						next_state = MEM_READ_2_2_AND_LOAD_OPERAND;
					end
					RST:begin
						next_state = LOAD_OPERAND;
					end
					// input group
					IN_MEM_EXTEND:begin
						next_state = INPUT_4;
					end
					IN_MEM_REG_IND:begin
						next_state = INPUT_4;
					end
					INI:begin
						next_state = INPUT_4;
					end
					INIR:begin
						next_state = INPUT_4;
					end
					IND:begin
						next_state = INPUT_4;
					end
					INDR:begin
						next_state = INPUT_4;
					end
					// output group
					OUT_MEM_EXTEND:begin
						next_state = OUTPUT_4;
					end
					OUT_MEM_REG_IND:begin
						next_state = OUTPUT_4;
					end
					OUTI:begin
						next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
					end
					OUTD:begin
						next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
					end
					OTIR:begin
						next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
					end
					OTDR:begin
						next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
					end
					// block transfer group
					LDI,
					LDD:begin
						next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
					end
					LDIR,
					LDDR:begin
						next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
					end
					// block search group
					CPI, CPD, CPIR,
					CPDR:begin
						next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
					end
					// CPU control
					NOP:begin
						next_state = NOP_STATE;
					end
					HALT:begin
						next_state = HALT_STATE;
					end
					DINT:begin
						next_state = RESET_IFF;
					end
					EINT:begin
						next_state = SET_IFF;
					end
					IM0, IM1,
					IM2:begin
						next_state = INS_FETCH_INITIAL;
					end
					// RETI RETN
					RETI:begin
						next_state = MEM_READ_2_2_AND_LOAD_OPERAND;
					end
					RETN:begin
						next_state = MEM_READ_2_2_AND_LOAD_OPERAND_AND_IFF;
					end
					default: next_state = INS_FETCH_DECODE;
				endcase				
			end
			1'b0:begin
				{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IF_DRIVER;
				next_state = INS_FETCH_DECODE;
			end
			endcase
		end 
		REGISTER_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = REGWR;
			next_state = INS_FETCH_INITIAL;
		end
		MEM_READ_1_2:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD;
			next_state = MEM_READ_1_1;
		end
		MEM_READ_1_1:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD & NO_MEM_RD;
			case(function_sel)
				EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP,
				EX_IY_AND_MEM_SP:begin
					next_state = MEM_WRITE_1_2;
				end
				OE_MEM_HL, 
				OE_MEM_HL_MEM:begin
					next_state = LOAD_OPERAND;
				end
				OE_MEM_INDEX_IX, OE_MEM_INDEX_IY, OE_MEM_INDEX_MEM_IX,
				OE_MEM_INDEX_MEM_IY:begin
					next_state = LOAD_OPERAND_AGAIN;
				end
				RS_MEM_HL:begin
					next_state = LOAD_OPERAND;
				end
				RS_MEM_INDEX_IX,
				RS_MEM_INDEX_IY:begin
					next_state = LOAD_OPERAND_AGAIN;
				end
				BM_SET_RESET_MEM_HL,
				BM_TEST_MEM_HL:begin
					next_state = LOAD_OPERAND;
				end
				BM_SET_MEM_IX, BM_RESET_MEM_IX, BM_SET_MEM_IY,
				BM_RESET_MEM_IY:begin
					next_state = LOAD_OPERAND_AGAIN;
				end
				BM_TEST_MEM_IX, 
				BM_TEST_MEM_IY:begin
					next_state = LOAD_OPERAND_AGAIN;
				end
				default: next_state = REGISTER_LOAD;
			endcase
		end
		MEM_WRITE_1_2:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR;
			case(function_sel)
				EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP,
				EX_IY_AND_MEM_SP:begin
					next_state = MEM_WRITE_1_1_AND_REGISTER_LOAD;
				end
				RST:begin
					next_state = MEM_WRITE_1_1_AND_REG_PC_LOAD;
				end	
				default: next_state = MEM_WRITE_1_1;				
			endcase
		end
		MEM_WRITE_1_1:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR & NO_MEM_WR;
			next_state = INS_FETCH_INITIAL;
		end
		LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IE;
			next_state = ALU_EXCUTION;
		end
		ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = AL;
			case(function_sel)
				LOAD_REG2MEM_INDEXED_IX, LOAD_REG2MEM_INDEXED_IY, LOAD_IMM2MEM_INDEXED_IX,
				LOAD_IMM2MEM_INDEXED_IY:begin
					next_state = MEM_WRITE_1_2;
				end
				PUSH:begin
					next_state = MEM_WRITE_2_2_AND_LOAD_OPERAND;
				end
				OE_REG,
				OE_MEM_HL:begin
					next_state = REGISTER_LOAD;
				end
				OE_MEM_HL_MEM:begin
					next_state = MEM_WRITE_1_2_AND_REGISTER_LOAD;
				end
				OE_MEM_INDEX_IX, OE_MEM_INDEX_IY, OE_MEM_INDEX_MEM_IX,
				OE_MEM_INDEX_MEM_IY:begin
					next_state = MEM_READ_1_2;
				end
				OE_IMM:begin
					next_state = REGISTER_LOAD;
				end
				OE_ADD_16_BIT, OE_ADC_16_BIT, OE_SBC_16_BIT, OE_INC_16_BIT,
				OE_DEC_16_BIT:begin
					next_state = REGISTER_LOAD;
				end
				OE_NEG: next_state = REGISTER_LOAD;
				RS_REG:begin
					next_state = REGISTER_LOAD;
				end
				RS_MEM_HL:begin
					next_state = MEM_WRITE_1_2_AND_REGISTER_LOAD;
				end
				BM_TEST, BM_RESET,
				BM_SET:begin
					next_state = REGISTER_LOAD;
				end
				BM_SET_RESET_MEM_HL:begin
					next_state = MEM_WRITE_1_2;
				end
				BM_TEST_MEM_HL:begin
					next_state = REGISTER_LOAD;
				end
				JUMP_RELATIVE:begin
					next_state = REGISTER_PC_LOAD;
				end
				JUMP_DJNZ:begin
					next_state = REGISTER_LOAD_AND_ZERO_JUDGE;
				end
				CALL:begin
					next_state = MEM_WRITE_2_2_AND_LOAD_OPERAND;
				end
				RST:begin
					next_state = MEM_WRITE_2_2_AND_LOAD_OPERAND;
				end
				INIR,
				INDR:begin
					next_state = REGISTER_PC_LOAD;
				end
				OTIR,
				OTDR:begin
					next_state = REGISTER_PC_LOAD;
				end
				default: next_state = MEM_READ_1_2;
			endcase
		end
		// add with 16-bit load instruction
		MEM_READ_2_2_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD_DATA2IE;
			next_state = MEM_READ_2_1_AND_ALU_EXCUTION;
		end
		MEM_READ_2_1_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD_AL & NO_MEM_RD;
			case(function_sel)
				POP: next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
				RETURN_FUNC: next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
				RETI,
				RETN:begin
					next_state = MEM_READ_1_2_AND_LOAD_OPERAND;
				end
				default: next_state = MEM_READ_1_2;
			endcase
		end
		MEM_WRITE_2_2_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_DATA2IE;
			next_state = MEM_WRITE_2_1_AND_ALU_EXCUTION;
		end
		MEM_WRITE_2_1_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_AL & NO_MEM_WR;
			case(function_sel)
				PUSH:begin
					next_state = MEM_WRITE_1_2_AND_REGISTER_LOAD;
				end
				EX_HL_AND_MEM_SP, EX_IX_AND_MEM_SP,
				EX_IY_AND_MEM_SP:begin
					next_state = MEM_READ_1_2;
				end
				CALL:begin
					next_state = MEM_WRITE_1_2_AND_REG_LOAD;
				end
				RST:begin
					next_state = MEM_WRITE_1_2;
				end
				default: next_state = MEM_WRITE_1_2;
			endcase
		end
		MEM_WRITE_1_2_AND_REGISTER_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_REGWR;
			next_state = MEM_WRITE_1_1;
		end
		MEM_READ_1_2_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD_DATA2IE;
			case(function_sel)
				LDI, LDD, LDIR,
				LDDR:begin
					next_state = MEM_READ_1_1_AND_ALU_EXCUTION_AND_LOAD_OPERAND;
				end
				CPI, CPIR, CPD,
				CPDR:begin
					next_state = MEM_READ_1_1_AND_ALU_EXCUTION_AND_LOAD_OPERAND;
				end
				default: next_state = MEM_READ_1_1_AND_ALU_EXCUTION;
			endcase
		end
		MEM_READ_1_1_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD_AL & NO_MEM_RD;
			case(function_sel)
				RETURN_FUNC: next_state = REG_PC_LOAD_AND_REG_LOAD;
				OUTI, OUTD, OTIR,
				OTDR:begin
					next_state = OUTPUT_4_AND_REGISTER_LOAD;
				end
				RETI,
				RETN:begin
					next_state = REG_PC_LOAD_AND_REG_LOAD;
				end
				default: next_state = REGISTER_LOAD;
			endcase
		end
		// add with exchange instruction(16-bits)
		MEM_READ_2_2:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD;
			next_state = MEM_READ_2_1;
		end
		MEM_READ_2_1:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD & NO_MEM_RD;
			next_state = MEM_WRITE_2_2_AND_LOAD_OPERAND;
		end
		MEM_WRITE_1_1_AND_REGISTER_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_REGWR & NO_MEM_WR;
			next_state = INS_FETCH_INITIAL;
		end
		// add with 8-bit arithmetic ang logic
		LOAD_OPERAND_AGAIN:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IE;
			next_state = ALU_EXCUTION_AGAIN;	
		end
		ALU_EXCUTION_AGAIN:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = AL;
			case(function_sel)
				OE_MEM_INDEX_MEM_IX,
				OE_MEM_INDEX_MEM_IY:begin
					next_state = MEM_WRITE_1_2_AND_REGISTER_LOAD;
				end
				RS_MEM_INDEX_IX, 
				RS_MEM_INDEX_IY:begin
					next_state = MEM_WRITE_1_2_AND_REGISTER_LOAD;
				end
				BM_SET_MEM_IX, BM_RESET_MEM_IX, BM_SET_MEM_IY,
				BM_RESET_MEM_IY:begin
					next_state = MEM_WRITE_1_2;
				end
				BM_TEST_MEM_IX,
				BM_TEST_MEM_IY:begin
					next_state = REGISTER_LOAD;
				end
				JUMP_DJNZ:begin
					next_state = REGISTER_PC_LOAD;
				end
				default: next_state = REGISTER_LOAD;
			endcase
		end
		// add with jump call return and reset
		REGISTER_PC_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IF;
			next_state = INS_FETCH_INITIAL;
		end
		REGISTER_LOAD_AND_ZERO_JUDGE:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = REGWR;
			case(zero)
				1'b1: next_state = LOAD_OPERAND_CLEAR;
				1'b0: next_state = LOAD_OPERAND_AGAIN; 
			endcase
		end
		LOAD_OPERAND_CLEAR:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IE;
			next_state = INS_FETCH_INITIAL;
		end
		MEM_WRITE_1_2_AND_REG_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_REGWR;
			next_state = MEM_WRITE_1_1_AND_REG_PC_LOAD;
		end
		MEM_WRITE_1_1_AND_REG_PC_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_DATA2IF & NO_MEM_WR;
			next_state = INS_FETCH_INITIAL;				
		end
		REG_PC_LOAD_AND_REG_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IF_REGWR;
			next_state = INS_FETCH_INITIAL;				
		end
		// add with input group
		INPUT_4:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IN_DRIVER;
			case(function_sel)
				INI, INIR, IND,
				INDR:begin
					next_state = INPUT_3_AND_LOAD_OPERAND;
				end 
				default: next_state = INPUT_3;
			endcase			
		end
		INPUT_3:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IN_DRIVER;
			next_state = INPUT_2;				
		end
		INPUT_2:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IN_DRIVER;
			next_state = INPUT_1;				
		end
		INPUT_1:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IN_DRIVER;
			next_state = REGISTER_LOAD;				
		end
		INPUT_3_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IN_DATA2IE;
			next_state = INPUT_2_AND_ALU_EXCUTION;				
		end
		INPUT_2_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IN_AL;
			next_state = INPUT_1_AND_REGISTER_LOAD;				
		end
		INPUT_1_AND_REGISTER_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IN_REGWR;
			next_state = MEM_WRITE_1_2_AND_LOAD_OPERAND;				
		end
		MEM_WRITE_1_2_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_DATA2IE;
			next_state = MEM_WRITE_1_1_AND_ALU_EXCUTION;				
		end
		MEM_WRITE_1_1_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_AL & NO_MEM_WR;
			case(function_sel)
				INIR, 
				INDR:begin
					next_state = REGISTER_LOAD_AND_REPEAT_JUDGE;
				end 
				default: next_state = REGISTER_LOAD;
			endcase				
		end
		REGISTER_LOAD_AND_REPEAT_JUDGE:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = REGWR;
			case(zero)
				1'b0: next_state = LOAD_OPERAND;
				1'b1: next_state = LOAD_OPERAND_CLEAR;
			endcase
		end
		OUTPUT_4:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_DRIVER;
			next_state = OUTPUT_3;
		end
		OUTPUT_3:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_DRIVER;
			next_state = OUTPUT_2;
		end
		OUTPUT_2:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_DRIVER;
			next_state = OUTPUT_1;
		end
		OUTPUT_1:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_DRIVER;
			next_state = INS_FETCH_INITIAL;
		end
		OUTPUT_4_AND_REGISTER_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_REGWR;
			next_state = OUTPUT_3_AND_LOAD_OPERAND;
		end
		OUTPUT_3_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_DATA2IE;
			next_state = OUTPUT_2_AND_ALU_EXCUTION;
		end
		OUTPUT_2_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_AL;
			case(function_sel)
				OTIR,
				OTDR:begin
					next_state = OUTPUT_1_AND_REG_LOAD_AND_REPEAT_JUDGE;
				end 
				default: next_state = OUTPUT_1_AND_REGISTER_LOAD;
			endcase
		end
		OUTPUT_1_AND_REGISTER_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_REGWR;
			next_state = INS_FETCH_INITIAL;
		end
		OUTPUT_1_AND_REG_LOAD_AND_REPEAT_JUDGE:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = OUT_REGWR;
			case(zero)
				1'b0: next_state = LOAD_OPERAND;
				1'b1: next_state = LOAD_OPERAND_CLEAR;
			endcase				
		end
		MEM_READ_1_1_AND_ALU_EXCUTION_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD_AL_DATA2IE & NO_MEM_RD;
			case(function_sel)
				CPI, CPIR, CPD,
				CPDR:begin
					next_state = REGISTER_LOAD_AND_ALU_EXCUTION;
				end
				default: next_state = MEM_WRITE_1_2_AND_REGISTER_LOAD_AND_ALU_EXCUTION;
			endcase
		end
		MEM_WRITE_1_2_AND_REGISTER_LOAD_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_REGWR_AL;
			next_state = MEM_WRITE_1_1_AND_REGISTER_LOAD_AND_LOAD_OPERAND;
		end
		MEM_WRITE_1_1_AND_REGISTER_LOAD_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_REGWR_DATA2IE & NO_MEM_WR;
			next_state = ALU_EXCUTION_THIRD_TIME;
		end
		ALU_EXCUTION_THIRD_TIME:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = AL;
			case(function_sel)
				LDIR, 
				LDDR:begin
					next_state = REGISTER_LOAD_AND_REPEAT_JUDGE_AND_LOAD_OPERAND;
				end
				CPIR,
				CPDR:begin
					next_state = REGISTER_LOAD_AND_REPEAT_JUDGE_AND_LOAD_OPERAND;
				end
				default: next_state = REGISTER_LOAD_THIRD_TIME;
			endcase
		end
		REGISTER_LOAD_THIRD_TIME:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = REGWR;
			next_state = INS_FETCH_INITIAL;
		end
		REGISTER_LOAD_AND_REPEAT_JUDGE_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = REGWR_DATA2IE;
			case(function_sel)
				CPIR, 
				CPDR:begin
					case({zero, parity})
						2'b01: next_state = ALU_EXCUTION_FOURTH_TIME;
						default: next_state = INS_FETCH_INITIAL;
					endcase
				end
				default:begin
					case(parity) // bc = 0 -> reset
						1'b1: next_state = ALU_EXCUTION_FOURTH_TIME; // compute new pc
						1'b0: next_state = INS_FETCH_INITIAL;
					endcase						
				end
			endcase

		end
		ALU_EXCUTION_FOURTH_TIME:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = AL;
			next_state = REGISTER_PC_LOAD;
		end
		REGISTER_LOAD_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = REGWR_AL;
			next_state = REGISTER_LOAD_AND_LOAD_OPERAND;
		end
		REGISTER_LOAD_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = REGWR_DATA2IE; 
			next_state = ALU_EXCUTION_THIRD_TIME;
		end
		NOP_STATE:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IDLE; 
			next_state = INS_FETCH_INITIAL;				
		end
		HALT_STATE:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IDLE; 
			next_state = HALT_STATE;				
		end
		RESET_IFF:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IDLE; 
			next_state = INS_FETCH_INITIAL;
		end
		SET_IFF:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IDLE; 
			next_state = INS_FETCH_INITIAL;
		end
		// nmi int state
		NMI_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IE;
			next_state = NMI_ALU_EXCUTION_AND_IFF;
		end
		NMI_ALU_EXCUTION_AND_IFF:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = AL;
			next_state = NMI_INT_MEM_WRITE_2_2_AND_LOAD_OPERAND;
		end
		NMI_INT_MEM_WRITE_2_2_AND_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_DATA2IE;
			next_state = NMI_INT_MEM_WRITE_2_1_AND_ALU_EXCUTION;
		end
		NMI_INT_MEM_WRITE_2_1_AND_ALU_EXCUTION:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_AL & NO_MEM_WR;
			next_state = NMI_INT_MEM_WRITE_1_2_AND_REGISTER_LOAD;
		end
		NMI_INT_MEM_WRITE_1_2_AND_REGISTER_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_REGWR;
			case(nmi_int_ofos_operation_type)
				INTERRUPT_MODE_0: next_state = INT_MEM_WRITE_1_1;
				default: next_state = NMI_INT_MEM_WRITE_1_1_AND_REGISTER_PC_LOAD;
			endcase
		end
		NMI_INT_MEM_WRITE_1_1_AND_REGISTER_PC_LOAD:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_DATA2IF & NO_MEM_WR;
			next_state = INS_FETCH_INITIAL;
		end
		INT_LOAD_OPERAND:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IE;
			next_state = INT_ALU_EXCUTION_AND_IFF;
		end
		INT_ALU_EXCUTION_AND_IFF:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = AL;
			next_state = NMI_INT_MEM_WRITE_2_2_AND_LOAD_OPERAND;
		end
		INT_LOAD_OPERAND_AND_INPUT_4:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = DATA2IE_IN;
			next_state = INT_ALU_EXCUTION_AND_INPUT_3_AND_IFF;
		end
		INT_ALU_EXCUTION_AND_INPUT_3_AND_IFF:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = AL_IN;				
			next_state = INT_MEM_WRITE_2_2_AND_LOAD_OPERAND_AND_INPUT_2;
		end
		INT_MEM_WRITE_2_2_AND_LOAD_OPERAND_AND_INPUT_2:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_DATA2IE_IN;
			next_state = INT_MEM_WRITE_2_1_AND_ALU_EXCUTION_AND_INPUT_1;
		end
		INT_MEM_WRITE_2_1_AND_ALU_EXCUTION_AND_INPUT_1:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR_AL_IN & NO_MEM_WR;
			next_state = NMI_INT_MEM_WRITE_1_2_AND_REGISTER_LOAD;
		end
		INT_MEM_WRITE_1_1:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMWR & NO_MEM_WR;
			next_state = INT_INS_FETCH_INITIAL;
		end
		INT_INS_FETCH_INITIAL:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IF_DRIVER;
			next_state = INS_FETCH_DECODE;
		end
		// INT_INS_FETCH:begin
		// 	{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IF_DRIVER;
		// 	if (decode_en) begin
		// 		next_state = INS_DECODE;//fsm_mem_bus_int = 1'b0;
		// 	end	
		// 	else begin
		// 		next_state = INT_INS_FETCH;			
		// 	end			
		// end
		MEM_READ_2_2_AND_LOAD_OPERAND_AND_IFF:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = MEMRD_DATA2IE;
			next_state = MEM_READ_2_1_AND_ALU_EXCUTION;
		end
		default:begin
			{fsm_if_en, fsm_if_pc_modify, fsm_of_le_en, fsm_of_mem_rd, fsm_of_load_en, fsm_of_input, fsm_ie_en, fsm_os_mem_wr, fsm_os_output} = IDLE;
			next_state = INS_FETCH_INITIAL;		
		end
	endcase		
end


//==================================================================================================================================
//                            cpu output signal 
//==================================================================================================================================
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		halt_o <= 1'b1;
	end
	else if (current_state == HALT_STATE) begin
		halt_o <= 1'b0;
	end else begin
		halt_o <= 1'b1;
	end
end

//==================================================================================================================================
//                            interrupt process
//==================================================================================================================================
// fsm_mem_bus_int is used to switch the data_bus 
// to instr_fetch module or operand_fetch module
// always @(negedge clk or negedge reset) begin
// 	if (!reset) begin
// 		fsm_mem_bus_int <= 1'b0;
// 	end
// 	else begin
// 		case(current_state)
// 			INT_LOAD_OPERAND_AND_INPUT_4: fsm_mem_bus_int <= 1'b1;
// 			INT_ALU_EXCUTION_AND_INPUT_3_AND_IFF: fsm_mem_bus_int <= 1'b1;
// 			INT_MEM_WRITE_2_2_AND_LOAD_OPERAND_AND_INPUT_2: fsm_mem_bus_int <= 1'b1;
// 			INT_MEM_WRITE_2_1_AND_ALU_EXCUTION_AND_INPUT_1: fsm_mem_bus_int <= 1'b1;
// 			INT_INS_FETCH_INITIAL: fsm_mem_bus_int <= 1'b1;
// 			INT_INS_FETCH: fsm_mem_bus_int <= 1'b1;
// 			default: fsm_mem_bus_int <= 1'b0;
// 		endcase
// 	end
// end
//==================================================================================================================================
//                            interrupt register
//==================================================================================================================================
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		IFF1 <= 1'b0;
		IFF2 <= 1'b0;		
	end
	else begin
		case(current_state)
			SET_IFF:begin
				IFF1 <= 1'b1;
				IFF2 <= 1'b1;
			end
			RESET_IFF:begin 
				IFF1 <= 1'b0;
				IFF2 <= 1'b0;
			end
			NMI_ALU_EXCUTION_AND_IFF:begin
				IFF1 <= 1'b0;
				IFF2 <= IFF1;
			end
			INT_ALU_EXCUTION_AND_IFF:begin
				IFF1 <= 1'b0;
				IFF2 <= 1'b0;
			end
			INT_ALU_EXCUTION_AND_INPUT_3_AND_IFF:begin
				IFF1 <= 1'b0;
				IFF2 <= 1'b0;				
			end
			MEM_READ_2_2_AND_LOAD_OPERAND_AND_IFF:begin
				IFF1 <= IFF2;
			end
			default:begin
				IFF1 <= IFF1;
				IFF2 <= IFF2;
			end
		endcase	
	end
end

always @(IFF2) begin
	fsm_os_IFF2 = IFF2;
end

always @(posedge clk or negedge reset) begin
	if (!reset) begin
		int_mode <= INT_MODE_0;
	end
	else begin
		case(function_sel)
			IM0:begin
				//function_sel <= IM0;
				int_mode <= INT_MODE_0;
			end
			IM1:begin
				//function_sel <= IM1;
				int_mode <= INT_MODE_1;
			end
			IM2:begin
				//function_sel <= IM2;
				int_mode <= INT_MODE_2;
			end	
			default: int_mode <= int_mode;
		endcase	
	end
end

//==================================================================================================================================
//                            interrupt signal 
//==================================================================================================================================
// fsm_os_int is used to write IFF2 in reg F[2] when interrupt happens during excution of LOAD_IMP2REG
always @(nonmaskable_int or maskable_int) begin
	fsm_os_int = nonmaskable_int | maskable_int;
end

wire end_of_instr;
assign end_of_instr = (next_state == INS_FETCH_INITIAL || next_state == HALT_STATE);

// sample nmi(active low) with the rising edge of the final clock at the end of any instruction
wire nmi_sample_en;
assign nmi_sample_en = end_of_instr;
reg nonmaskable_int_temp;
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		nonmaskable_int_temp <= NO_INTERRUPT;
	end
	//else if(nmi_sample_en && (nmi == 1'b0)) begin
	else if(nmi == 1'b0) begin
		nonmaskable_int_temp <= NON_MASK_INT;
	end
	else begin
		nonmaskable_int_temp <= NO_INTERRUPT;
	end
end
always @(nonmaskable_int_temp or nmi_sample_en) begin
	nonmaskable_int = nonmaskable_int_temp & nmi_sample_en;
end


// sample int(active low) with the rising edge of the final clock at the end of any instruction
// During the execution of this instruction(EI: IFF<-1) and the following instruction, 
// maskable interrupts are disabled.
reg [7:0] function_sel_last; // store last instruction
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		function_sel_last <= NO_FUNCTION;
	end
	else if (end_of_instr) begin  
		function_sel_last <= function_sel;
	end
end
wire int_sample_en;
assign int_sample_en = IFF1 && end_of_instr && (function_sel != EINT) && (function_sel_last != EINT);
reg maskable_int_temp;
always @(posedge clk or negedge reset) begin
	if(!reset)begin
		maskable_int_temp <= NO_INTERRUPT;
	end 
	//else if(int_sample_en && (int == 1'b0)) begin
	else if(int == 1'b0) begin
		maskable_int_temp <= MASK_INT;
	end
	else begin
		maskable_int_temp <= NO_INTERRUPT;
	end
end
always @(maskable_int_temp or int_sample_en) begin
	maskable_int = maskable_int_temp & int_sample_en;
end

endmodule 