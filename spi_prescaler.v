// ------------------------------------------------------------
// Módulo: Prescaler SPI
// ------------------------------------------------------------
module spi_prescaler #(
    parameter DIVISOR = 4
)(
    input  wire clk,
    input  wire rst,
    output reg  sclk,
    output reg  enable
);

    reg [15:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            sclk <= 0;
            enable <= 0;
        end else begin
            if (count == (DIVISOR-1)) begin
                count <= 0;
                sclk <= ~sclk;
                enable <= 1;
            end else begin
                count <= count + 1;
                enable <= 0;
            end
        end
    end
endmodule