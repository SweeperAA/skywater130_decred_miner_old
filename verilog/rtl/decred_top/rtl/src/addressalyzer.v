`timescale 1ns / 1ps

module addressalyzer (
  input  wire  RST,
  input  wire  iCLK,

  input        start_of_transfer,
  input        end_of_transfer,
  input [7:0]  data_in_value,
  input        data_in_ready,
  input        data_out_request,
  input        write_enable_mask,

  output wire [14:0] ram_address_out,
  output reg   address_strobe,
  output       ram_read_strobe,
  output       ram_write_strobe
  );

  wire read_cycle;

  // //////////////////////////////////////////////////////
  // Address FSM signals 
  parameter ADDR_SIZE     = 6;
  parameter ADDR_IDLE     = 6'b000001;
  parameter ADDR_ADDR1    = 6'b000010;
  parameter ADDR_ADDR2    = 6'b000100;  
  parameter ADDR_RD_BYTES = 6'b001000;  
  parameter ADDR_WR_BYTEQ = 6'b010000;  
  parameter ADDR_WR_BYTES = 6'b100000;  

  reg [ADDR_SIZE - 1:0]  addr_state;

  reg [15:0] address_local;
  assign read_cycle = address_local[15];
  assign ram_address_out = address_local[14:0];

  always @ (posedge iCLK) begin 
    if(RST) begin 
      address_local  <= 0;
      address_strobe <= 0;
      addr_state     <= ADDR_IDLE;
    end
    else begin

      case (addr_state)

        ADDR_IDLE:
		    begin
          address_local  <= 0;
          address_strobe <= 0;
	  	    if (start_of_transfer == 1'b1) begin
            addr_state <= ADDR_ADDR1;
          end
		    end

        ADDR_ADDR1:
  		  if (data_in_ready == 1'b1) begin

          address_local <= {data_in_value, data_in_value};
          addr_state <= ADDR_ADDR2;

        end

        ADDR_ADDR2:
		    if (data_in_ready == 1'b1) begin

          address_local  <= {address_local[15:8], data_in_value};
          address_strobe <= 1;

          if (read_cycle == 1'b1) begin

            addr_state <= ADDR_RD_BYTES;

          end else begin

            addr_state <= ADDR_WR_BYTEQ;
 
          end
        end 

        ADDR_RD_BYTES:
		    if (data_out_request == 1'b1) begin

          address_local  <= address_local + 1'b1;
          address_strobe <= 0;

        end else if (end_of_transfer == 1'b1) begin

          addr_state     <= ADDR_IDLE;
          address_strobe <= 0;

        end

        ADDR_WR_BYTEQ:
		    if (data_in_ready == 1'b1) begin

          addr_state     <= ADDR_WR_BYTES;
          address_strobe <= 0;

        end else if (end_of_transfer == 1'b1) begin

          addr_state <= ADDR_IDLE;
          address_strobe <= 0;

        end

        ADDR_WR_BYTES:
	      if (data_in_ready == 1'b1) begin

          address_local <= address_local + 1'b1;

        end else if (end_of_transfer == 1'b1) begin

          addr_state <= ADDR_IDLE;

        end

        default: begin
          addr_state <= ADDR_IDLE;
        end
      endcase
    end
  end

  // //////////////////////////////////////////////////////
  // Read/Write FSM signals 
  parameter RDWR_SIZE       = 4;
  parameter RDWR_IDLE       = 4'b0001;
  parameter RDWR_CLK_EN     = 4'b0010;
  parameter RDWR_STROBE0    = 4'b0100;  
  parameter RDWR_END        = 4'b1000;  

  reg [RDWR_SIZE - 1:0]  rdwr_state;
  reg rdwr_read_en;
  reg rdwr_write_en;

  assign ram_read_strobe = rdwr_read_en;
  assign ram_write_strobe = rdwr_write_en;

  always @ (posedge iCLK) begin 
    if(RST) begin 
      rdwr_state    <= RDWR_IDLE;
      rdwr_read_en  <= 0;
      rdwr_write_en <= 0;
    end
    else begin

    case (rdwr_state)

      RDWR_IDLE:
      if (addr_state == ADDR_WR_BYTES) begin

        rdwr_read_en     <= 0;
        rdwr_write_en    <= write_enable_mask;
        rdwr_state       <= RDWR_CLK_EN;

      end else if (addr_state == ADDR_RD_BYTES) begin

        rdwr_read_en     <= 0;
        rdwr_write_en    <= 0;
        rdwr_state       <= RDWR_CLK_EN;
		  end

      RDWR_CLK_EN:
      if (addr_state == ADDR_WR_BYTES) begin

        rdwr_read_en     <= 0;
        rdwr_write_en    <= 0;
        rdwr_state       <= RDWR_STROBE0;

      end else if (addr_state == ADDR_RD_BYTES) begin

        rdwr_read_en     <= 1;
        rdwr_write_en    <= 0;
        rdwr_state       <= RDWR_STROBE0;
		  end

      RDWR_STROBE0:
      begin

        rdwr_read_en     <= 0;
        rdwr_write_en    <= 0;
        rdwr_state       <= RDWR_END;
      end

      RDWR_END:
      begin

        if (data_in_ready == 1'b1) begin

          rdwr_state <= RDWR_IDLE;
		    end
      end

      default:
      begin
        rdwr_state <= RDWR_IDLE;
      end
      endcase
     end
   end
endmodule // addressalyzer
