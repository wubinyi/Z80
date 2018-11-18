// Company           :   tud                      
// Author            :   wubi17            
// E-Mail            :   <email>                    
//                    			
// Filename          :   z80.v                
// Project Name      :   prz    
// Subproject Name   :   main    
// Description       :   <short description>            
//
// Create Date       :   Wed Sep  6 15:02:04 2017 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module z80(
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

input             clk;
input             reset;
input             nmi;
input             int;
inout      [7:0]  data;
output reg [15:0] address_out;
output reg        m1_out;
output reg        wr_out;
output reg        rd_out;
output reg        mreq_out;
output reg        iorq_out;
output reg        halt_out;


wire [7:0]  cpu_data_input;
wire [7:0]  cpu_data_output_output;
wire [7:0]  cpu_data_os;
wire [15:0] address;
wire        m1;
wire        wr;
wire        rd;
wire        mreq;
wire        iorq_o;
wire        halt_o;

wire        pram_ce;
wire        dram_ce;
wire        dram_wr;
wire        m1_o;
wire        mreq_o;
wire        rd_o;
wire        wr_o;

wire [7:0]  pram_data;
wire [7:0]  dram_input;
wire [7:0]  dram_output;
wire [7:0]  io_input;
wire [7:0]  io_output;	

z80_cpu z80_cpu_0(
	.clk(clk),
	.reset(reset),
	.nmi(nmi),
	.int(int),
	.data_input(cpu_data_input),
	.data_output_output(cpu_data_output_output),
	.data_bus_os(cpu_data_os),
	.address(address),
	.m1(m1),
	.wr(wr),
	.rd(rd),
	.mreq(mreq),
	.iorq(iorq_o),
	.halt(halt_o)
);

mem_control mem_control_0(
	.m1(m1),
	.mreq(mreq),
	//.rd(rd),
	.wr(wr),
	.address(address),
	.pram_ce(pram_ce),
	.dram_ce(dram_ce),
	.dram_wr(dram_wr)
	//.m1_o(m1_o),
	//.mreq_o(mreq_o),
	//.rd_o(rd_o),
	//.wr_o(wr_o)		
);

data_bus data_bus_0(
	.m1(m1),
	.mreq(mreq),
	.rd(rd),
	.wr(wr),
	.cpu_data_input(cpu_data_input),
	.cpu_data_output_output(cpu_data_output_output),
	.cpu_data_os(cpu_data_os),
	.pram_data(pram_data),
	.dram_input(dram_input),
	.dram_output(dram_output),
	.io_input(io_input),
	.io_output(io_output)
);

always @(address) begin
	address_out = address;
end
always @(iorq_o) begin
	iorq_out = iorq_o;
end
always @(halt_o) begin
	halt_out = halt_o;
end
always @(m1) begin
	m1_out = m1;
end
always @(mreq) begin
	mreq_out = mreq;
end
always @(rd) begin
	rd_out = rd;
end
always @(wr) begin
	wr_out = wr;
end

wire io_input_flag;
assign io_input_flag = m1 & (~wr) & rd & mreq;
assign data = io_input_flag ? io_input : 8'hzz;
wire io_output_flag;
assign io_output_flag = m1 & wr & (~rd) & mreq;
assign io_output = io_output_flag ? data : 8'h00;


