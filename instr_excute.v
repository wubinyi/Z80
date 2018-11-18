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

module instr_excute(
	clk,
	reset,
	fsm_ie_en,	
	of_ie_operand_des,
	of_ie_operand_des_high,
	of_ie_operand_sou,
	of_ie_operand_sou_high,
	of_ie_flag_reg,
	of_ie_operation,
	ie_os_result,
	ie_os_result_high,
	ie_os_flag_reg,
	ie_fsm_flag_reg
);

input clk;
input reset;
input fsm_ie_en;
input [4:0] of_ie_operation;
input [7:0] of_ie_operand_des;
input [7:0] of_ie_operand_sou;
input [7:0] of_ie_operand_des_high;
input [7:0] of_ie_operand_sou_high;
input [7:0] of_ie_flag_reg;
output reg [7:0] ie_os_result;
output reg [7:0] ie_os_result_high;
output reg [7:0] ie_os_flag_reg;
output reg [7:0] ie_fsm_flag_reg;

// can not change the parameter, if change please search "can not change the parameter" at first
// some place use parameter's bits as selector
parameter ADD_ALU                    = 5'd1;
parameter ADC_ALU                    = 5'd2;
parameter SUB_ALU                    = 5'd3;
parameter SBC_ALU                    = 5'd4;
parameter AND_ALU                    = 5'd5;
parameter XOR_ALU                    = 5'd6;
parameter OR_ALU                     = 5'd7;
parameter CP_ALU                     = 5'd8;
parameter INC_ALU                    = 5'd9;
parameter DEC_ALU                    = 5'd10;

parameter ADD_16BIT_ALU              = 5'd11;
parameter ADC_16BIT_ALU              = 5'd12;
parameter SBC_16BIT_ALU              = 5'd13;
parameter INC_16BIT_ALU              = 5'd14;  // not used
parameter DEC_16BIT_ALU              = 5'd15;  // not used
parameter SUB_AF_ALU                 = 5'd16;

parameter RLC_ALU                    = 5'd17;
parameter RRC_ALU                    = 5'd18;
parameter RL_ALU                     = 5'd19;
parameter RR_ALU                     = 5'd20;
parameter SLA_ALU                    = 5'd21;
parameter SRA_ALU                    = 5'd22;
parameter SRL_ALU                    = 5'd23;
parameter RLD_ALU                    = 5'd24;
parameter RRD_ALU                    = 5'd25;

parameter SET_BIT_ALU                = 5'd26;
parameter RESET_BIT_ALU              = 5'd27;
parameter TEST_BIT_ALU               = 5'd28;

parameter ADD_16BIT_NONE_AFFECT_ALU  = 5'd29;
parameter ADD_16BIT_BLOCK_TRANS_ALU  = 5'd30;
parameter BLOCK_SEARCH_COMPARE_ALU   = 5'd31;

parameter AND = 2'h0;
parameter OR  = 2'h1;
parameter XOR = 2'h2;
parameter NON = 2'h3;

