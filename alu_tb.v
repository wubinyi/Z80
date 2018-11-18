`timescale 1ns/10ps

module alu_tb();

reg clk;
reg reset;
reg fsm_ie_en;
reg [4:0] of_ie_operation;
reg [7:0] of_ie_operand_des;
reg [7:0] of_ie_operand_sou;
reg [7:0] of_ie_operand_des_high;
reg [7:0] of_ie_operand_sou_high;
reg [7:0] of_ie_flag_reg;
wire [7:0] ie_os_result;
wire [7:0] ie_os_result_high;
wire [7:0] ie_os_flag_reg;
wire [7:0] ie_fsm_flag_reg;



instr_excute alu(
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

initial begin
	clk <= 1'b0;
	forever #20 clk <= ~clk;
end
initial begin
	fsm_ie_en = 1;
	reset = 1;
	#10 reset = 0;
	#10 reset = 1;
end

initial begin
	of_ie_operation = 5'd1;   // ADD
	of_ie_operand_des = 8'd125;
	of_ie_operand_sou = 8'd100;
	of_ie_operand_des_high = 8'd0;
	of_ie_operand_sou_high = 8'd0;
	of_ie_flag_reg = 8'h00;	
	# 40
	of_ie_operation = 5'd2;   // ADC
	of_ie_operand_des = 8'd127;
	of_ie_operand_sou = 8'd126;
	of_ie_operand_des_high = 8'd0;
	of_ie_operand_sou_high = 8'd0;
	of_ie_flag_reg = 8'hff;
	# 40
	of_ie_operation = 5'd3;   // SUB
	of_ie_operand_des = 8'd125;
	of_ie_operand_sou = 8'd124;
	of_ie_operand_des_high = 8'd0;
	of_ie_operand_sou_high = 8'd0;
	of_ie_flag_reg = 8'h00;	
	# 40
	of_ie_operation = 5'd4;   // SBC
	of_ie_operand_des = 8'd124;
	of_ie_operand_sou = 8'd124;
	of_ie_operand_des_high = 8'd0;
	of_ie_operand_sou_high = 8'd0;
	of_ie_flag_reg = 8'hff;	
	# 40
	of_ie_operation = 5'd3;   // SUB
	of_ie_operand_des = 8'd0;
	of_ie_operand_sou = 8'h80;
	of_ie_operand_des_high = 8'd0;
	of_ie_operand_sou_high = 8'd0;
	of_ie_flag_reg = 8'h00;	
	# 40
	of_ie_operation = 5'd3;   // SUB
	of_ie_operand_des = 8'd0;
	of_ie_operand_sou = 8'h00;
	of_ie_operand_des_high = 8'd0;
	of_ie_operand_sou_high = 8'd0;
	of_ie_flag_reg = 8'h00;		
end


endmodule