// ===================  pram  ========================
wire [32:0] pram_data_dword;
reg  [7:0] pram_data_temp;
reg pram_csb;
SY180_1024X8X4CM4 #(.INITFILE0("INITFILE0")) sy180_1024_ram_0(
	.A0(address[0]),
	.A1(address[1]),
	.A2(address[2]),
	.A3(address[3]),
	.A4(address[4]),
	.A5(address[5]),
	.A6(address[6]),
	.A7(address[7]),
	.A8(address[8]),
	.A9(address[9]),
	.DO0(pram_data_dword[0]),
	.DO1(pram_data_dword[1]),
	.DO2(pram_data_dword[2]),
	.DO3(pram_data_dword[3]),
	.DO4(pram_data_dword[4]),
	.DO5(pram_data_dword[5]),
	.DO6(pram_data_dword[6]),
	.DO7(pram_data_dword[7]),
	.DO8(pram_data_dword[8]),
	.DO9(pram_data_dword[9]),
	.DO10(pram_data_dword[10]),
	.DO11(pram_data_dword[11]),
	.DO12(pram_data_dword[12]),
	.DO13(pram_data_dword[13]),
	.DO14(pram_data_dword[14]),
	.DO15(pram_data_dword[15]),
	.DO16(pram_data_dword[16]),
	.DO17(pram_data_dword[17]),
	.DO18(pram_data_dword[18]),
	.DO19(pram_data_dword[19]),
	.DO20(pram_data_dword[20]),
	.DO21(pram_data_dword[21]),
	.DO22(pram_data_dword[22]),
	.DO23(pram_data_dword[23]),
	.DO24(pram_data_dword[24]),
	.DO25(pram_data_dword[25]),
	.DO26(pram_data_dword[26]),
	.DO27(pram_data_dword[27]),
	.DO28(pram_data_dword[28]),
	.DO29(pram_data_dword[29]),
	.DO30(pram_data_dword[30]),
	.DO31(pram_data_dword[31]),
	.DI0(1'b0),
	.DI1(1'b0),
	.DI2(1'b0),
	.DI3(1'b0),
	.DI4(1'b0),
	.DI5(1'b0),
	.DI6(1'b0),
	.DI7(1'b0),
	.DI8(1'b0),
	.DI9(1'b0),
	.DI10(1'b0),
	.DI11(1'b0),
	.DI12(1'b0),
	.DI13(1'b0),
	.DI14(1'b0),
	.DI15(1'b0),
	.DI16(1'b0),
	.DI17(1'b0),
	.DI18(1'b0),
	.DI19(1'b0),
	.DI20(1'b0),
	.DI21(1'b0),
	.DI22(1'b0),
	.DI23(1'b0),
	.DI24(1'b0),
	.DI25(1'b0),
	.DI26(1'b0),
	.DI27(1'b0),
	.DI28(1'b0),
	.DI29(1'b0),
	.DI30(1'b0),
	.DI31(1'b0),
	.CK(clk),
	.WEB0(1'b1),
	.WEB1(1'b1),
	.WEB2(1'b1),
	.WEB3(1'b1),
	.CSB(pram_csb)
);
always @(negedge clk or negedge reset) begin
	if (!reset) begin
		pram_csb <= 1'b1;
	end
	else if(pram_ce == 1'b0) begin
	//else begin
		pram_csb <= ~pram_csb;
	end
end
always @ (pram_data_dword or address[11:10])
	begin
	  	case({address[10], address[11]})
	  		2'b00:begin
	  			pram_data_temp <= pram_data_dword[7:0];
	  		end
	  		2'b01:begin
	  			pram_data_temp <= pram_data_dword[15:8];
	  		end
	  		2'b10:begin
	  			pram_data_temp <= pram_data_dword[23:16];
	  		end
	  		2'b11:begin
	  			pram_data_temp <= pram_data_dword[31:24];
	  		end
	    endcase
	end
assign pram_data = pram_data_temp;

//========================  dram  ======================
wire [7:0] dram_data_out_0; 
wire [7:0] dram_data_out_1; 
reg csb_0;
reg csb_1;
reg web;
SY180_256X8X1CM8 #(.INITFILE("INITFILE")) sy180_256_ram_0(
	.A0(address[0]),
	.A1(address[1]),
	.A2(address[2]),
	.A3(address[3]),
	.A4(address[4]),
	.A5(address[5]),
	.A6(address[6]),
	.A7(address[7]),
	.DO0(dram_data_out_0[0]),
	.DO1(dram_data_out_0[1]),
	.DO2(dram_data_out_0[2]),
	.DO3(dram_data_out_0[3]),
	.DO4(dram_data_out_0[4]),
	.DO5(dram_data_out_0[5]),
	.DO6(dram_data_out_0[6]),
	.DO7(dram_data_out_0[7]),
	.DI0(dram_input[0]),
	.DI1(dram_input[1]),
	.DI2(dram_input[2]),
	.DI3(dram_input[3]),
	.DI4(dram_input[4]),
	.DI5(dram_input[5]),
	.DI6(dram_input[6]),
	.DI7(dram_input[7]),
	.WEB(web),
	.CK(clk),
	.CSB(csb_0)
);

SY180_256X8X1CM8 sy180_256_ram_1(
	.A0(address[0]),
	.A1(address[1]),
	.A2(address[2]),
	.A3(address[3]),
	.A4(address[4]),
	.A5(address[5]),
	.A6(address[6]),
	.A7(address[7]),
	.DO0(dram_data_out_1[0]),
	.DO1(dram_data_out_1[1]),
	.DO2(dram_data_out_1[2]),
	.DO3(dram_data_out_1[3]),
	.DO4(dram_data_out_1[4]),
	.DO5(dram_data_out_1[5]),
	.DO6(dram_data_out_1[6]),
	.DO7(dram_data_out_1[7]),
	.DI0(dram_input[0]),
	.DI1(dram_input[1]),
	.DI2(dram_input[2]),
	.DI3(dram_input[3]),
	.DI4(dram_input[4]),
	.DI5(dram_input[5]),
	.DI6(dram_input[6]),
	.DI7(dram_input[7]),
	.WEB(web),
	.CK(clk),
	.CSB(csb_1)
);
// read\write  ram_0 : when dram_ce=0, address_bus[8]=0
//assign csb_0 = dram_ce | (address[8]);
// read\write  ram_1 : when dram_ce=0, address_bus[8]=1
//assign csb_1 = dram_ce | (~address[8]);
always @(negedge clk or negedge reset) begin
	if (!reset) begin
		csb_0 <= 1'b1;
		csb_1 <= 1'b1;
		web <= 1'b1;
	end
	else begin
		if ((dram_ce || address[8]) == 1'b0) begin
			csb_0 <= ~csb_0;
		end
		if ((dram_ce || (~address[8])) == 1'b0) begin
			csb_1 <= ~csb_1;
		end
		if (dram_wr == 1'b0) begin
			web <= ~web;
		end
	end
end
// always @(posedge clk or negedge reset) begin
// 	if (!reset) begin
// 		//csb_0 <= 1'b1;
// 		//csb_1 <= 1'b1;
// 		web <= 1'b1;
// 	end
// 	else begin
// 		//csb_0 <= dram_ce || address[8];
// 		//csb_1 <= dram_ce | (~address[8]);
// 		web <= dram_wr;
// 	end
// end

// reg  [7:0] dram_output_temp;
// always @(address[8] or dram_data_out_0 or dram_data_out_1) begin
// 	case(address[8])
// 		1'b0: dram_output_temp <= dram_data_out_0;
// 		1'b1: dram_output_temp <= dram_data_out_1;
// 	endcase
// end
assign dram_output = address[8] ? dram_data_out_1 : dram_data_out_0;
endmodule