wire C;       // carry
wire N;       // add/substrate
wire P_V;     // parity/overflow flag
wire H;       // half carry falg
wire Z;       // zero flag
wire S;       // sign flag
wire X_1;     // unused
wire X_2;     // unused
assign {S, Z, X_1, H, X_2, P_V, N, C} = of_ie_flag_reg;
//================================================================================
// operand allocate
//================================================================================
reg [7:0] oper_a_low;
reg [7:0] oper_a_high;
reg [7:0] oper_b_low;
reg [7:0] oper_b_high;
reg       adder_en;
reg       add_sub;
reg       carry_in;
reg       word_adder_en;
reg       logic_en;
reg [1:0] logic_type;
always @* begin
	case(of_ie_operation)
		ADD_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;
		end
		ADC_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = C;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;
		end
		SUB_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;
		end
		SBC_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = C;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;
		end
		AND_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high; // 8'h00;
			oper_b_high = of_ie_operand_sou_high; // 8'h00;
			adder_en = 1'b0;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b1;
			logic_type = AND;
		end
		XOR_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high; //8'h00; 
			oper_b_high = of_ie_operand_sou_high; //8'h00; 
			adder_en = 1'b0;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b1;
			logic_type = XOR;	
		end
		OR_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high; //8'h00;
			oper_b_high = of_ie_operand_sou_high; //8'h00;
			adder_en = 1'b0;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b1;
			logic_type = OR;				
		end
		CP_ALU:begin // SUB but not store the sum
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high; //8'h00;
			oper_b_high = of_ie_operand_sou_high; //8'h00;
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = 1'b0;	
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;			
		end
		INC_ALU:begin
			oper_a_low = of_ie_operand_sou;
			oper_b_low = 8'h01;
			oper_a_high = of_ie_operand_des_high; //8'h00;
			oper_b_high = of_ie_operand_sou_high; //8'h00;
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;			
		end
		DEC_ALU:begin
			oper_a_low = of_ie_operand_sou;
			oper_b_low = 8'h01;
			oper_a_high = of_ie_operand_des_high; //8'h00;
			oper_b_high = of_ie_operand_sou_high; //8'h00;
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;					
		end
		ADD_16BIT_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b1;
			logic_en = 1'b0;
			logic_type = NON;
		end
		ADC_16BIT_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = C;
			word_adder_en = 1'b1;
			logic_en = 1'b0;
			logic_type = NON;
		end
		SBC_16BIT_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = C;
			word_adder_en = 1'b1;
			logic_en = 1'b0;
			logic_type = NON;										   
		end
		INC_16BIT_ALU:begin
			oper_a_low = 8'h01;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = 8'h00;
			oper_b_high = of_ie_operand_sou_high;
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b1;
			logic_en = 1'b0;
			logic_type = NON;
		end
		DEC_16BIT_ALU:begin
			oper_a_low = of_ie_operand_sou;
			oper_b_low = 8'h01;
			oper_a_high = of_ie_operand_sou_high;
			oper_b_high = 8'h00;
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = 1'b0;
			word_adder_en = 1'b1;
			logic_en = 1'b0;
			logic_type = NON;
		end
		SUB_AF_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;  // 8'h00
			oper_b_high = of_ie_operand_sou_high;  // 8'h00
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;				
		end
		SET_BIT_ALU:begin
			oper_a_low = of_ie_operand_des;
			//oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;  // 8'h00
			oper_b_high = of_ie_operand_sou_high;  // 8'h00
			adder_en = 1'b0;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b1;
			logic_type = OR;
			case(of_ie_operand_sou)
				8'd0: oper_b_low = 8'd1;    // set bit 0
				8'd1: oper_b_low = 8'd2;    // set bit 1
				8'd2: oper_b_low = 8'd4;    // set bit 2
				8'd3: oper_b_low = 8'd8;    // set bit 3
				8'd4: oper_b_low = 8'd16;    // set bit 4
				8'd5: oper_b_low = 8'd32;    // set bit 5
				8'd6: oper_b_low = 8'd64;    // set bit 6
				8'd7: oper_b_low = 8'd128;    // set bit 7
				default: oper_b_low = 8'd0;    // do not set any bit
			endcase
		end
		RESET_BIT_ALU:begin
			oper_a_low = of_ie_operand_des;
			//oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;  // 8'h00
			oper_b_high = of_ie_operand_sou_high;  // 8'h00
			adder_en = 1'b0;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b1;
			logic_type = AND;
			case(of_ie_operand_sou)
				8'd0: oper_b_low = 8'b1111_1110;    // reset bit 0
				8'd1: oper_b_low = 8'b1111_1101;    // reset bit 1
				8'd2: oper_b_low = 8'b1111_1011;    // reset bit 2
				8'd3: oper_b_low = 8'b1111_0111;    // reset bit 3
				8'd4: oper_b_low = 8'b1110_1111;    // reset bit 4
				8'd5: oper_b_low = 8'b1101_1111;    // reset bit 5
				8'd6: oper_b_low = 8'b1011_1111;    // reset bit 6
				8'd7: oper_b_low = 8'b0111_1111;    // sreet bit 7
				default: oper_b_low = 8'b1111_1111;    // do not reset any bit
			endcase
		end
		ADD_16BIT_NONE_AFFECT_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;  // 8'h00
			oper_b_high = of_ie_operand_sou_high;  // 8'h00
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b1;
			logic_en = 1'b0;
			logic_type = NON;
		end
		ADD_16BIT_BLOCK_TRANS_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;  // 8'h00
			oper_b_high = of_ie_operand_sou_high;  // 8'h00
			adder_en = 1'b1;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b1;
			logic_en = 1'b0;
			logic_type = NON;
		end
		BLOCK_SEARCH_COMPARE_ALU:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;  // 8'h00
			oper_b_high = of_ie_operand_sou_high;  // 8'h00
			adder_en = 1'b1;
			add_sub = 1'b1;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;
		end
		default:begin
			oper_a_low = of_ie_operand_des;
			oper_b_low = of_ie_operand_sou;
			oper_a_high = of_ie_operand_des_high;  // 8'h00
			oper_b_high = of_ie_operand_sou_high;  // 8'h00
			adder_en = 1'b0;
			add_sub = 1'b0;
			carry_in = 1'b0;
			word_adder_en = 1'b0;
			logic_en = 1'b0;
			logic_type = NON;			
		end
	endcase
