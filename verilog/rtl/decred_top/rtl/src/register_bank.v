`timescale 1ns / 1ps
`include "decred_defines.v"

module regBank #(
  parameter DATA_WIDTH=8,
  parameter ADDR_WIDTH=8,
  parameter NUM_OF_MACROS=2
)(
  input  wire                  iCLK,
  input  wire                  RST,
  input  wire						       MAIN_CLOCK,
  input  wire [ADDR_WIDTH-1:0] address,
  input  wire [DATA_WIDTH-1:0] data_in,
  input  wire                  read_strobe,
  input  wire                  write_strobe,
  output reg [DATA_WIDTH-1:0]  data_out,

  output wire						       hash_clock_reset,
  output wire                  LED_out,
  output wire	[6:0]				     spi_addr,
  output wire						       ID_out,
  output wire                  interrupt_out
  );

  localparam REGISTERS = 6;

  // //////////////////////////////////////////////////////
  // reg array
  // reg [DATA_WIDTH-1:0] registers [2**ADDR_WIDTH-1:0];
  reg [DATA_WIDTH-1:0] registers [REGISTERS-1:0];

  wire	[7 :0]	macro_data_writeout;
  wire	[7 :0]	macro_data_readback;

  wire	[3 :0] threadCount [NUM_OF_MACROS-1:0];

  reg [31:0] perf_counter;
  always @(posedge MAIN_CLOCK)
    if (registers[3][2] == 1'b1) 
	    perf_counter <= perf_counter + 1'b1;

  always @(posedge iCLK) begin : REG_WRITE_BLOCK
    integer i;
    if(RST) begin 
      for (i = 0; i < REGISTERS; i = i + 1) begin
        registers[i] <= 0;
      end
    end
    else begin
      if (write_strobe) begin
        registers[address] <= data_in;
      end
    end
  end

  always @(posedge iCLK) begin
    if (read_strobe) begin
		if (address[7:0] == 8'h02) begin
			// interrupt active register
			data_out <= macro_rs[1];
		end else
		  if (address[7:0] == 8'h05) begin
			// ID register
			data_out <= 8'h11;
		end else
		  if (address[7:0] == 8'h06) begin
			// MACRO_INFO register
			data_out <= ((NUM_OF_MACROS << 4) | (threadCount[0]));
		end else
		  if (address[7:0] == 8'h07) begin
			data_out <= perf_counter[7:0];
		end else
		  if (address[7:0] == 8'h08) begin
			data_out <= perf_counter[15:8];
		end else
		  if (address[7:0] == 8'h09) begin
			data_out <= perf_counter[23:16];
		end else
		  if (address[7:0] == 8'h0A) begin
			data_out <= perf_counter[31:24];
		end else
      if (address[7] == 0) begin
        data_out <= registers[address[6:0]];
      end
	   else begin
			data_out <= macro_data_readback;
	    end
    end
  end

  //  WRITE REGS
  // MACRO_ADDR  =  0     : 0x00
  // MACRO_DATA  =  1     : 0x01 (write only)
  // MACRO_SELECT=  2     : 0x02 (int status on readback)
  // CONTROL     =  3     : 0x03
  //   CONTROL.0 = HASHCTRL
  //   CONTROL.1 = <available>
  //   CONTROL.2 = PERF_COUNTER run
  //   CONTROL.3 = LED output
  //   CONTROL.4 = hash_clock_reset
  //   CONTROL.5 = ID_out
  // SPI_ADDR    =  4     : 0x04
  //   SPI_ADDR.x= Address on SPI bus (6:0)
  // ID REG      =  5     : 0x05 (read-only)
  // MACRO_WR_EN =  5     : macro write enable
  // MACRO_INFO  =  6     : 0x06 macro count (read-only)
  // PERF_CTR    = 10-7   : 0x0A - 0x07 (read-only)

  assign spi_addr = registers[4][6:0];

  assign macro_data_writeout = registers[1];

`ifdef BYPASS_THIS_ASIC
  assign LED_out = 1;
  assign ID_out = 1;
`else
  assign LED_out = registers[3][3];
  assign ID_out = registers[3][5];
`endif

  // sync HASH_start to MAIN_CLOCK
  reg [1:0]		hash_en_rs;
  wire 			HASH_start;
  always @ (posedge MAIN_CLOCK)
  begin
    hash_en_rs <= {hash_en_rs[0], registers[3][0]};
  end
  assign HASH_start = hash_en_rs[1];

  assign hash_clock_reset = registers[3][4];

  // //////////////////////////////////////////////////////
  // interrupt logic

  wire	[NUM_OF_MACROS - 1: 0]	macro_interrupts;
  reg		[NUM_OF_MACROS - 1: 0]	macro_rs[1:0];

  // resync interrupts to spi clock
  always @(posedge iCLK) begin
    macro_rs[1] <= macro_rs[0];
	 macro_rs[0] <= macro_interrupts;
  end

  assign interrupt_out = |macro_rs[1];

  // //////////////////////////////////////////////////////
  // hash macro interface

  genvar i;
  for (i = 0; i < NUM_OF_MACROS; i = i + 1) begin: hash_macro_multi_block
`ifdef USE_NONBLOCKING_HASH_MACRO
    blake256r14_core_nonblock hash_macro (
`else
    blake256r14_core_block hash_macro (
`endif
					  
						.CLK(MAIN_CLOCK), 
						.HASH_EN(HASH_start), 

						.MACRO_WR_SELECT(registers[5][i]),
						.DATA_IN(macro_data_writeout),

						.MACRO_RD_SELECT(registers[2][i]),
						.ADDR_IN(registers[0][5:0]),

						.THREAD_COUNT(threadCount[i]), // only use [0]

						.DATA_AVAILABLE(macro_interrupts[i]),
						.DATA_OUT(macro_data_readback)
					  );
  end

endmodule // regBank

