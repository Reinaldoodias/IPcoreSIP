module spi_master
#(
    parameter MODO_SPI = 0, // Parâmetro que define o modo de operação do SPI

    // Número de ciclos de clock do sistema para cada meio período do clock SPI
    // Controla a frequência do spi_clk
    parameter CICLOS_POR_MEIO_BIT = 2 
)
(
    input  wire clk, // Clock do sistema
    input  wire rst_n, // Reset ativo em nível baixo

    input  wire [7:0] tx_dado,  // Dado a ser transmitido (8 bits)
    input  wire       tx_valido, // Indica que o dado de transmissão é válido
    output reg        tx_pronto, // Indica que o módulo está pronto para receber um novo dado

    output reg  [7:0] rx_dado, // Dado recebido
    output reg        rx_valido, // Indica que o dado recebido é valido

    output reg spi_clk,  // Clock SPI gerado pelo master
    input  wire spi_miso, // Linha MISO (Master In, Slave Out)
    output reg spi_mosi // Linha MOSI (Master Out, Slave In)

    // Interface SPI (todos os sinais relacionados operam no domínio do clock SPI)
    wire w_CPOL;    // como o clock começa - estado ocioso
    wire w_CPHA;   // se você lê no primeiro ou segundo movimento
);
