`timescale 1ns / 1ps

`include "decred_defines.v"

module spi_passthrough (
  input  wire  iCLK,
  input  wire  RSTin,
  input  wire	 ID_in, 
  input	 wire	 IRQ_in,
  input  wire  address_strobe,
  input  wire [6:0] currentSPIAddr,
  input  wire [6:0] setSPIAddr,

  input  wire  SCLKin,
  input  wire  SCSNin,
  input  wire  MOSIin,
  output wire  MISOout,

  output wire  rst_local,
  output wire  sclk_local,
  output wire	 scsn_local,
  output wire	 mosi_local,
  input	 wire	 miso_local,
  input	 wire	 irq_local,
  output wire  write_enable,

  output wire  RSTout,
  output wire  SCLKout,
  output wire  SCSNout,
  output wire  MOSIout,
  input  wire  MISOin,
  output wire  IRQout
  );

  // each of the inputs are negated
  wire rst_wire;

  // //////////////////////////////////////////////////////
  // synchronizers
  reg [1:0] id_resync;
  reg [1:0] reset_resync;

  always @(posedge iCLK)
    if (rst_wire) begin
      id_resync <= 0;
    end
    else begin
      id_resync <= {id_resync[0], ID_in};
    end

  reg [1:0] irq_resync;

  always @(posedge iCLK)
    if (rst_wire) begin
      irq_resync <= 0;
    end
    else begin
      irq_resync <= {irq_resync[0], IRQ_in};
    end

`ifdef BYPASS_THIS_ASIC
  assign IRQout = IRQ_in;
`else
  assign IRQout = irq_resync[1] | irq_local;
`endif

  always @(posedge iCLK)
    begin
      reset_resync <= {reset_resync[0], !RSTin};
    end

  // //////////////////////////////////////////////////////
  // pass-through signals and pick-off

  assign rst_wire = reset_resync[1];
  assign rst_local = rst_wire;
  assign RSTout = RSTin;

  assign SCLKout = SCLKin;
  assign sclk_local = SCLKin;

  assign SCSNout = SCSNin;
  assign scsn_local = SCSNin;

  assign MOSIout = MOSIin;
  assign mosi_local = MOSIin;

  // //////////////////////////////////////////////////////
  // MISO mux

  wire unique_address_match;
  wire id_active;
  reg  local_address_select;

  assign unique_address_match = (currentSPIAddr == setSPIAddr) ? 1'b1 : 1'b0;
  assign id_active = id_resync[1];

  always @(posedge iCLK)
    if (rst_wire) begin
      local_address_select <= 0;
    end
    else begin
      if (address_strobe) begin
        if ((id_active) && (unique_address_match)) begin
          local_address_select <= 1;
        end else begin
          local_address_select <= 0;
        end
      end
    end

`ifdef BYPASS_THIS_ASIC
  assign MISOout = MISOin;
`else
  assign MISOout = (local_address_select) ? miso_local : MISOin;
`endif

  // //////////////////////////////////////////////////////
  // Write enable mask

  wire global_address_match;
  reg  global_address_select;

  assign global_address_match = (currentSPIAddr == 7'b1111111) ? 1'b1 : 1'b0;

  always @(posedge iCLK)
    if (rst_wire) begin
      global_address_select <= 0;
    end
    else begin
      if (address_strobe) begin
        if ((id_active) && ((unique_address_match) || (global_address_match))) begin
          global_address_select <= 1;
        end else begin
          global_address_select <= 0;
        end
      end
    end

  assign write_enable = global_address_select;

endmodule // spi_passthrough
