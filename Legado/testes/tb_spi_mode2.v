// ------------------------------------------------------------
// Testbench SPI - Modo 2 (CPOL=1, CPHA=0)
// ------------------------------------------------------------
`timescale 1ns/1ps
module tb_spi_mode2;

    reg clk = 0;
    reg rst = 0;
    reg start = 0;
    reg [7:0] data_in = 8'b10101100;
    wire [7:0] data_out;
    wire busy, SCLK, MOSI, CS;
    reg MISO = 0;

    always #10 clk = ~clk;

    spi_master #(
        .DATA_WIDTH(8),
        .PRESCALE(4),
        .CPOL(1),
        .CPHA(0)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .busy(busy),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS(CS)
    );

    initial begin
        $dumpfile("spi_mode2.vcd");
        $dumpvars(0, tb_spi_mode2);

        rst = 1; #40; rst = 0;
        #50 start = 1; #20 start = 0;

        // MISO alterna nas bordas de subida
        forever begin
            @(posedge SCLK);
            MISO = $random;
        end
    end

    initial begin
        #2000 $finish;
    end
endmodule