	case(if_fsm_num_bytes)
		//------------------------------------------------------------------------------------------------------------------------
		// *******************************  one byte instruction  ****************************************************************
		//------------------------------------------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------------------------------------------
		// *******************************  two byte instruction  *****************************************************************
		//-------------------------------------------------------------------------------------------------------------------------
		3'd2:begin
			case(instruction[15:0])
				// ============   8-bit load group: register to Implied  ============
				16'h47ed:begin
					fsm_of_sou <= 8'd0; // A
					fsm_of_des <= 8'd8; // I
					ofos_operation_type <= LOAD_REG2IMP;
					function_sel <= LOAD_REG2IMP;
				end
				16'h4fed:begin
					fsm_of_sou <= 8'd0; // A
					fsm_of_des <= 8'd9; // R
					ofos_operation_type <= LOAD_REG2IMP;
					function_sel <= LOAD_REG2IMP;
				end
				// ===============   8-bit load: Implied to register ================
				16'h57ed:begin
					fsm_of_sou <= 8'd8; // I
					fsm_of_des <= 8'd0; // A
					ofos_operation_type <= LOAD_IMP2REG;
					function_sel <= LOAD_IMP2REG;
				end	
				16'h5fed:begin
					fsm_of_sou <= 8'd9; // R
					fsm_of_des <= 8'd0; // A
					ofos_operation_type <= LOAD_IMP2REG;
					function_sel <= LOAD_IMP2REG;
				end	
				// ============   16-bit load: IX to SP ============
				16'hf9dd:begin
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= LOAD_16_BIT_IX2SP;
					function_sel <= LOAD_16_BIT_IX2SP;
				end
				// ============   16-bit load: IY to SP ============
				16'hf9fd:begin
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= LOAD_16_BIT_IY2SP;
					function_sel <= LOAD_16_BIT_IY2SP;
				end
				// ============   16-bit PUSH: IX or IY to (SP) ============
				16'he5dd, 16'he5fd:begin
					case(instruction[5])
						1'b0: fsm_of_sou <= REG_IX;
						1'b1: fsm_of_sou <= REG_IY;
					endcase
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= PUSH;
					function_sel <= PUSH;
				end
				// ============   16-bit POP: (SP) to IX or IY ============
				16'he1dd, 16'he1fd:begin
					case(instruction[5])
						1'b0: fsm_of_des <= REG_IX;
						1'b1: fsm_of_des <= REG_IY;
					endcase
					fsm_of_sou <= 8'd0;   // unuseful
					ofos_operation_type <= POP;
					function_sel <= POP;
				end
				// ==================  exchange  ==================
				16'he3dd:begin
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= EX_IX_AND_MEM_SP;
					function_sel <= EX_IX_AND_MEM_SP;
				end
				16'he3fd:begin
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= EX_IY_AND_MEM_SP;
					function_sel <= EX_IY_AND_MEM_SP;
				end
				// ====================  16-BIT arithmetic ADD_OP ====================
				16'h09dd, 16'h19dd, 16'h29dd, 16'h39dd:begin
					ofos_operation_type <= OE_ADD_16_BIT;
					function_sel <= OE_ADD_16_BIT;
					fsm_of_des <= REG_IX; 	//IX// dd
					case(instruction[13:12])
						2'b00: fsm_of_sou <= REG_BC; // BC
						2'b01: fsm_of_sou <= REG_DE; // DE
						2'b10: fsm_of_sou <= REG_IX; // IX
						2'b11: fsm_of_sou <= REG_SP; // SP
					endcase
				end
				16'h09fd, 16'h19fd, 16'h29fd, 16'h39fd:begin
					ofos_operation_type <= OE_ADD_16_BIT;
					function_sel <= OE_ADD_16_BIT; 
					fsm_of_des <= REG_IY; 	//IY// fd							
					case(instruction[13:12])
						2'b00: fsm_of_sou <= REG_BC; // BC
						2'b01: fsm_of_sou <= REG_DE; // DE
						2'b10: fsm_of_sou <= REG_IY; // IY
						2'b11: fsm_of_sou <= REG_SP; // SP
					endcase
				end
				// ====================  16-BIT arithmetic ADC_OP ====================
				16'h4aed, 16'h5aed, 16'h6aed, 16'h7aed:begin
					ofos_operation_type <= OE_ADC_16_BIT;
					function_sel <= OE_ADC_16_BIT;
					fsm_of_des <= REG_HL;
					case(instruction[13:12])
						2'b00: fsm_of_sou <= REG_BC; // BC
						2'b01: fsm_of_sou <= REG_DE; // DE
						2'b10: fsm_of_sou <= REG_HL; // HL
						2'b11: fsm_of_sou <= REG_SP; // SP
					endcase
				end	
				// ====================  16-BIT arithmetic SBC_OP ====================				
				16'h42ed, 16'h52ed, 16'h62ed, 16'h72ed:begin
					ofos_operation_type <= OE_SBC_16_BIT;
					function_sel <= OE_SBC_16_BIT;
					fsm_of_des <= REG_HL;
					case(instruction[13:12])
						2'b00: fsm_of_sou <= REG_BC; // BC
						2'b01: fsm_of_sou <= REG_DE; // DE
						2'b10: fsm_of_sou <= REG_HL; // HL
						2'b11: fsm_of_sou <= REG_SP; // SP
					endcase						
				end
				// ====================  16-BIT arithmetic INC_OP ====================
				16'h23dd, 16'h23fd:begin
					ofos_operation_type <= OE_INC_16_BIT;
					function_sel <= OE_INC_16_BIT;
					case(instruction[5])
						1'b0:begin
							fsm_of_des <= REG_IX; // IX
							fsm_of_sou <= REG_IX; // IX
						end 
						1'b1:begin
							fsm_of_des <= REG_IY; // IY
							fsm_of_sou <= REG_IY; // IY
						end 
					endcase						
				end
				// ====================  16-BIT arithmetic DEC_OP ====================
				16'h2bdd, 16'h2bfd:begin
					ofos_operation_type <= OE_DEC_16_BIT;
					function_sel <= OE_DEC_16_BIT;
					case(instruction[5])
						1'b0:begin
							fsm_of_des <= REG_IX; // IX
							fsm_of_sou <= REG_IX; // IX
						end 
						1'b1:begin
							fsm_of_des <= REG_IY; // IY
							fsm_of_sou <= REG_IY; // IY
						end 
					endcase						
				end
				// ====================  General Purpose AF Operation ====================
				16'h44ed:begin
					ofos_operation_type <= OE_NEG;
					function_sel <= OE_NEG;
					//fsm_ie_oper_sel <= SUB_AF;
					//fsm_of_sou <= 8'd0;
					//fsm_of_des <= 8'd0;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				// ================  rotates and shift: mem HL  ===================
				16'h06cb, 16'h0ecb, 16'h16cb, 16'h1ecb,
				16'h26cb, 16'h2ecb, 16'h3ecb:begin
					ofos_operation_type <= RS_MEM_HL;
					function_sel <= RS_MEM_HL;
					case(instruction[13:11])
						3'b000: fsm_of_des <= RLC_OP;
						3'b001: fsm_of_des <= RRC_OP;
						3'b010: fsm_of_des <= RL_OP;
						3'b011: fsm_of_des <= RR_OP;
						3'b100: fsm_of_des <= SLA_OP;
						3'b101: fsm_of_des <= SRA_OP;
						//3'b110:
						3'b111: fsm_of_des <= SRL_OP;
					endcase	
					fsm_of_sou <= 8'd0;   // unuseful					
				end
				16'h6fed, 16'h67ed:begin
					ofos_operation_type <= RS_MEM_HL;
					function_sel <= RS_MEM_HL;
					case(instruction[11])
						1'b0: fsm_of_des <= RRD_OP;
						1'b1: fsm_of_des <= RLD_OP;
					endcase
					fsm_of_sou <= 8'd0;   // unuseful
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
							function_sel <= BM_TEST;
							ofos_operation_type <= BM_TEST;
							//fsm_ie_oper_sel <= TEST_BIT;
						end 
						2'b10:begin
							function_sel <= BM_RESET;
							ofos_operation_type <= BM_RESET;
							//fsm_ie_oper_sel <= RESET_BIT;
						end 
						2'b11:begin
							function_sel <= BM_SET;
							ofos_operation_type <= BM_SET;
							//fsm_ie_oper_sel <= SET_BIT;
						end 
					endcase
					case(instruction[10:8])
						3'b111: fsm_of_des <= 8'd0;    // A
						3'b000: fsm_of_des <= 8'd1;    // B
						3'b001: fsm_of_des <= 8'd2;    // C
						3'b010: fsm_of_des <= 8'd3;    // D
						3'b011: fsm_of_des <= 8'd4;    // E
						3'b100: fsm_of_des <= 8'd6;    // H <-- F
						3'b101: fsm_of_des <= 8'd7;    // L
					endcase
					fsm_of_sou <= {5'b00000, instruction[13:11]};
					/*case(instruction[13:11])
						3'b000: fsm_of_sou <= 8'd0;    // bit 0
						3'b001: fsm_of_sou <= 8'd1;    // bit 1
						3'b010: fsm_of_sou <= 8'd2;    // bit 2
						3'b011: fsm_of_sou <= 8'd3;    // bit 3
						3'b100: fsm_of_sou <= 8'd4;    // bit 4
						3'b101: fsm_of_sou <= 8'd5;    // bit 5
						3'b110: fsm_of_sou <= 8'd6;    // bit 6
						3'b111: fsm_of_sou <= 8'd7;    // bit 7
					endcase*/
				end
				16'h46cb, 16'h4ecb, 16'h56cb, 16'h5ecb, 16'h66cb, 16'h6ecb, 16'h76cb, 16'h7ecb,
				16'h86cb, 16'h8ecb, 16'h96cb, 16'h9ecb, 16'ha6cb, 16'haecb, 16'hb6cb, 16'hbecb,
				16'hc6cb, 16'hcecb, 16'hd6cb, 16'hdecb, 16'he6cb, 16'heecb, 16'hf6cb, 16'hfecb:begin
					case(instruction[15:14])
						2'b01:begin
							function_sel <= BM_TEST_MEM_HL;
							ofos_operation_type <= BM_TEST_MEM_HL;
							//fsm_ie_oper_sel <= TEST_BIT;
							fsm_of_des <= 8'd0;   // unuseful
						end 
						2'b10:begin
							function_sel <= BM_SET_RESET_MEM_HL;
							ofos_operation_type <= BM_SET_RESET_MEM_HL;
							fsm_of_des <= RESET_BIT;
						end 
						2'b11:begin
							function_sel <= BM_SET_RESET_MEM_HL;
							ofos_operation_type <= BM_SET_RESET_MEM_HL;
							fsm_of_des <= SET_BIT;
						end 
					endcase	
					fsm_of_sou <= {5'b00000, instruction[13:11]};					
				end
				// ============= jump: IX IY =============
				16'he9fd, 16'he9dd:begin
					ofos_operation_type <= JUMP_REG_IND;
					function_sel <= JUMP_REG_IND;
					case(instruction[5])
						1'b0: fsm_of_sou <= REG_IX;
						1'b1: fsm_of_sou <= REG_IY;
					endcase
					fsm_of_des <= 8'd0;   // unuseful
				end
				// =============  input group: input reg ind. to reg  ==============
				16'h40ed, 16'h48ed, 16'h50ed, 16'h58ed, 16'h60ed, 16'h68ed, 16'h78ed:begin
					ofos_operation_type <= IN_MEM_REG_IND;
					function_sel <= IN_MEM_REG_IND;
					case(instruction[13:11])
						3'b111: fsm_of_des <= 8'd0;    // A
						3'b000: fsm_of_des <= 8'd1;    // B
						3'b001: fsm_of_des <= 8'd2;    // C
						3'b010: fsm_of_des <= 8'd3;    // D
						3'b011: fsm_of_des <= 8'd4;    // E
						3'b100: fsm_of_des <= 8'd6;    // H <-- F
						3'b101: fsm_of_des <= 8'd7;    // L
					endcase
					fsm_of_sou <= 8'd0;   // unuseful
				end
				// =============  input group: ini,inir,ind,indr  ============== 
				16'ha2ed:begin
					ofos_operation_type <= INI;
					function_sel <= INI;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'hb2ed:begin
					ofos_operation_type <= INIR;
					function_sel <= INIR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'haaed:begin
					ofos_operation_type <= IND;
					function_sel <= IND;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'hbaed:begin
					ofos_operation_type <= INDR;
					function_sel <= INDR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				// =============  output group: reg to input reg ind.  ==============
				16'h41ed, 16'h49ed, 16'h51ed, 16'h59ed, 16'h61ed, 16'h69ed, 16'h79ed:begin
					ofos_operation_type <= OUT_MEM_REG_IND;
					function_sel <= OUT_MEM_REG_IND;
					case(instruction[13:11])
						3'b111: fsm_of_sou <= 8'd0;    // A
						3'b000: fsm_of_sou <= 8'd1;    // B
						3'b001: fsm_of_sou <= 8'd2;    // C
						3'b010: fsm_of_sou <= 8'd3;    // D
						3'b011: fsm_of_sou <= 8'd4;    // E
						3'b100: fsm_of_sou <= 8'd6;    // H <-- F
						3'b101: fsm_of_sou <= 8'd7;    // L
					endcase	
					fsm_of_des <= 8'd0;   // unuseful					
				end
				// =============  output group: outi,otir,outd,otdr  ============== 
				16'ha3ed:begin
					ofos_operation_type <= OUTI;
					function_sel <= OUTI;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'hb3ed:begin
					ofos_operation_type <= OTIR;
					function_sel <= OTIR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'habed:begin
					ofos_operation_type <= OUTD;
					function_sel <= OUTD;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'hbbed:begin
					ofos_operation_type <= OTDR;
					function_sel <= OTDR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				// ========  block transfer group: lidi,ldir,ldd,lddr  =========
				16'ha0ed:begin
					ofos_operation_type <= LDI;
					function_sel <= LDI;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'hb0ed:begin
					ofos_operation_type <= LDIR;
					function_sel <= LDIR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'ha8ed:begin
					ofos_operation_type <= LDD;
					function_sel <= LDD;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				16'hb8ed:begin
					ofos_operation_type <= LDDR;
					function_sel <= LDDR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				// ========  block search group: cpi, cpir, cpd, cpdr  =========
				16'ha1ed:begin
					ofos_operation_type <= CPI;
					function_sel <= CPI;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					//fsm_ie_oper_sel <= BS_COMPARE;
				end
				16'hb1ed:begin
					ofos_operation_type <= CPIR;
					function_sel <= CPIR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					//fsm_ie_oper_sel <= BS_COMPARE;
				end
				16'ha9ed:begin
					ofos_operation_type <= CPD;
					function_sel <= CPD;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					//fsm_ie_oper_sel <= BS_COMPARE;
				end
				16'hb9ed:begin
					ofos_operation_type <= CPDR;
					function_sel <= CPDR;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					//fsm_ie_oper_sel <= BS_COMPARE;
				end
				// ====================== cpu control =======================
				16'h46ed:begin
					function_sel <= IM0;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= NO_FUNCTION; //unuseful
					//int_mode <= INT_MODE_0;
				end
				16'h56ed:begin
					function_sel <= IM1;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= NO_FUNCTION; //unuseful
					//int_mode <= INT_MODE_1;
				end
				16'h5eed:begin
					function_sel <= IM2;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= NO_FUNCTION; //unuseful
					//int_mode <= INT_MODE_2;
				end
				// ====================== RETI RETN =======================
				16'h4ded:begin
					function_sel <= RETI;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
					ofos_operation_type <= RETI;
				end
				16'h45ed:begin
					function_sel <= RETN;
					ofos_operation_type <= RETN;
					fsm_of_sou <= 8'd0;   // unuseful
					fsm_of_des <= 8'd0;   // unuseful
				end
				default:begin
					case(instruction[7:0])
						// =============   8-bit load: imm. to register =============
						8'h3e,8'h06,8'h0e,8'h16,8'h1e,8'h26,8'h2e:
						begin
							ofos_operation_type <= LOAD_IMM2REG;
							function_sel <= LOAD_IMM2REG;
							case(instruction[5:3])
								3'b111: fsm_of_des <= 8'd0;    // A
								3'b000: fsm_of_des <= 8'd1;    // B
								3'b001: fsm_of_des <= 8'd2;    // C
								3'b010: fsm_of_des <= 8'd3;    // D
								3'b011: fsm_of_des <= 8'd4;    // E
								3'b100: fsm_of_des <= 8'd6;    // H
								3'b101: fsm_of_des <= 8'd7;    // L
							endcase
							fsm_of_sou <= instruction[15:8];
						end
						// =============   8-bit load: imm. to reg indirect =============
						8'h36:begin
							ofos_operation_type <= LOAD_IMM2MEM_REG_IND;
							function_sel <= LOAD_IMM2MEM_REG_IND;
							fsm_of_sou <= instruction[15:8];
							fsm_of_des <= 8'd0;   // unuseful
						end
						// =====================   8-bit arithmetic ======================
						8'hc6, 8'hce, 8'hd6, 8'hde, 8'he6, 8'hee, 8'hf6, 8'hfe:begin
							ofos_operation_type <= OE_IMM;
							function_sel <= OE_IMM;			
							fsm_of_sou <= instruction[15:8];
							case(instruction[5:3])
								3'b000: fsm_of_des <= ADD_OP;
								3'b001: fsm_of_des <= ADC_OP;
								3'b010: fsm_of_des <= SUB_OP;
								3'b011: fsm_of_des <= SBC_OP;
								3'b100: fsm_of_des <= AND_OP;
								3'b101: fsm_of_des <= XOR_OP;
								3'b110: fsm_of_des <= OR_OP;
								3'b111: fsm_of_des <= CP_OP;
							endcase					
						end
						// =================  rotates and shift: reg  ====================
						8'hcb:begin
							ofos_operation_type <= RS_REG;
							function_sel <= RS_REG;
							case(instruction[13:11])
								3'b000: fsm_of_des <= RLC_OP;
								3'b001: fsm_of_des <= RRC_OP;
								3'b010: fsm_of_des <= RL_OP;
								3'b011: fsm_of_des <= RR_OP;
								3'b100: fsm_of_des <= SLA_OP;
								3'b101: fsm_of_des <= SRA_OP;
								//3'b110:
								3'b111: fsm_of_des <= SRL_OP;
							endcase
							case(instruction[10:8])
								3'b111: fsm_of_sou <= 8'd0;    // A
								3'b000: fsm_of_sou <= 8'd1;    // B
								3'b001: fsm_of_sou <= 8'd2;    // C
								3'b010: fsm_of_sou <= 8'd3;    // D
								3'b011: fsm_of_sou <= 8'd4;    // E
								3'b100: fsm_of_sou <= 8'd6;    // H
								3'b101: fsm_of_sou <= 8'd7;    // L
							endcase
						end
						// =================  jump relative  ====================
						8'h18:begin  // unconditional jump
							ofos_operation_type <= JUMP_RELATIVE;
							function_sel <= JUMP_RELATIVE;
							fsm_of_sou <= instruction[15:8];
							fsm_of_des <= 8'd0;   // unuseful
							//fsm_ie_oper_sel <= ADD_16BIT_NONE_AFFECT;
						end
						8'h20, 8'h28, 8'h30, 8'h38:begin
							case({instruction[4:3], carry, zero})
								4'b0000, 4'b0010,
								4'b0101, 4'b0111,
								4'b1000, 4'b1001,
								4'b1110, 4'b1111:begin  // jump
									ofos_operation_type <= JUMP_RELATIVE;
									function_sel <= JUMP_RELATIVE;
									fsm_of_sou <= instruction[15:8];
									fsm_of_des <= 8'd0;   // unuseful
									//fsm_ie_oper_sel <= ADD_16BIT_NONE_AFFECT;
								end
								4'b0001, 4'b0011,
								4'b0100, 4'b0110,
								4'b1010, 4'b1011,
								4'b1100, 4'b1101:begin  // do not jump
									ofos_operation_type <= NO_JUMP;
									function_sel <= NO_JUMP;
									fsm_of_sou <= 8'd0;   // unuseful
									fsm_of_des <= 8'd0;   // unuseful
								end
							endcase
						end
						// =================  jump djnz  ====================
						8'h10:begin
							ofos_operation_type <= JUMP_DJNZ;
							function_sel <= JUMP_DJNZ;
							fsm_of_sou <= instruction[15:8];
							//fsm_ie_oper_sel <= ADD_16BIT_NONE_AFFECT;	
							fsm_of_des <= 8'd0;   // unuseful							
						end
						// =============  input group: input mem. extend to A  ==============
						8'hdb:begin
							ofos_operation_type <= IN_MEM_EXTEND;
							function_sel <= IN_MEM_EXTEND;
							fsm_of_sou <= instruction[15:8];
							fsm_of_des <= 8'd0;   // unuseful
						end
						// =============  output group: A to input mem. extend  ==============
						8'hd3:begin
							ofos_operation_type <= OUT_MEM_EXTEND;
							function_sel <= OUT_MEM_EXTEND;
							fsm_of_des <= instruction[15:8];
							fsm_of_sou <= 8'd0;   // unuseful
						end
						default:begin
							function_sel <= NO_FUNCTION;
							ofos_operation_type <= NO_FUNCTION;
							fsm_of_des <= 8'b0;
							fsm_of_sou <= 8'b0;
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
					fsm_of_sou <= instruction[23:16]; // d
					case(instruction[13:11])
						3'b111: fsm_of_des <= 8'd0;    // A
						3'b000: fsm_of_des <= 8'd1;    // B
						3'b001: fsm_of_des <= 8'd2;    // C
						3'b010: fsm_of_des <= 8'd3;    // D
						3'b011: fsm_of_des <= 8'd4;    // E
						3'b100: fsm_of_des <= 8'd6;    // H
						3'b101: fsm_of_des <= 8'd7;    // L
					endcase
					ofos_operation_type <= LOAD_MEM2REG_INDEXED_IX;
					function_sel <= LOAD_MEM2REG_INDEXED_IX;
				end
				16'h7efd,16'h46fd,16'h4efd,16'h56fd,16'h5efd,16'h66fd,16'h6efd:begin
					fsm_of_sou <= instruction[23:16]; // d
					case(instruction[13:11])
						3'b111: fsm_of_des <= 8'd0;    // A
						3'b000: fsm_of_des <= 8'd1;    // B
						3'b001: fsm_of_des <= 8'd2;    // C
						3'b010: fsm_of_des <= 8'd3;    // D
						3'b011: fsm_of_des <= 8'd4;    // E
						3'b100: fsm_of_des <= 8'd6;    // H
						3'b101: fsm_of_des <= 8'd7;    // L
					endcase
					ofos_operation_type <= LOAD_MEM2REG_INDEXED_IY;
					function_sel <= LOAD_MEM2REG_INDEXED_IY;		
				end
				// =============   8-bit load: reg to indexed(mem)============
				16'h77dd,16'h70dd,16'h71dd,16'h72dd,16'h73dd,16'h74dd,16'h75dd:begin
					ofos_operation_type <= LOAD_REG2MEM_INDEXED_IX;
					function_sel <= LOAD_REG2MEM_INDEXED_IX;
					fsm_of_des <= instruction[23:16]; // d	
					case(instruction[10:8])
						3'b111: fsm_of_sou <= 8'd0;    // A
						3'b000: fsm_of_sou <= 8'd1;    // B
						3'b001: fsm_of_sou <= 8'd2;    // C
						3'b010: fsm_of_sou <= 8'd3;    // D
						3'b011: fsm_of_sou <= 8'd4;    // E
						3'b100: fsm_of_sou <= 8'd6;    // H <-- F
						3'b101: fsm_of_sou <= 8'd7;    // L
					endcase					
				end
				16'h77fd,16'h70fd,16'h71fd,16'h72fd,16'h73fd,16'h74fd,16'h75fd:begin
					ofos_operation_type <= LOAD_REG2MEM_INDEXED_IY;
					function_sel <= LOAD_REG2MEM_INDEXED_IY;
					fsm_of_des <= instruction[23:16]; // d	
					case(instruction[10:8])
						3'b111: fsm_of_sou <= 8'd0;    // A
						3'b000: fsm_of_sou <= 8'd1;    // B
						3'b001: fsm_of_sou <= 8'd2;    // C
						3'b010: fsm_of_sou <= 8'd3;    // D
						3'b011: fsm_of_sou <= 8'd4;    // E
						3'b100: fsm_of_sou <= 8'd6;    // H <-- F
						3'b101: fsm_of_sou <= 8'd7;    // L
					endcase					
				end
				// =========================   8-bit arithmetic ======================== 
				16'h86dd,16'h8edd,16'h96dd,16'h9edd,16'ha6dd,16'haedd,16'hb6dd,16'hbedd:begin
					ofos_operation_type <= OE_MEM_INDEX_IX;
					function_sel <= OE_MEM_INDEX_IX;
					fsm_of_sou <= instruction[23:16]; // d
					// use fsm_of_des as indicator
					case(instruction[13:11])
						3'b000: fsm_of_des <= ADD_OP;
						3'b001: fsm_of_des <= ADC_OP;
						3'b010: fsm_of_des <= SUB_OP;
						3'b011: fsm_of_des <= SBC_OP;
						3'b100: fsm_of_des <= AND_OP;
						3'b101: fsm_of_des <= XOR_OP;
						3'b110: fsm_of_des <= OR_OP;
						3'b111: fsm_of_des <= CP_OP;
					endcase
				end
				16'h86fd,16'h8efd,16'h96fd,16'h9efd,16'ha6fd,16'haefd,16'hb6fd,16'hbefd:begin
					ofos_operation_type <= OE_MEM_INDEX_IY;
					function_sel <= OE_MEM_INDEX_IY;
					fsm_of_sou <= instruction[23:16]; // d
					// use fsm_of_des as indicator
					case(instruction[13:11])
						3'b000: fsm_of_des <= ADD_OP;
						3'b001: fsm_of_des <= ADC_OP;
						3'b010: fsm_of_des <= SUB_OP;
						3'b011: fsm_of_des <= SBC_OP;
						3'b100: fsm_of_des <= AND_OP;
						3'b101: fsm_of_des <= XOR_OP;
						3'b110: fsm_of_des <= OR_OP;
						3'b111: fsm_of_des <= CP_OP;
					endcase
				end
				16'h34dd, 16'h35dd:begin
					ofos_operation_type <= OE_MEM_INDEX_MEM_IX;
					function_sel <= OE_MEM_INDEX_MEM_IX;
					fsm_of_sou <= instruction[23:16]; // d	
					// use fsm_of_des as indicator
					if (instruction[8]) begin
						fsm_of_des <= DEC_OP;
					end
					else begin
						fsm_of_des <= INC_OP;
					end	
				end
				16'h34fd, 16'h35fd:begin
					ofos_operation_type <= OE_MEM_INDEX_MEM_IY;
					function_sel <= OE_MEM_INDEX_MEM_IY;
					fsm_of_sou <= instruction[23:16]; // d	
					// use fsm_of_des as indicator
					if (instruction[8]) begin
						fsm_of_des <= DEC_OP;
					end
					else begin
						fsm_of_des <= INC_OP;
					end					
				end
				default:begin
					fsm_of_sou <= instruction[15:8];  // n  low
					fsm_of_des <= instruction[23:16]; // n  high						
					case(instruction[7:0])
						// =============   8-bit load: ext.(mem) to reg  ============
						8'h3a: begin
							//fsm_of_sou <= instruction[15:8];  // n  low
							//fsm_of_des <= instruction[23:16]; // n  high
							ofos_operation_type <= LOAD_MEM2REG_EXT;
							function_sel <= LOAD_MEM2REG_EXT;
						end
						// =============   8-bit load: reg(A) to indexed(mem)  ============
						8'h32: begin
							//fsm_of_sou <= instruction[15:8];  // n  low
							//fsm_of_des <= instruction[23:16]; // n  high
							ofos_operation_type <= LOAD_REG2MEM_EXT;
							function_sel <= LOAD_REG2MEM_EXT;
						end
						// =================   16-bit load: imm. to BC  ===================
						8'h01: begin
							//fsm_of_sou <= instruction[15:8];  // n  low
							//fsm_of_des <= instruction[23:16]; // n  high
							ofos_operation_type <= LOAD_16_BIT_IMM2BC;
							function_sel <= LOAD_16_BIT_IMM2BC;
						end
						// =================   16-bit load: imm. to DE  ===================
						8'h11: begin
							//fsm_of_sou <= instruction[15:8];  // n  low
							//fsm_of_des <= instruction[23:16]; // n  high
							ofos_operation_type <= LOAD_16_BIT_IMM2DE;
							function_sel <= LOAD_16_BIT_IMM2DE;
						end
						// =================   16-bit load: imm. to HL  ===================
						8'h21: begin
							//fsm_of_sou <= instruction[15:8];  // n  low
							//fsm_of_des <= instruction[23:16]; // n  high
							ofos_operation_type <= LOAD_16_BIT_IMM2HL;
							function_sel <= LOAD_16_BIT_IMM2HL;
						end
						// =================   16-bit load: imm. to SP  ===================
						8'h31: begin
							//fsm_of_sou <= instruction[15:8];  // n  low
							//fsm_of_des <= instruction[23:16]; // n  high
							ofos_operation_type <= LOAD_16_BIT_IMM2SP;
							function_sel <= LOAD_16_BIT_IMM2SP;
						end
						// =================   16-bit load: ext.(mem) to HL  ===================
						8'h2a: begin
							//fsm_of_sou <= instruction[15:8];  // n  low
							//fsm_of_des <= instruction[23:16]; // n  high
							ofos_operation_type <= LOAD_16_BIT_MEM2HL_EXT;
							function_sel <= LOAD_16_BIT_MEM2HL_EXT;
						end
						// =================   16-bit load:HL to ext.(mem)   ===================
						8'h22:begin
							ofos_operation_type <= LOAD_16_BIT_HL2MEM_EXT;
							function_sel <= LOAD_16_BIT_HL2MEM_EXT;
						end
						// =================   jump imm.   ===================
						8'hc3:begin
							ofos_operation_type <= JUMP_IMM;
							function_sel <= JUMP_IMM;
						end
						8'hc2, 8'hca:begin
							case({instruction[3], zero})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= JUMP_IMM;
									function_sel <= JUMP_IMM;
								end
							endcase
						end
						8'hd2, 8'hda:begin
							case({instruction[3], carry})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= JUMP_IMM;
									function_sel <= JUMP_IMM;
								end
							endcase								
						end
						8'he2, 8'hea:begin
							case({instruction[3], parity})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= JUMP_IMM;
									function_sel <= JUMP_IMM;
								end
							endcase								
						end
						8'hf2, 8'hfa:begin
							case({instruction[3], sign})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_JUMP;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= JUMP_IMM;
									function_sel <= JUMP_IMM;
								end
							endcase								
						end
						// =================   call imm.   ===================
						8'hcd:begin
							ofos_operation_type <= CALL;
							function_sel <= CALL;
							//fsm_ie_oper_sel <= SUB_OP;
						end
						8'hc4, 8'hcc:begin
							case({instruction[3], zero})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= CALL;
									function_sel <= CALL;
									//fsm_ie_oper_sel <= SUB_OP;
								end
							endcase								
						end
						8'hd4, 8'hdc:begin
							case({instruction[3], carry})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= CALL;
									function_sel <= CALL;
									//fsm_ie_oper_sel <= SUB_OP;
								end
							endcase								
						end
						8'he4, 8'hec:begin
							case({instruction[3], parity})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= CALL;
									function_sel <= CALL;
									//fsm_ie_oper_sel <= SUB_OP;
								end
							endcase								
						end	
						8'hf4, 8'hfc:begin
							case({instruction[3], sign})
								2'b01, 2'b10:begin  // no jump
									ofos_operation_type <= NO_FUNCTION;  // unuseful
									function_sel <= NO_CALL;
								end
								2'b00, 2'b11:begin
									ofos_operation_type <= CALL;
									function_sel <= CALL;
									//fsm_ie_oper_sel <= SUB_OP;
								end
							endcase								
						end
						default:begin
							function_sel <= NO_FUNCTION;
							ofos_operation_type <= NO_FUNCTION;
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
					fsm_of_sou <= instruction[31:24];
					fsm_of_des <= instruction[23:16];						
				end
				16'hcbdd, 16'hcbfd:begin   
					case(instruction[31:30])
						2'b00:begin// rotates and shift
							fsm_of_sou <= instruction[23:16];
							case(instruction[29:27])
								3'b000: fsm_of_des <= RLC_OP;
								3'b001: fsm_of_des <= RRC_OP;
								3'b010: fsm_of_des <= RL_OP;
								3'b011: fsm_of_des <= RR_OP;
								3'b100: fsm_of_des <= SLA_OP;
								3'b101: fsm_of_des <= SRA_OP;
								//3'b110:
								3'b111: fsm_of_des <= SRL_OP;
							endcase								
						end
						2'b01, 2'b10,
						2'b11:begin 
							fsm_of_sou <= {5'b00000, instruction[29:27]};
							fsm_of_des <= instruction[23:16];									
						end
					endcase	
				end
				default:begin
					fsm_of_sou <= instruction[23:16];
					fsm_of_des <= instruction[31:24];
				end
			endcase
			case(instruction[15:0])
				// =============   8-bit load: imm. to indexed(mem)============
				16'h36dd:begin
					//fsm_of_sou <= instruction[31:24];
					//fsm_of_des <= instruction[23:16];
					ofos_operation_type <= LOAD_IMM2MEM_INDEXED_IX;
					function_sel <= LOAD_IMM2MEM_INDEXED_IX;
				end
				16'h36fd:begin
					//fsm_of_sou <= instruction[31:24];
					//fsm_of_des <= instruction[23:16];
					ofos_operation_type <= LOAD_IMM2MEM_INDEXED_IY;
					function_sel <= LOAD_IMM2MEM_INDEXED_IY;
				end
				// =================   16-bit load: imm. to indexed(mem)  ===================
				16'h21dd:begin
					//fsm_of_sou <= instruction[23:16];
					//fsm_of_des <= instruction[31:24];
					ofos_operation_type <= LOAD_16_BIT_IMM2IX;
					function_sel <= LOAD_16_BIT_IMM2IX;
				end
				16'h21fd:begin
					//fsm_of_sou <= instruction[23:16];
					//fsm_of_des <= instruction[31:24];
					ofos_operation_type <= LOAD_16_BIT_IMM2IY;
					function_sel <= LOAD_16_BIT_IMM2IY;
				end
				// =================   16-bit load: ext.(mem) to reg(BC, DE, SP, IX, IY)  ===================
				16'h4bed:begin
					ofos_operation_type <= LOAD_16_BIT_MEM2BC_EXT;
					function_sel <= LOAD_16_BIT_MEM2BC_EXT;
				end 
				16'h5bed:begin
					ofos_operation_type <= LOAD_16_BIT_MEM2DE_EXT;
					function_sel <= LOAD_16_BIT_MEM2DE_EXT;
				end 
				16'h7bed:begin
					ofos_operation_type <= LOAD_16_BIT_MEM2SP_EXT;
					function_sel <= LOAD_16_BIT_MEM2SP_EXT;
				end 
				16'h2add:begin
					ofos_operation_type <= LOAD_16_BIT_MEM2IX_EXT;
					function_sel <= LOAD_16_BIT_MEM2IX_EXT;
				end 
				16'h2afd:begin
					ofos_operation_type <= LOAD_16_BIT_MEM2IY_EXT;
					function_sel <= LOAD_16_BIT_MEM2IY_EXT;
				end
				// =================   16-bit load: reg(BC, DE, SP, IX, IY) to ext.(mem)  ===================
				16'h43ed:begin
					ofos_operation_type <= LOAD_16_BIT_BC2MEM_EXT;
					function_sel <= LOAD_16_BIT_BC2MEM_EXT;
				end 
				16'h53ed:begin
					ofos_operation_type <= LOAD_16_BIT_DE2MEM_EXT;
					function_sel <= LOAD_16_BIT_DE2MEM_EXT;
				end 
				16'h73ed:begin
					ofos_operation_type <= LOAD_16_BIT_SP2MEM_EXT;
					function_sel <= LOAD_16_BIT_SP2MEM_EXT;
				end 
				16'h22dd:begin
					ofos_operation_type <= LOAD_16_BIT_IX2MEM_EXT;
					function_sel <= LOAD_16_BIT_IX2MEM_EXT;
				end 
				16'h22fd:begin
					ofos_operation_type <= LOAD_16_BIT_IY2MEM_EXT;
					function_sel <= LOAD_16_BIT_IY2MEM_EXT;
				end
				// ==================================   rotates and shift  ====================================
				16'hcbdd:begin
					case(instruction[31:30])
						2'b00:begin
							ofos_operation_type <= RS_MEM_INDEX_IX;
							function_sel <= RS_MEM_INDEX_IX;								
						end
						2'b01:begin
							ofos_operation_type <= BM_TEST_MEM_IX;
							function_sel <= BM_TEST_MEM_IX;
						end
						2'b10:begin
							ofos_operation_type <= BM_RESET_MEM_IX;
							function_sel <= BM_RESET_MEM_IX;
						end 
						2'b11:begin
							ofos_operation_type <= BM_SET_MEM_IX;
							function_sel <= BM_SET_MEM_IX;
						end
					endcase
				end
				16'hcbfd:begin
					case(instruction[31:30])
						2'b00:begin
							ofos_operation_type <= RS_MEM_INDEX_IY;
							function_sel <= RS_MEM_INDEX_IY;								
						end
						2'b01:begin
							ofos_operation_type <= BM_TEST_MEM_IY;
							function_sel <= BM_TEST_MEM_IY;								
						end
						2'b10:begin
							ofos_operation_type <= BM_RESET_MEM_IY;
							function_sel <= BM_RESET_MEM_IY;								
						end 
						2'b11:begin
							ofos_operation_type <= BM_SET_MEM_IY;
							function_sel <= BM_SET_MEM_IY;									
						end
					endcase

				end
				default:begin
					function_sel <= NO_FUNCTION;
					ofos_operation_type <= NO_FUNCTION;					
				end
			endcase
		end
		default:begin
			function_sel <= NO_FUNCTION;
			ofos_operation_type <= NO_FUNCTION;
			fsm_of_des <= 8'b0;
			fsm_of_sou <= 8'b0;
		end
	endcase