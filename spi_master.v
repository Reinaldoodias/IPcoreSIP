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


    // ================================
    // Registradores e contadores
    // ================================
    reg [$clog2(CICLOS_POR_MEIO_BIT*2)-1:0] contador_clk;
    reg [4:0] contador_bordas; // Conta o número de bordas do clock SPI (subida + descida)

    reg clk_spi_interno; // Clock SPI interno antes de ser enviado para o pino spi_clk
    reg borda_subida; // Indica quando ocorreu uma borda de subida do clock SPI
    reg borda_descida; // Indica quando ocorreu uma borda de descida do clock SPI


    // Registrador que armazena o byte a ser transmitido via MOSI
    // Funciona como um shift register durante a transmissão
    reg [7:0] registrador_tx;

    // Guarda o estado do sinal tx_valido internamente
    // Evita perder o pedido de transmissão enquanto o SPI está ocupado
    reg       tx_valido_reg;

    // Contador de bits transmitidos (0 a 7)
    // Controla qual bit do registrador_tx está sendo enviado
    reg [2:0] contador_bit_tx;

    // Contador de bits recebidos (0 a 7)
    // Controla a montagem do byte recebido via MISO
    reg [2:0] contador_bit_rx;

);
