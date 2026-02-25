`timescale 1ns/1ps

module tb_spi_master;

    parameter DATA_WIDTH = 8;
    parameter PRESCALE   = 4;

    reg clk;
    reg rst;
    reg start;
    reg [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire busy;
    wire SCLK;
    wire MOSI;
    wire MISO;
    wire CS;

    // Loopback interno
    assign MISO = MOSI;

    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .PRESCALE(PRESCALE)
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

    // Clock
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin

        rst   = 1;
        start = 0;
        data_in = 8'b10101010;

        #50;
        rst = 0;

        #50;

        start = 1;
        #20;
        start = 0;

        wait(busy == 0);

        #100;

        if (data_out == data_in)
            $display("TESTE PASSOU: %b", data_out);
        else
            $display("ERRO: esperado %b, recebido %b", data_in, data_out);

        #100;
        $stop;
    end

endmodule