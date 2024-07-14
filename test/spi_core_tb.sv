//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2024 01:02:27 PM
// Design Name: 
// Module Name: spi_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Test bench for SPI core module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_tb ();  
  
  parameter CLK_DELAY = 2;  // 25 MHz

  logic reset     = 1'b0;  
  logic clk       = 1'b0;
  logic spi_sclk;
  logic spi_mosi;
  logic spi_miso;
  logic spi_ready;
  logic spi_out;

  logic dvsr 15'h0200;

  logic cpol = 1'b1;
  logic cpha = 1'b1;

  logic [7:0] wr_data;
  logic wr_spi;

  

  // Clock
  always #(CLK_DELAY) clk = ~clk;

  // Instantiate UUT
  spi spi_uut (
    .clk(clk), .reset(reset),
    .din(wr_data[7:0]),
    .dvsr(dvsr),
    .start(wr_spi),
    .cpol(cpol),
    .cpha(cpha),
    .dout(spi_out),
    .sclk(spi_sclk),
    .miso(spi_miso),
    .mosi(spi_mosi),
    .spi_done_tick(),
    .ready(spi_ready)
);


  // Sends a single byte from master.
  task SendSingleByte(input [7:0] data);
    @(posedge clk);
    wr_data <= data;
    @(posedge clk);
    @(posedge spi_ready);
  endtask // SendSingleByte

  
  initial
    begin
        $dumpfile("dump.vcd"); 
        $dumpvars;
        
        repeat(10) @(posedge clk);
        reset  = 1'b0;
        repeat(10) @(posedge clk);
        reset  = 1'b1;
        
        wr_spi = 1'b1;
        @(posedge clk);
        assert (spi_ready == 0)        
        else                               
            $error("%m Not ready");
            
        // Test single byte
        SendSingleByte(8'hC1);
        $display("Sent 0xC1, Received 0x%X", spi_out); 
        
        // Test double byte
        SendSingleByte(8'hBE);
        $display("Sent 0xBE, Received 0x%X", spi_out); 
        SendSingleByte(8'hEF);
        $display("Sent 0xEF, Received 0x%X", spi_out); 
        repeat(10) @(posedge clk);
        $finish();      
    end // initial begin

endmodule // spi_tb