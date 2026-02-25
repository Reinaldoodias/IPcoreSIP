module top (
    input        CLOCK_50,
    input  [3:0] KEY,
    input  [9:0] SW,
    output [9:0] LEDR,
    output [7:0] LEDG
);

    wire [7:0] data_out;
    wire busy;
    wire mosi_wire;

    spi_master #(
        .DATA_WIDTH(8),
        .PRESCALE(50)   // pequeno para ver funcionar
    ) spi_inst (
        .clk(CLOCK_50),
        .rst(KEY[0]),
        .start(KEY[1]),
        .data_in(SW[7:0]),
        .data_out(data_out),
        .busy(busy),
        .SCLK(),                // ignorado
        .MOSI(mosi_wire),
        .MISO(mosi_wire),       // 👈 LOOPBACK INTERNO
        .CS()
    );

    assign LEDG[7:0] = data_out;
    assign LEDR[9]   = busy;

endmodule