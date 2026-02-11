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
    output reg spi_mosi // Linha MOSI (Master Out, Slave In)]
);


    // Interface SPI (todos os sinais relacionados operam no domínio do clock SPI)
    wire cpol;    // como o clock começa - estado ocioso
    wire cpha;   // se você lê no primeiro ou segundo movimento


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

    // ================================
    // Geração do clock SPI e controle da transmissão
    // ================================
    always @(posedge clk or negedge rst_n)
    begin
        // Reset assíncrono ativo em nível baixo
        if (!rst_n)
        begin
            tx_pronto        <= 1'b0;   // Indica que o SPI não está pronto após o reset
            contador_bordas  <= 0;      // Zera o contador de bordas do clock SPI
            borda_subida     <= 1'b0;   // Limpa flag de borda de subida
            borda_descida    <= 1'b0;   // Limpa flag de borda de descida
            clk_spi_interno  <= cpol;   // Inicializa o clock SPI conforme a polaridade (CPOL)
            contador_clk     <= 0;      // Zera o divisor de clock
        end
        else
        begin
            // Flags de borda válidas por apenas um ciclo de clock
            borda_subida  <= 1'b0;
            borda_descida <= 1'b0;

            // Início de uma nova transmissão
            if (tx_valido)
            begin
                tx_pronto       <= 1'b0; // SPI ocupado
                contador_bordas <= 16;   // 16 bordas para transmitir 8 bits
            end
            // Transmissão em andamento
            else if (contador_bordas > 0)
            begin
                tx_pronto <= 1'b0; // SPI ocupado durante a transmissão

                // Fim do período completo do clock SPI (borda de descida)
                if (contador_clk == CICLOS_POR_MEIO_BIT*2-1)
                begin
                    contador_bordas <= contador_bordas - 1'b1; // Decrementa bordas restantes
                    borda_descida   <= 1'b1;                    // Sinaliza borda de descida
                    contador_clk    <= 0;                       // Reinicia contador de clock
                    clk_spi_interno <= ~clk_spi_interno;        // Inverte o clock SPI
                end
                // Meio período do clock SPI (borda de subida)
                else if (contador_clk == CICLOS_POR_MEIO_BIT-1)
                begin
                    contador_bordas <= contador_bordas - 1'b1; // Decrementa bordas restantes
                    borda_subida    <= 1'b1;                    // Sinaliza borda de subida
                    contador_clk    <= contador_clk + 1'b1;    // Avança contador
                    clk_spi_interno <= ~clk_spi_interno;       // Inverte o clock SPI
                end
                // Contagem normal do divisor de clock
                else
                    contador_clk <= contador_clk + 1'b1;
            end
            // Fim da transmissão
            else
                tx_pronto <= 1'b1; // SPI pronto para novo dado
        end
    end

    // ================================
    // Registrador Interno de Transmissão
    // ================================
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            registrador_tx <= 8'h00; // Zera o registrador de transmissão (8 bits)
            tx_valido_reg  <= 1'b0; // Limpa o sinal que indica dado válido
        end
        else
        begin
            tx_valido_reg <= tx_valido; // Registra (sincroniza) o sinal tx_valido na borda de subida do clock

            if (tx_valido)
                registrador_tx <= tx_dado; // Carrega o dado de entrada no registrador de transmissão
        end
    end

    // ================================
    // Transmissão serial dos bits no barramento SPI (linha MOSI)
    // ================================
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            spi_mosi        <= 1'b0; // Força a linha MOSI para 0
            contador_bit_tx <= 3'b111; // Inicializa contador no bit mais significativo (bit 7)
        end
        else
        begin
            if (tx_pronto) // Se a transmissão terminou
                contador_bit_tx <= 3'b111; // Reinicia contador para próxima transmissão

            else if (tx_valido_reg & ~cpha) // Se há dado válido e CPHA = 0 (modo 0 ou 2)
            begin
                spi_mosi        <= registrador_tx[3'b111]; // Envia primeiro o MSB
                contador_bit_tx <= 3'b110; // Prepara próximo bit (bit 6)
            end
            else if ((borda_subida & cpha) | 
                    (borda_descida & ~cpha)) // Atualiza dado conforme modo SPI (CPHA)
            begin
                spi_mosi        <= registrador_tx[contador_bit_tx]; // Envia bit atual
                contador_bit_tx <= contador_bit_tx - 1'b1; //decrementa contador
            end
        end
    end


endmodule
