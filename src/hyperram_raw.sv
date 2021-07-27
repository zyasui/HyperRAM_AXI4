/*
 * Copyright (C) 2021 YASUI Tsukasa. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   1. Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   3. All advertising materials mentioning features or use of this software
 *      must display the following acknowledgement: This product includes
 *      software developed by YASUI Tsukasa. Neither the name of YASUI Tsukasa
 *      nor the names of its contributors may be used to endorse or promote
 *      products derived from this software without specific prior written
 *      permission.
 *
 * THIS SOFTWARE IS PROVIDED BY YASUI Tsukasa AS IS AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL YASUI Tsukasa BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

`begin_keywords "1800-2012"
`default_nettype none

module HYPERRAM_RAW #(
	parameter LATENCY = 10'd6,
	parameter FIXED_LATENCY_MODE = 1'b0
) (
	// Clock and reset
	input wire REFCLK200M,		// 200MHz IDELAYCTRL reference clock
	input wire IOCLK_0,			// Fundamental clock
	input wire IOCLK_90,		// 90deg lag clock against IOCLK_0
	input wire SCLR,			// Synchronous reset

	// Input delay (IDELAY) control
	input wire DELAY_RESET,		// Set input delay to minimum (sync'd w/IOCLK_0)
	input wire DELAY_INC,		// Increment delay tap value (sync'd w/IOCLK_0)

	// Control interface
	input wire START,
	input wire MEMORY_nREGISTER,		// 0:Register Space, 1:Memory Space
	input wire READ_nWRITE,				// 0:Write, 1:Read
	input wire BURST_LINEAR_nWRAP,		// 0:Wrap Burst, 1:Linear Burst
	input wire[28:0] ADDR_HIGH,
	input wire[2:0] ADDR_LOW,
	input wire[9:0] BURST_LEN,			// actual length = (BURST_LEN + 1) * 2 bytes, maximum burst length is limited by tCSM and CK frequency
	input wire[15:0] REGISTER_DATA_IN,	// Register data input, only used when MEMORY_nREGISTER=0 and READ_nWRITE=0 (register write)
	output logic BUSY,
	output logic DONE,

	// Write data
	input wire[7:0] WRITE_DATA_1ST,
	input wire[7:0] WRITE_DATA_2ND,
	input wire WRITE_DATA_MASK_1ST,
	input wire WRITE_DATA_MASK_2ND,
	output logic WRITE_DATA_REQ,

	// Read data
	output logic[7:0] READ_DATA_1ST,
	output logic[7:0] READ_DATA_2ND,
	output logic READ_DATA_VALID,

	// HyperRAM bus
	output logic RPC_CK,
	output logic RPC_CK_N,
	output logic RPC_CS_N,
	inout wire[7:0] RPC_DQ,
	output logic RPC_RESET_N,
	inout wire RPC_RWDS
);

	/*
	 * Command bit, timing definition
	 */
	localparam CMD_W        = 1'b0;
	localparam CMD_R        = 1'b1;
	localparam CMD_AS_MEM   = 1'b0;
	localparam CMD_AS_REG   = 1'b1;
	localparam CMD_BST_WRAP = 1'b0;
	localparam CMD_BST_LIN  = 1'b1;

	localparam tRP_CYC = 6'd34;		// 200ns / (1/166MHz) = 34



	/*
	 * IDDR / ODDR / IDELAY
	 */
	reg data_oe1, data_oe2, cke, cs, rwds_oe1, rwds_oe2;
	wire rwds_out1, rwds_out2;
	wire[7:0] data_in1, data_in2;
	wire[7:0] data_out1, data_out2;
	wire rwds_in1, rwds_in2;

	wire[7:0] iobuf_I, iobuf_O, iobuf_O2, iobuf_T;
	genvar i;
	generate
		for(i=0; i<=7; i=i+1) begin: Generate_ODDR2_DATA
			ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) oddr_data(
				.C(IOCLK_0), .CE(1'b1), .R(1'b0), .S(1'b0),
				.D1(data_out1[i]), .D2(data_out2[i]), .Q(iobuf_I[i]));
		end
	endgenerate

	generate
		for(i=0; i<=7; i=i+1) begin: Generate_ODDR2_DATA_OE
			ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) oddr_data_oe(
				.C(IOCLK_0), .CE(1'b1), .R(1'b0), .S(1'b0/*SCLR*/),
				.D1(~data_oe1), .D2(~data_oe1), .Q(iobuf_T[i]));
		end
	endgenerate

	generate
		for(i=0; i<=7; i=i+1) begin: Generate_IDDR2_DATA
			IDDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) iddr_data(
				.C(IOCLK_0), .CE(1'b1), .R(1'b0), .S(1'b0),
				.D(iobuf_O2[i]), .Q1(data_in1[i]), .Q2(data_in2[i]));
		end
	endgenerate

	generate
		for(i=0; i<=7; i=i+1) begin: Generate_IDELAYE2_DATA
			IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"), .IDELAY_VALUE(0)) idly_data(
				.IDATAIN(iobuf_O[i]), .DATAOUT(iobuf_O2[i]),
				.C(IOCLK_0), .CE(DELAY_INC), .REGRST('0), .LD(DELAY_RESET), .INC(1'b1), .CNTVALUEIN('0), .CINVCTRL('0), .LDPIPEEN('0));
		end
	endgenerate

	generate
		for(i=0; i<=7; i=i+1) begin: Generate_IOBUF_DATA
			IOBUF #(.DRIVE(6), .SLEW("SLOW"), .IOSTANDARD("LVCMOS18")) iobuf_data(
				.I(iobuf_I[i]), .O(iobuf_O[i]), .T(iobuf_T[i]), .IO(RPC_DQ[i]));
		end
	endgenerate

	ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) oddr_ck_p(
		.C(IOCLK_90), .CE(1'b1), .R(1'b0), .S(1'b0),
		.D1(cke), .D2(1'b0), .Q(RPC_CK));
	ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) oddr_ck_n(
		.C(IOCLK_90), .CE(1'b1), .R(1'b0), .S(1'b0),
		.D1(~cke), .D2(1'b1), .Q(RPC_CK_N));

	ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) oddr_cs_n(
		.C(IOCLK_0), .CE(1'b1), .R(1'b0), .S(SCLR),
		.D1(~cs), .D2(~cs), .Q(RPC_CS_N));

	wire iobuf_rwds_I, iobuf_rwds_O, iobuf_rwds_T;
	wire iobuf_rwds_O2;

	ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) oddr_rwds(
		.C(IOCLK_0), .CE(1'b1), .R(1'b0), .S(1'b0),
		.D1(rwds_out1), .D2(rwds_out2), .Q(iobuf_rwds_I));
	ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) oddr_rwds_oe(
		.C(IOCLK_0), .CE(1'b1), .R(1'b0), .S(1'b0/*SCLR*/),
		.D1(~rwds_oe1), .D2(~rwds_oe2), .Q(iobuf_rwds_T));
	IDDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) iddr_rwds(
		.C(IOCLK_0), .CE(1'b1), .R(1'b0), .S(1'b0),
		.D(iobuf_rwds_O2), .Q1(rwds_in1), .Q2(rwds_in2));
	IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"), .IDELAY_VALUE(0)) idly_rwds(
		.IDATAIN(iobuf_rwds_O), .DATAOUT(iobuf_rwds_O2),
		.C(IOCLK_0), .CE(DELAY_INC), .REGRST('0), .LD(DELAY_RESET), .INC(1'b1), .CNTVALUEIN('0), .CINVCTRL('0), .LDPIPEEN('0));
	IOBUF #(.DRIVE(6), .SLEW("SLOW"), .IOSTANDARD("LVCMOS18")) iobuf_rwds(
		.I(iobuf_rwds_I), .O(iobuf_rwds_O), .T(iobuf_rwds_T), .IO(RPC_RWDS));

	IDELAYCTRL idlyctl0(.RST(SCLR), .REFCLK(REFCLK200M));



	/*
	 * Reset signal extension
	 */
	reg[5:0] reset_count;

	always_ff @(posedge IOCLK_0) begin
		if(SCLR) begin
			RPC_RESET_N = 1'b0;
			reset_count <= 'd0;
		end else if(reset_count != (tRP_CYC - 'd1))
			reset_count <= reset_count + 'd1;
		else
			RPC_RESET_N = 1'b1;
	end



	/*
	 * State machine
	 */
	typedef enum { HRAM_IDLE, HRAM_HOLD_CS, HRAM_CMD, HRAM_WAIT_LATENCY, HRAM_READ_WRITE, HRAM_DONE } STATE_HRAM_T;
	STATE_HRAM_T state_hram;
	reg[47:0] cmd;
	reg[9:0] count, latched_burst_len;
	reg latched_read_nwrite, latched_memory_nregister;
	reg[15:0] latched_register_data_in;

	always_ff @(posedge IOCLK_0) begin
		if(SCLR) begin
			WRITE_DATA_REQ <= 1'b0;
			data_oe1 <= 1'b0;
			data_oe2 <= 1'b0;
			rwds_oe1 <= 1'b0;
			rwds_oe2 <= 1'b0;
			cke <= 1'b0;
			cs <= 1'b0;
			state_hram <= HRAM_IDLE;
		end else case(state_hram)
		HRAM_IDLE:
			if(START && !(READ_nWRITE && !MEMORY_nREGISTER)) begin	// Register read is not supported (will be ignored)
				cs <= 1'b1;
				cmd <= {
					READ_nWRITE ? CMD_R : CMD_W, MEMORY_nREGISTER ? CMD_AS_MEM : CMD_AS_REG,
					BURST_LINEAR_nWRAP ? CMD_BST_LIN : CMD_BST_WRAP, ADDR_HIGH, 13'h0000, ADDR_LOW };
				latched_read_nwrite <= READ_nWRITE;
				latched_memory_nregister <= MEMORY_nREGISTER;
				latched_register_data_in <= REGISTER_DATA_IN;
				latched_burst_len <= BURST_LEN;
				count <= 'd1;
				state_hram <= HRAM_HOLD_CS;
			end

		HRAM_HOLD_CS: begin
			data_oe1 <= 1'b1;
			data_oe2 <= 1'b1;
			if(count == 'd0) begin
				cmd <= { cmd[32:0], 16'hxxxx };
				cke <= 1'b1;
				count <= 'd2;
				state_hram <= HRAM_CMD;
			end else
				count <= count - 'd1;
		end

		HRAM_CMD: begin
			if(count == 'd1)
				cmd <= { latched_register_data_in, 32'hxxxxxxxx };	// Load
			else
				cmd <= { cmd[32:0], 16'hxxxx };	// Shift

			if(count == 'd0) begin
				count <=
					FIXED_LATENCY_MODE ? ( { LATENCY, 1'b0 } - 'd3 ) :
					                     ( rwds_in1 ? ({ LATENCY, 1'b0 } - 'd3) : (LATENCY - 'd3) );
				if(!latched_read_nwrite && latched_memory_nregister) begin
					// Memory space write
					rwds_oe1 <= 1'b1;
					rwds_oe2 <= 1'b1;
					state_hram <= HRAM_WAIT_LATENCY;
				end else if(latched_read_nwrite && latched_memory_nregister) begin
					// Memory space read
					data_oe1 <= 1'b0;
					data_oe2 <= 1'b0;
					state_hram <= HRAM_WAIT_LATENCY;
				end else begin
					// Register space write
					cs <= 1'b0;
					data_oe1 <= 1'b0;
					data_oe2 <= 1'b0;
					state_hram <= HRAM_DONE;
				end
			end else
				count <= count - 'd1;
		end

		HRAM_WAIT_LATENCY: begin
			if(count == 'd0) begin
				count <= latched_burst_len;
				if(latched_read_nwrite) begin
					// Memory space read
					state_hram <= HRAM_READ_WRITE;
				end else begin
					// Memory space write
					WRITE_DATA_REQ <= 1'b1;
					data_oe1 <= 1'b1;
					data_oe2 <= 1'b1;
					state_hram <= HRAM_READ_WRITE;
				end
			end else
				count <= count - 'd1;
		end

		HRAM_READ_WRITE: begin
			if(count == 'd0) begin
				data_oe1 <= 1'b0;
				data_oe2 <= 1'b0;
				rwds_oe1 <= 1'b0;
				rwds_oe2 <= 1'b0;
				WRITE_DATA_REQ <= 1'b0;
				state_hram <= HRAM_DONE;
			end else
				count <= count - 'd1;
		end

		HRAM_DONE: begin
			data_oe1 <= 1'b0;
			data_oe2 <= 1'b0;
			rwds_oe1 <= 1'b0;
			rwds_oe2 <= 1'b0;
			cke <= 1'b0;
			cs <= 1'b0;
			state_hram <= HRAM_IDLE;
		end
		endcase
	end

	assign data_out1 = WRITE_DATA_REQ ? WRITE_DATA_1ST : cmd[47:40];
	assign data_out2 = WRITE_DATA_REQ ? WRITE_DATA_2ND : cmd[39:32];
	assign rwds_out1 = WRITE_DATA_MASK_1ST;
	assign rwds_out2 = WRITE_DATA_MASK_2ND;

	assign BUSY = (SCLR || !RPC_RESET_N || (state_hram != HRAM_IDLE)) ? 1'b1 : 1'b0;
	assign DONE = (state_hram == HRAM_DONE) ? 1'b1 : 1'b0;



	/*
	 * Data receive state machine
	 *
	 * TODO:
	 *   This state machine does not support additional latency requests where the device temporarily stops RSDS
	 *   transitions. This limitation should be no problem for the S27KL0641 device, but that may cause a problem
	 *   in other devices.
	 */
	reg[9:0] read_count;
	reg[7:0] read_data_tmp;
	reg[2:0] timeout_count;
	typedef enum { RECEIVER_IDLE, RECEIVER_WAIT_RWDS, RECEIVER_RECEIVING_EVEN, RECEIVER_RECEIVING_ODD } STATE_RECEIVER_T;
	STATE_RECEIVER_T state_receiver;

	always_ff @(posedge IOCLK_0) begin
		if(SCLR) begin
			READ_DATA_VALID <= 1'b0;
			state_receiver <= RECEIVER_IDLE;
		end else case(state_receiver)
		RECEIVER_IDLE: begin
			READ_DATA_VALID <= 1'b0;
			if((state_hram == HRAM_READ_WRITE) && latched_read_nwrite) begin
				read_count <= latched_burst_len;
				timeout_count <= 'd7;
				state_receiver <= RECEIVER_WAIT_RWDS;
			end
		end

		RECEIVER_WAIT_RWDS:
			if(rwds_in2) begin
				// Even data order
				READ_DATA_1ST <= data_in2;
				READ_DATA_2ND <= data_in1;
				read_count <= read_count - 'd1;
				READ_DATA_VALID <= 1'b1;
				timeout_count <= 'd7;
				if(read_count == 'd0)
					state_receiver <= RECEIVER_IDLE;
				else
					state_receiver <= RECEIVER_RECEIVING_EVEN;
			end else if(rwds_in1) begin
				// Odd data order
				read_data_tmp <= data_in1;
				timeout_count <= 'd7;
				state_receiver <= RECEIVER_RECEIVING_ODD;
			end else begin
				if(timeout_count == 'd0)
					state_receiver <= RECEIVER_IDLE;	// Something wrong!!
				timeout_count <= timeout_count - 'd1;
			end

		RECEIVER_RECEIVING_EVEN: begin
			// Even data order
//			if(rwds_in1 || rwds_in2) begin
				timeout_count <= 'd7;
				READ_DATA_1ST <= data_in2;
				READ_DATA_2ND <= data_in1;
				read_count <= read_count - 'd1;
				if(read_count == 'd0)
					state_receiver <= RECEIVER_IDLE;
//			end else begin
//				// The device can request additional latency by stopping RSDS transitions. In this case, both rwds_in{1|2} go low state. 
//				if(timeout_count == 'd0)
//					state_receiver <= RECEIVER_IDLE;	// Something wrong!!
//				timeout_count <= timeout_count - 'd1;
//			end
		end

		RECEIVER_RECEIVING_ODD: begin
			// Odd data order
//			if(rwds_in1 || rwds_in2) begin
				timeout_count <= 'd7;
				READ_DATA_VALID <= 1'b1;
				READ_DATA_1ST <= read_data_tmp;
				READ_DATA_2ND <= data_in2;
				read_data_tmp <= data_in1;
				read_count <= read_count - 'd1;
				if(read_count == 'd0)
					state_receiver <= RECEIVER_IDLE;
//			end else begin
//				// The device can request additional latency by stopping RSDS transitions. In this case, both rwds_in{1|2} go low state. 
//				if(timeout_count == 'd0)
//					state_receiver <= RECEIVER_IDLE;	// Something wrong!!
//				timeout_count <= timeout_count - 'd1;
//			end
		end
		endcase
	end



`ifdef NEVER
	ila_0 ila0(
		.clk(IOCLK_0),
		.probe0(BUSY),
		.probe1(START),
		.probe2(MEMORY_nREGISTER),
		.probe3(READ_nWRITE),
		.probe4(DONE),
		.probe5(data_oe1),
		.probe6(data_oe2),
		.probe7(cke),
		.probe8(cs),
		.probe9(rwds_oe1),
		.probe10(rwds_oe2),
		.probe11(rwds_out1),
		.probe12(rwds_out2),
		.probe13(rwds_in1),
		.probe14(rwds_in2),
		.probe15(data_in1),
		.probe16(data_in2),
		.probe17(data_out1),
		.probe18(data_out2),
		.probe19(state_receiver),
		.probe20(WRITE_DATA_REQ),
		.probe21(count),
		.probe22(state_hram),
		.probe23(READ_DATA_VALID),
		.probe24(READ_DATA_1ST),
		.probe25(READ_DATA_2ND),
		.probe26(REGISTER_DATA_IN),
		.probe27(BURST_LINEAR_nWRAP),
		.probe28(BURST_LEN)
	);
`endif

endmodule

`default_nettype wire
`end_keywords
