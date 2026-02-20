// ------------------------------------------------------------
// Módulo: SPI Master IP Core
// Universidade Estadual do Maranhão - UEMA (2026)
// Autor: baseado no TCC - PECS / Microeletrônica Front-End Digital
// ------------------------------------------------------------
// Descrição:
// Implementação do protocolo SPI no modo mestre, com arquitetura modular,
// suporte aos quatro modos (CPOL/CPHA), e largura de dados parametrizável.
// ------------------------------------------------------------
module spi_master #(
    parameter DATA_WIDTH = 8,   // Largura da palavra de dados
    parameter PRESCALE   = 4,   // Divisor de clock para o SCLK
    parameter CPOL       = 0,   // Polaridade do clock
    parameter CPHA       = 0    // Fase do clock
)(
    input  wire clk,             // Clock principal do sistema (FPGA)
    input  wire rst,             // Reset síncrono
    input  wire start,           // Inicia transmissão
    input  wire [DATA_WIDTH-1:0] data_in,  // Dado paralelo a transmitir
    output wire [DATA_WIDTH-1:0] data_out, // Dado recebido do escravo
    output wire busy,            // Indica transmissão em andamento

    // Linhas do barramento SPI
    output wire SCLK,            // Clock SPI
    output reg  MOSI,            // Mestre -> Escravo
    input  wire MISO,            // Escravo -> Mestre
    output reg  CS               // Chip Select (ativo em 0)
);

    // ------------------------------------------------------------
    // Sinais internos
    // ------------------------------------------------------------
    wire spi_clk;                // Clock SPI gerado pelo prescaler
    wire spi_clk_en;             // Pulso de habilitação de clock
    reg [DATA_WIDTH-1:0] tx_shift; // Registrador de transmissão
    reg [DATA_WIDTH-1:0] rx_shift; // Registrador de recepção
    reg [$clog2(DATA_WIDTH):0] bit_cnt; // Contador de bits
    reg [1:0] state;             // Estado da FSM

    // ------------------------------------------------------------
    // Parâmetros da FSM
    // ------------------------------------------------------------
    localparam IDLE     = 2'b00;
    localparam LOAD     = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam DONE     = 2'b11;

    // ------------------------------------------------------------
    // Instanciação do Prescaler (gera o clock SPI)
    // ------------------------------------------------------------
    spi_prescaler #(
        .DIVISOR(PRESCALE)
    ) prescaler_inst (
        .clk(clk),
        .rst(rst),
        .sclk(spi_clk),
        .enable(spi_clk_en)
    );

    // ------------------------------------------------------------
    // Máquina de Estados (FSM)
    // ------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            bit_cnt <= 0;
            CS      <= 1'b1;
            MOSI    <= 1'b0;
            tx_shift <= 0;
            rx_shift <= 0;
        end else begin
            case (state)
                IDLE: begin
                    CS <= 1'b1;
                    if (start)
                        state <= LOAD;
                end

                LOAD: begin
                    tx_shift <= data_in;
                    rx_shift <= 0;
                    bit_cnt <= DATA_WIDTH;
                    CS <= 1'b0;
                    state <= TRANSFER;
                end

                TRANSFER: begin
                    if (spi_clk_en) begin
                        // Transmissão e recepção conforme CPHA
                        if (CPHA == 0) begin
                            MOSI <= tx_shift[DATA_WIDTH-1];
                            tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                            rx_shift <= {rx_shift[DATA_WIDTH-2:0], MISO};
                        end else begin
                            rx_shift <= {rx_shift[DATA_WIDTH-2:0], MISO};
                            MOSI <= tx_shift[DATA_WIDTH-1];
                            tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                        end

                        if (bit_cnt > 0)
                            bit_cnt <= bit_cnt - 1;
                        else
                            state <= DONE;
                    end
                end

                DONE: begin
                    CS <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------
    // Saídas
    // ------------------------------------------------------------
    assign data_out = rx_shift;
    assign SCLK = (state == TRANSFER) ? spi_clk : CPOL;
    assign busy = (state != IDLE);

endmodule