end

//================================================================================
// adder 
//================================================================================
// low 8-bit adder
reg [7:0] sum_low;
reg       half_carry_low;
reg       carry_low_;
reg       carry_low;
reg       overflow_low;
reg       zero_low;
reg       sign_low;
always @(adder_en or add_sub or oper_a_low or oper_b_low or carry_in)
begin
	if (adder_en) begin
		if (add_sub) begin // sub
			{half_carry_low, sum_low[3:0]} = oper_a_low[3:0] - oper_b_low[3:0] - {3'h0, carry_in};
			{carry_low_, sum_low[6:4]} = oper_a_low[6:4] - oper_b_low[6:4] - {2'h0, half_carry_low};
			{carry_low, sum_low[7]}    = oper_a_low[7]   - oper_b_low[7]   - carry_low_;		
		end
		else begin         // add
			{half_carry_low, sum_low[3:0]} = oper_a_low[3:0] + oper_b_low[3:0] + {3'h0, carry_in};
			{carry_low_, sum_low[6:4]} = oper_a_low[6:4] + oper_b_low[6:4] + {2'h0, half_carry_low};
			{carry_low, sum_low[7]}    = oper_a_low[7]   + oper_b_low[7]   + carry_low_;			
		end
		overflow_low = carry_low_ ^ carry_low; 
		zero_low = ~|sum_low; 
		sign_low = sum_low[7];
	end
	else begin
		sum_low = 8'h0;
		half_carry_low = 1'b0;
		carry_low_ = 1'b0;
		carry_low = 1'b0;
		overflow_low = 1'b0;
		zero_low = 1'b0;
		sign_low = 1'b0;
	end
end
// high 8-bit adder
reg [7:0] sum_high;
reg       half_carry_high;
reg       carry_high_;
reg       carry_high;
reg       overflow_high;
reg       zero_high;
reg       sign_high;
always @(word_adder_en or add_sub or oper_a_high or oper_b_high or carry_low)
begin
	if (word_adder_en) begin
		if (add_sub) begin  // sub
			{half_carry_high, sum_high[3:0]} = {1'b0, oper_a_high[3:0]} - {1'b0, oper_b_high[3:0]} - {4'h0, carry_low};
			{carry_high_, sum_high[6:4]} = {1'b0, oper_a_high[6:4]} - {1'b0, oper_b_high[6:4]} - {3'h0, half_carry_high};
			{carry_high, sum_high[7]}    = {1'b0, oper_a_high[7]}   - {1'b0, oper_b_high[7]}   - {1'b0, carry_high_};				
		end
		else begin          // add
			{half_carry_high, sum_high[3:0]} = {1'b0, oper_a_high[3:0]} + {1'b0, oper_b_high[3:0]} + {4'h0, carry_low};
			{carry_high_, sum_high[6:4]} = {1'b0, oper_a_high[6:4]} + {1'b0, oper_b_high[6:4]} + {3'h0, half_carry_high};
			{carry_high, sum_high[7]}    = {1'b0, oper_a_high[7]}   + {1'b0, oper_b_high[7]}   + {1'b0, carry_high_};			
		end
		overflow_high = carry_high_ ^ carry_high; 
		zero_high = ~|sum_high; 
		sign_high = sum_high[7];		
	end
	else begin
		sum_high = 8'h0;
		half_carry_high = 1'b0;
		carry_high_ = 1'b0;
		carry_high = 1'b0;
		overflow_high = 1'b0;
		zero_high = 1'b0;
		sign_high = 1'b0;
	end
end

//================================================================================
// logic unit
//================================================================================
reg [7:0] logic_result;
reg       logic_half_carry;
reg       logic_carry;
reg       logic_parity_overlfow;
reg       logic_zero;
reg       logic_sign;
always @(logic_en or logic_type or oper_a_low or oper_b_low) begin
	if (logic_en) begin
		case(logic_type)
			AND: logic_result = oper_b_low & oper_b_low;
			XOR: logic_result = oper_b_low ^ oper_b_low;
			OR:  logic_result = oper_b_low | oper_b_low;
			NON: logic_result =	8'h00;
		endcase	
		case(logic_type)
			AND: logic_half_carry = 1'b1;
			default: logic_half_carry = 1'b0;
		endcase
		case(logic_type)
			XOR: logic_parity_overlfow =  ~^logic_result;                                                  // parity
			default: logic_parity_overlfow = ((oper_a_low[7] & oper_b_low[7] & !logic_result[7]) |         // overflow
												(!oper_a_low[7] & !oper_b_low[7] & logic_result[7]));
		endcase
		logic_carry = 1'b0;
		logic_zero = ~|logic_result;
		logic_sign = logic_result[7];
	end
	else begin
		logic_result = 8'h00;
		logic_half_carry = 1'b0;
		logic_carry = 1'b0;
		logic_parity_overlfow= 1'b0;
		logic_zero = 1'b0;
		logic_sign = 1'b0;
	end
end

reg [7:0] result_low;
reg [7:0] result_high;
reg [7:0] result_flag;
reg       result_carry;
reg       result_add_sub;
reg       result_parity_overflow;
reg       result_half_carry;
reg       result_zero;
reg       result_sign;
always @* begin
	case(of_ie_operation)
		ADD_ALU, ADC_ALU, SUB_ALU,
		SBC_ALU:begin
			result_low = sum_low;
			result_high = 8'h00; // sum_high; //8'h00
			result_carry = carry_low;
			result_add_sub = add_sub;
			result_parity_overflow = overflow_low;
			result_half_carry = half_carry_low;
			result_zero = zero_low;
			result_sign = sign_low;
		end
		AND_ALU, XOR_ALU,
		OR_ALU:begin
			result_low = logic_result;
			result_high = 8'h00; // sum_high; //8'h00
			result_carry = logic_carry;
			result_add_sub = add_sub;
			result_parity_overflow = logic_parity_overlfow;
			result_half_carry = logic_half_carry;
			result_zero = logic_zero;
			result_sign = logic_zero;
		end
		CP_ALU:begin
			result_low = of_ie_operand_des; // keep value
			result_high = 8'h00; // sum_high; //8'h00
			result_carry = carry_low;
			result_add_sub = add_sub;
			result_parity_overflow = overflow_low;
			result_half_carry = half_carry_low;
			result_zero = zero_low;
			result_sign = sign_low;			
		end
		INC_ALU,
		DEC_ALU:begin
			result_low = sum_low;
			result_high = 8'h00; // sum_high; //8'h00
			result_carry = C;       // C is not affected
			result_add_sub = add_sub;
			result_parity_overflow = overflow_low;
			result_half_carry = half_carry_low;
			result_zero = zero_low;
			result_sign = sign_low;
		end
		ADD_16BIT_ALU:begin
			result_low = sum_low;
			result_high = 8'h00; // sum_high;    //8'h00
			result_carry = carry_high; // 16-bit
			result_add_sub = add_sub;
			result_parity_overflow = P_V; // not affected
			result_half_carry = half_carry_high; // 16-bit
			result_zero = Z; // not affected
			result_sign = S; // not affected
		end
		ADC_16BIT_ALU, 
		SBC_16BIT_ALU:begin
			result_low = sum_low;
			result_high = 8'h00; // sum_high; //8'h00
			result_carry = carry_high;
			result_add_sub = add_sub;
			result_parity_overflow = overflow_high;
			result_half_carry = half_carry_high;
			result_zero = zero_high;
			result_sign = sign_high;
		end
		INC_16BIT_ALU, 
		DEC_16BIT_ALU:begin
			result_low = sum_low;
			result_high = 8'h00; // sum_high;    //8'h00
			result_carry = C; // not affected
			result_add_sub = N; // not affected
			result_parity_overflow = P_V; // not affected
			result_half_carry = H; // not affected
			result_zero = Z; // not affected
			result_sign = S; // not affected
		end
		SUB_AF_ALU:begin
			result_low = sum_low;
			result_high = 8'h00; // sum_high; //8'h00
			result_carry = carry_low;
			result_add_sub = add_sub;
			result_parity_overflow = overflow_low;
			result_half_carry = half_carry_low;
			result_zero = zero_low;
			result_sign = sign_low;				
		end
		RLC_ALU, RRC_ALU, RL_ALU, RR_ALU, SLA_ALU, SRA_ALU,
		SRL_ALU:begin
			case(of_ie_operation[2:0])    // can not change the parameter
				3'b001: result_low = {of_ie_operand_des[6:0], of_ie_operand_des[7]};  // RLC
				3'b010: result_low = {of_ie_operand_des[0], of_ie_operand_des[7:1]};  // RRC
				3'b011: result_low = {of_ie_operand_des[6:0], C};                     // RL
				3'b100: result_low = {C, of_ie_operand_des[7:1]};                     // RR     
				3'b101: result_low = {of_ie_operand_des[6:0], 1'b0};                  // SLA
				3'b110: result_low = {of_ie_operand_des[7], of_ie_operand_des[7:1]};  // SRA
				3'b111: result_low = {1'b0, of_ie_operand_des[7:1]};                  // SRL
				default: result_low = 8'h00;
			endcase
			case(of_ie_operation[2:0])    // can not change the parameter
				3'b001: result_carry = of_ie_operand_des[7];  // RLC
				3'b010: result_carry = of_ie_operand_des[0];  // RRC
				3'b011: result_carry = of_ie_operand_des[7];  // RL
				3'b100: result_carry = of_ie_operand_des[0];  // RR
				3'b101: result_carry = of_ie_operand_des[7];  // SLA
				3'b110: result_carry = of_ie_operand_des[0];  // SRA
				3'b111: result_carry = of_ie_operand_des[0];  // SRL
				default: result_carry = 8'h00;
			endcase
			case(of_ie_operation[2:0])    // can not change the parameter
				3'b111: result_sign = 1'b0;  // SRL
				default: result_sign = result_low[7];
			endcase			
			result_high = 8'h00; // sum_high; //8'h00
			result_half_carry = 1'b0;
			result_add_sub = 1'b0;
			result_parity_overflow =  ~^result_low;  // parity
			result_zero = ~|result_low;
		end
		RLD_ALU, 
		RRD_ALU:begin
			case(of_ie_operation[0])    // can not change the parameter
				1'b0:begin
					result_low = {of_ie_operand_des[3:0], of_ie_operand_sou[3:0]};       // memory data
					result_high = {of_ie_operand_sou[7:4], of_ie_operand_des[7:4]};      // Accumulator					
				end
				1'b1:begin
					result_low = {of_ie_operand_sou[3:0], of_ie_operand_des[7:4]};       // memory data
					result_high = {of_ie_operand_sou[7:4], of_ie_operand_des[3:0]};      // Accumulator					
				end
			endcase
			result_carry = C;
			result_half_carry = 1'b0;
			result_add_sub = 1'b0;
			result_parity_overflow =  ~^result_high;  // parity
			result_sign = result_high[7];
			result_zero = ~|result_high;					
		end
		SET_BIT_ALU,
		RESET_BIT_ALU:begin
			result_low = logic_result;
			result_high = 8'h00; // sum_high;    //8'h00
			result_carry = C; // not affected
			result_add_sub = N; // not affected
			result_parity_overflow = P_V; // not affected
			result_half_carry = H; // not affected
			result_zero = Z; // not affected
			result_sign = S; // not affected
		end
		TEST_BIT_ALU:begin
			result_low = 8'h00;
			result_high = 8'h00; // sum_high;    //8'h00
			result_carry = C; // not affected
			result_add_sub = 1'b0;
			result_parity_overflow = P_V; // not affected
			result_half_carry = 1'b1;
			result_sign = S; // not affected
			case(of_ie_operand_sou[2:0])
				3'd0: result_zero = ~of_ie_operand_des[0];
				3'd1: result_zero = ~of_ie_operand_des[1];
				3'd2: result_zero = ~of_ie_operand_des[2];
				3'd3: result_zero = ~of_ie_operand_des[3];
				3'd4: result_zero = ~of_ie_operand_des[4];
				3'd5: result_zero = ~of_ie_operand_des[5];
				3'd6: result_zero = ~of_ie_operand_des[6];
				3'd7: result_zero = ~of_ie_operand_des[7];
			endcase			
		end
		ADD_16BIT_NONE_AFFECT_ALU:begin
			result_low = sum_low;
			result_high = sum_high;
			result_carry = C; // not affected
			result_add_sub = N; // not affected
			result_parity_overflow = P_V; // not affected
			result_half_carry = H; // not affected
			result_zero = Z; // not affected
			result_sign = S; // not affected
		end
		ADD_16BIT_BLOCK_TRANS_ALU:begin
			result_low = sum_low;
			result_high = sum_high;
			result_carry = C; // not affected
			result_add_sub = 1'b0;
			result_parity_overflow = |{sum_high, sum_low}; // not equal 0 = 0
			result_half_carry = 1'b0;
			result_zero = Z; // not affected
			result_sign = S; // not affected
		end
		BLOCK_SEARCH_COMPARE_ALU:begin
			result_low = sum_low;
			result_high = 8'h00; //sum_high;  //8'h00;
			result_carry = C; // not affected
			result_add_sub = 1'b1;
			result_parity_overflow = |{sum_high, sum_low}; // not equal 0 = 0
			result_half_carry = half_carry_low;
			result_zero = ~|sum_low;
			result_sign = sign_low;
		end
	endcase
	result_flag = {result_sign, result_zero, X_1, result_half_carry, X_2, result_parity_overflow, result_add_sub, result_carry};
end

always @(posedge clk or negedge reset) begin
	if (!reset) begin
		ie_os_result <= 8'b0;
		ie_os_result_high <= 8'b0;
		ie_os_flag_reg <= 8'b0;
		ie_fsm_flag_reg <= 8'b0;	
	end
	else if (fsm_ie_en) begin
		ie_os_result <= result_low;
		ie_os_result_high <= result_high;
		ie_os_flag_reg <= result_flag;
		ie_fsm_flag_reg <= result_flag;	
	end
end

endmodule