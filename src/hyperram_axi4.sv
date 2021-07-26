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

module HYPERRAM_AXI4 #(
	parameter POWERUP_WAIT_COUNT = 24999,	// decide this value to ensure the power-up wait time (tVCS, unit:1/IOCLK_0)
//	parameter SAME_CLOCK_MODE = 0,			// enable this mode if IOCLK_0 == AXI_ACLK (Not implemented yet, this mode will make it possible to remove all the FIFOs in this IP.)
	parameter LATENCY = 6,
	parameter FIXED_LATENCY_MODE = 0,
	parameter WRAP_BURST_LEN = 16,			// WRAP_BURST_LEN must be same to your system's cache line length in bytes. 16, 32, 64, 128 bytes are supported.
	parameter AWID_WIDTH = 2,
	parameter ARID_WIDTH = 2
) (
	// Clock and reset
	input wire REFCLK200M,		// 200MHz IDELAYCTRL reference clock
	input wire IOCLK_0,			// Fundamental clock
	input wire IOCLK_90,		// 90deg rag clock against IOCLK_0
	input wire AXI_ACLK,
	input wire AXI_ARESETN,		// Synchronous reset ()

	// AXI4 Slave (Memory Space)
	input wire[AWID_WIDTH-1:0] Sm_AXI_AWID,
	input wire[31:0] Sm_AXI_AWADDR,
	input wire[7:0] Sm_AXI_AWLEN,
	input wire[2:0] Sm_AXI_AWSIZE,
	input wire[1:0] Sm_AXI_AWBURST,
//	input wire[0:0] Sm_AXI_AWLOCK,		// Optional
//	input wire[3:0] Sm_AXI_AWCACHE,		// Optional
//	input wire[2:0] Sm_AXI_AWPROTO,		// Optional
//	input wire[3:0] Sm_AXI_AWQOS,		// Optional
//	input wire[3:0] Sm_AXI_AWREGION,	// Optional
//	input wire[] Sm_AXI_AWUSER,			// Optional
	input wire Sm_AXI_AWVALID,
	output logic Sm_AXI_AWREADY,

	input wire[31:0] Sm_AXI_WDATA,
	input wire[3:0] Sm_AXI_WSTRB,
//	input wire Sm_AXI_WLAST,			// Optional
//	input wire[] Sm_AXI_WUSER,			// Optional
	input wire Sm_AXI_WVALID,
	output logic Sm_AXI_WREADY,

	output logic[AWID_WIDTH-1:0] Sm_AXI_BID,
	output logic[1:0] Sm_AXI_BRESP,		// Optional
//	output logic[] Sm_AXI_BUSER,		// Optional
	output logic Sm_AXI_BVALID,
	input wire Sm_AXI_BREADY,

	input wire[ARID_WIDTH-1:0] Sm_AXI_ARID,
	input wire[31:0] Sm_AXI_ARADDR,
	input wire[7:0] Sm_AXI_ARLEN,
	input wire[2:0] Sm_AXI_ARSIZE,
	input wire[1:0] Sm_AXI_ARBURST,
//	input wire[0:0] Sm_AXI_ARLOCK,		// Optional
//	input wire[3:0] Sm_AXI_ARCACHE,		// Optional
//	input wire[2:0] Sm_AXI_ARPROT,		// Optional
//	input wire[3:0] Sm_AXI_ARQOS,		// Optional
//	input wire[3:0] Sm_AXI_ARREGION,	// Optional
//	input wire[] Sm_AXI_ARUSER,			// Optional
	input wire Sm_AXI_ARVALID,
	output logic Sm_AXI_ARREADY,

	output logic[ARID_WIDTH-1:0] Sm_AXI_RID,
	output logic[31:0] Sm_AXI_RDATA,
	output logic[1:0] Sm_AXI_RRESP,		// Optional
	output logic Sm_AXI_RLAST,
//	output logic[] Sm_AXI_RUSER,		// Optional
	output logic Sm_AXI_RVALID,
	input wire Sm_AXI_RREADY,

	// AXI4-Lite Slave (Register Space)
	input wire[31:0] Sr_AXI_AWADDR,
//	input wire[2:0] Sr_AXI_AWPROTO,		// Optional
	input wire Sr_AXI_AWVALID,
	output logic Sr_AXI_AWREADY,

	input wire[31:0] Sr_AXI_WDATA,
	input wire[3:0] Sr_AXI_WSTRB,
	input wire Sr_AXI_WVALID,
	output logic Sr_AXI_WREADY,

//	output logic[1:0] Sr_AXI_BRESP,		// Optional
	output logic Sr_AXI_BVALID,
	input wire Sr_AXI_BREADY,

	input wire[31:0] Sr_AXI_ARADDR,
//	input wire[2:0] Sr_AXI_ARPROT,		// Optional
	input wire Sr_AXI_ARVALID,
	output logic Sr_AXI_ARREADY,

	output logic[31:0] Sr_AXI_RDATA,
//	output logic[1:0] Sr_AXI_RRESP,		// Optional
	output logic Sr_AXI_RVALID,
	input wire Sr_AXI_RREADY,

	// HyperRAM bus
	output logic RPC_CK,
	output logic RPC_CK_N,
	output logic RPC_CS_N,
	inout wire[7:0] RPC_DQ,
	output logic RPC_RESET_N,
	inout wire RPC_RWDS
);

	/*
	 * AXI4 definition
	 */
	localparam AxSIZE_32BIT = 3'b010;

	localparam AxBURST_INCR = 2'b01;
	localparam AxBURST_WRAP = 2'b10;

	localparam ABRESP_OK     = 2'b00;
	localparam ABRESP_SLVERR = 2'b10;



	/*
	 * IOCLK_0 domain reset
	 */
	reg[15:0] synced_axi_aresetn;
	wire SCLR;

	always @(negedge AXI_ARESETN or posedge IOCLK_0) begin
		if(!AXI_ARESETN)
			synced_axi_aresetn <= '0;
		else
			synced_axi_aresetn <= { synced_axi_aresetn[14:0], 1'b1 };
	end

	assign SCLR = ~synced_axi_aresetn[15];



	/*
	 * AXI4 write channel
	 */
	wire fifo0_wr_en, fifo0_rd_en, fifo0_empty, fifo0_wr_rst_busy;
	wire[41:0] fifo0_dout;
	wire awerror;
	reg write_channel_pending;
	reg[AWID_WIDTH-1:0] awid;

	FIFO_READ_WRITE_ADDR fifo0(
		.rst(~AXI_ARESETN),
		.wr_clk(AXI_ACLK), .din({ Sm_AXI_AWBURST, Sm_AXI_AWADDR, Sm_AXI_AWLEN }), .wr_en(fifo0_wr_en), .wr_rst_busy(fifo0_wr_rst_busy),
		.rd_clk(IOCLK_0), .dout(fifo0_dout), .rd_en(fifo0_rd_en), .empty(fifo0_empty) );

	assign Sm_AXI_AWREADY = (fifo0_wr_rst_busy || write_channel_pending) ? 1'b0 : 1'b1;
	assign awerror = ( Sm_AXI_AWVALID && ((Sm_AXI_AWSIZE != AxSIZE_32BIT) || ((Sm_AXI_AWLEN != 8'd00) && (Sm_AXI_AWBURST != AxBURST_INCR) && (Sm_AXI_AWBURST != AxBURST_WRAP))) ) ? 1'b1 : 1'b0;	// Only 32-bit, INCR or WRAP burst access is supported
	assign fifo0_wr_en = (Sm_AXI_AWVALID && Sm_AXI_AWREADY && !awerror) ? 1'b1 : 1'b0;

	always_ff @(posedge AXI_ACLK)
		if(Sm_AXI_AWVALID && Sm_AXI_AWREADY)
			awid <= Sm_AXI_AWID;

	wire fifo1_wr_en, fifo1_rd_en, fifo1_empty, fifo1_full, fifo1_wr_rst_busy;
	wire[9:0] fifo1_rd_data_count;
	wire[17:0] fifo1_dout;

	FIFO_WRITE_DATA fifo1(
		.rst(~AXI_ARESETN),
		.wr_clk(AXI_ACLK), .din({ Sm_AXI_WSTRB[1:0], Sm_AXI_WDATA[15:0], Sm_AXI_WSTRB[3:2], Sm_AXI_WDATA[31:16] }), .wr_en(fifo1_wr_en), .full(fifo1_full), .wr_rst_busy(fifo1_wr_rst_busy),
		.rd_clk(IOCLK_0), .dout(fifo1_dout), .rd_en(fifo1_rd_en), .empty(fifo1_empty), .rd_data_count(fifo1_rd_data_count) );

	assign Sm_AXI_WREADY = (fifo1_wr_rst_busy || fifo1_full) ? 1'b0 : 1'b1;
	assign fifo1_wr_en = (Sm_AXI_WVALID && Sm_AXI_WREADY) ? 1'b1 : 1'b0;

	/* Return a response to the master */
	wire fifo2_wr_en, fifo2_rd_en, fifo2_empty;
	wire[1:0] fifo2_din, fifo2_dout;

	FIFO_WRITE_RESP fifo2(
		.rst(~AXI_ARESETN),
		.rd_clk(AXI_ACLK), .dout(fifo2_dout), .rd_en(fifo2_rd_en), .empty(fifo2_empty),
		.wr_clk(IOCLK_0), .din(fifo2_din), .wr_en(fifo2_wr_en) );

	assign Sm_AXI_BID = awid;
	assign Sm_AXI_BRESP = fifo2_dout;
	assign Sm_AXI_BVALID = ~fifo2_empty;
	assign fifo2_rd_en = (Sm_AXI_BVALID && Sm_AXI_BREADY) ? 1'b1 : 1'b0;

	always_ff @(posedge AXI_ACLK) begin
		if(!AXI_ARESETN)
			write_channel_pending <= 1'b0;
		else if(Sm_AXI_AWREADY && Sm_AXI_AWVALID)
			write_channel_pending <= 1'b1;
		else if(write_channel_pending && !fifo2_empty)
			write_channel_pending <= 1'b0;
	end



	/*
	 * AXI4 read channel
	 */
	wire fifo3_wr_en, fifo3_rd_en, fifo3_empty, fifo3_wr_rst_busy;
	wire[41:0] fifo3_dout;
	wire arerror;
	reg read_channel_pending;
	reg[ARID_WIDTH-1:0] arid;
	reg[7:0] read_len_count;

	FIFO_READ_WRITE_ADDR fifo3(
		.rst(~AXI_ARESETN),
		.wr_clk(AXI_ACLK), .din({ Sm_AXI_ARBURST, Sm_AXI_ARADDR, Sm_AXI_ARLEN }), .wr_en(fifo3_wr_en), .wr_rst_busy(fifo3_wr_rst_busy),
		.rd_clk(IOCLK_0), .dout(fifo3_dout), .rd_en(fifo3_rd_en), .empty(fifo3_empty) );

	assign Sm_AXI_ARREADY = (fifo3_wr_rst_busy || read_channel_pending) ? 1'b0 : 1'b1;
	assign arerror = ( Sm_AXI_ARVALID && ((Sm_AXI_ARSIZE != AxSIZE_32BIT) || ((Sm_AXI_ARLEN != 8'd00) && (Sm_AXI_ARBURST != AxBURST_INCR) && (Sm_AXI_ARBURST != AxBURST_WRAP))) ) ? 1'b1 : 1'b0;	// Only 32-bit, INCR access is supported
	assign fifo3_wr_en = (Sm_AXI_ARVALID && Sm_AXI_ARREADY && !arerror) ? 1'b1 : 1'b0;

	always_ff @(posedge AXI_ACLK)
		if(Sm_AXI_ARVALID && Sm_AXI_ARREADY)
			arid <= Sm_AXI_ARID;

	wire fifo4_wr_en, fifo4_rd_en, fifo4_empty;
	wire[15:0] fifo4_din;

	FIFO_READ_DATA fifo4(
		.rst(~AXI_ARESETN),
		.rd_clk(AXI_ACLK), .dout({ Sm_AXI_RDATA[15:0], Sm_AXI_RDATA[31:16] }), .rd_en(fifo4_rd_en), .empty(fifo4_empty),
		.wr_clk(IOCLK_0), .din(fifo4_din), .wr_en(fifo4_wr_en) );

	assign Sm_AXI_RID = arid;
	assign Sm_AXI_RRESP = ABRESP_OK;
	assign Sm_AXI_RVALID = ~fifo4_empty;
	assign fifo4_rd_en = (Sm_AXI_RVALID && Sm_AXI_RREADY) ? 1'b1 : 1'b0;

	always_ff @(posedge AXI_ACLK) begin
		if(!AXI_ARESETN)
			read_channel_pending <= 1'b0;
		else if(Sm_AXI_ARREADY && Sm_AXI_ARVALID) begin
			read_channel_pending <= 1'b1;
			read_len_count <= Sm_AXI_ARLEN;
		end if(read_channel_pending && fifo4_rd_en) begin
			if(read_len_count == 'd0)
				read_channel_pending <= 1'b0;
			read_len_count <= read_len_count - 'd1;
		end
	end

	assign Sm_AXI_RLAST = (read_len_count == 'd0) ? 1'b1 : 1'b0;



	/*
	 * HyperRAM control state machine
	 */
	typedef enum { HRAM_WAIT_POWERUP, HRAM_WRITE_CR0, HRAM_WAIT_CR0, HRAM_IDLE, HRAM_WAIT_WRITE_DATA, HRAM_WRITE, HRAM_WAIT_COMPLETE } STATE_HRAM_T;
	STATE_HRAM_T state_hram;
	reg[14:0] powerup_timer;
	reg[8:0] burst_len, write_count;
	reg[31:0] addr;
	reg[1:0] burst_type;
	wire write_data_ready;
	reg read_start;

	wire hram0_busy;

	always @(posedge IOCLK_0) begin
		if(SCLR) begin
			powerup_timer <= POWERUP_WAIT_COUNT;
			read_start <= 1'b0;
			state_hram <= HRAM_WAIT_POWERUP;
		end else case(state_hram)
		HRAM_WAIT_POWERUP:
			if(powerup_timer == 'd0)
				state_hram <= HRAM_WRITE_CR0;
			else
				powerup_timer <= powerup_timer - 'd1;

		HRAM_WRITE_CR0:
			state_hram <= HRAM_WAIT_CR0;

		HRAM_WAIT_CR0:
			if(!hram0_busy)
				state_hram <= HRAM_IDLE;

		HRAM_IDLE:
			if(~fifo0_empty) begin
				// Wait for write data, then we'll start a write transaction
				burst_len  <= { fifo0_dout[7:0], 1'b1 };
				addr       <= fifo0_dout[39:8];
				burst_type <= fifo0_dout[41:40];
				state_hram <= HRAM_WAIT_WRITE_DATA;
			end else if(~fifo3_empty) begin
				// Start a read transaction immediately
				burst_len  <= { fifo3_dout[7:0], 1'b1 };
				addr       <= fifo3_dout[39:8];
				burst_type <= fifo3_dout[41:40];
				read_start <= 1'b1;
				state_hram <= HRAM_WAIT_COMPLETE;
			end

		HRAM_WAIT_WRITE_DATA:
			if(write_data_ready) begin
				write_count <= burst_len;
				state_hram <= HRAM_WAIT_COMPLETE;
			end

		HRAM_WAIT_COMPLETE: begin
			read_start <= 1'b0;
			if(!hram0_busy)
				state_hram <= HRAM_IDLE;
		end
		endcase
	end

	assign write_data_ready = (fifo1_rd_data_count == ({ 1'b0, burst_len } + 'd1)) ? 1'b1 : 1'b0;

	assign fifo0_rd_en = ((state_hram == HRAM_IDLE) && ~fifo0_empty) ? 1'b1 : 1'b0;
	assign fifo3_rd_en = read_start ? 1'b1 : 1'b0;

	assign fifo2_wr_en = ((state_hram == HRAM_WAIT_WRITE_DATA) && write_data_ready) ? 1'b1 : 1'b0;
	assign fifo2_din = ABRESP_OK;



	/*
	 * HyperRAM low-level layer instance
	 */
	wire hram0_start, hram0_memory_nregister, hram0_read_nwrite, hram0_burst_linear_nwrap;
	wire[28:0] hram0_addr_high;
	wire[2:0] hram0_addr_low;
	wire[9:0] hram0_burst_len;
	wire[15:0] hram0_register_data_in;
	wire hram0_delay_reset, hram0_delay_inc;

	HYPERRAM_RAW #(
		.LATENCY(LATENCY), .FIXED_LATENCY_MODE(FIXED_LATENCY_MODE)
	) hram0(
		.REFCLK200M(REFCLK200M), .IOCLK_0(IOCLK_0), .IOCLK_90(IOCLK_90), .SCLR(SCLR),

		.DELAY_RESET(hram0_delay_reset), .DELAY_INC(hram0_delay_inc),

		.MEMORY_nREGISTER(hram0_memory_nregister), .READ_nWRITE(hram0_read_nwrite),	.BURST_LINEAR_nWRAP(hram0_burst_linear_nwrap),
		.ADDR_HIGH(hram0_addr_high), .ADDR_LOW(hram0_addr_low), .BURST_LEN(hram0_burst_len),
		.REGISTER_DATA_IN(hram0_register_data_in),
		.START(hram0_start), .BUSY(hram0_busy), .DONE(),

		.WRITE_DATA_1ST(fifo1_dout[7:0]), .WRITE_DATA_2ND(fifo1_dout[15:8]),			// Little Endian
		.WRITE_DATA_MASK_1ST(~fifo1_dout[16]), .WRITE_DATA_MASK_2ND(~fifo1_dout[17]),	// Little Endian
		.WRITE_DATA_REQ(fifo1_rd_en),

		.READ_DATA_1ST(fifo4_din[7:0]), .READ_DATA_2ND(fifo4_din[15:8]),				// Little Endian
		.READ_DATA_VALID(fifo4_wr_en),

		.RPC_CK(RPC_CK), .RPC_CK_N(RPC_CK_N), .RPC_CS_N(RPC_CS_N),
		.RPC_DQ(RPC_DQ), .RPC_RESET_N(RPC_RESET_N), .RPC_RWDS(RPC_RWDS)
	);

	assign hram0_memory_nregister = (state_hram == HRAM_WRITE_CR0) ? 1'b0 : 1'b1;
	assign hram0_read_nwrite = ((state_hram == HRAM_WRITE_CR0) || (state_hram == HRAM_WAIT_WRITE_DATA)) ? 1'b0 : 1'b1;
	assign hram0_burst_linear_nwrap = (burst_type == AxBURST_INCR) ? 1'b1 : 1'b0;
	assign hram0_addr_high =
		(state_hram == HRAM_WRITE_CR0) ? 29'h00000100 :	// CR0
		                                 { 10'h000, addr[22:4] };
	assign hram0_addr_low  =
		(state_hram == HRAM_WRITE_CR0) ? 3'b000 :		// CR0
		                                 { addr[3:2], 1'b0 };
	assign hram0_burst_len = { 1'b0, burst_len };
	assign hram0_register_data_in = 16'h8f04 |
		((LATENCY == 3) ? 16'h00e0 : (LATENCY == 4) ? 16'h00f0 : (LATENCY == 5) ? 16'h0000 : 16'h0010) |
		(FIXED_LATENCY_MODE ? 16'h0008 : 16'h0000) |
		((WRAP_BURST_LEN == 16) ? 16'h0002 : (WRAP_BURST_LEN == 32) ? 16'h0003 : (WRAP_BURST_LEN == 64) ? 16'h0001 : 16'h0000);
	assign hram0_start = (
		(state_hram == HRAM_WRITE_CR0) ||
		((state_hram == HRAM_WAIT_WRITE_DATA) && write_data_ready) ||
		read_start ) ? 1'b1 : 1'b0;



	/*
	 * AXI4-Lite Register access (At this point, this IP has only one register, and read access is not supported.)
	 */
	/* Write Channel */
	reg axi_delay_reset, axi_delay_inc;

	assign Sr_AXI_AWREADY = 1'b1;
	assign Sr_AXI_WREADY  = 1'b1;

	always @(posedge AXI_ACLK) begin
		if(!AXI_ARESETN) begin
			axi_delay_reset <= 1'b0;
			axi_delay_inc   <= 1'b0;
		end else if(Sr_AXI_WVALID && Sr_AXI_WSTRB[0]) begin
			if(Sr_AXI_WDATA[1])
				axi_delay_reset <= ~axi_delay_reset;	// toggle
			if(Sr_AXI_WDATA[0])
				axi_delay_inc   <= ~axi_delay_inc;		// toggle
		end
	end

	always @(posedge AXI_ACLK) begin
		if(!AXI_ARESETN)
			Sr_AXI_BVALID = 1'b0;
		else if(Sr_AXI_AWVALID)
			Sr_AXI_BVALID = 1'b1;
		else if(Sr_AXI_BVALID && Sr_AXI_BREADY)
			Sr_AXI_BVALID = 1'b0;
	end

	/* Read Channel */
	assign Sr_AXI_ARREADY = 1'b1;
	assign Sr_AXI_RDATA   = 32'hxxxxxxxx;

	always @(posedge AXI_ACLK) begin
		if(!AXI_ARESETN)
			Sr_AXI_RVALID = 1'b0;
		else if(Sr_AXI_ARVALID)
			Sr_AXI_RVALID = 1'b1;
		else if(Sr_AXI_RVALID && Sr_AXI_RREADY)
			Sr_AXI_RVALID = 1'b0;
	end

	/* Delay tap control (AXI_ACLK --> IOCLK_0 clock domain translation) */
	reg[2:0] ioclk_delay_reset, ioclk_delay_inc;

	always @(posedge IOCLK_0) begin
		if(SCLR) begin
			ioclk_delay_reset <= '0;
			ioclk_delay_inc   <= '0;
		end else begin
			ioclk_delay_reset <= { ioclk_delay_reset[1:0], axi_delay_reset };
			ioclk_delay_inc   <= { ioclk_delay_inc[1:0],   axi_delay_inc   };
		end
	end

	assign hram0_delay_reset = (SCLR || (ioclk_delay_reset[2] != ioclk_delay_reset[1])) ? 1'b1 : 1'b0;
	assign hram0_delay_inc   =          (ioclk_delay_inc[2]   != ioclk_delay_inc[1]  )  ? 1'b1 : 1'b0;;

endmodule

`default_nettype wire
`end_keywords
