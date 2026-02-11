# IPcoreSIP
Concepção, Modelagem e Desenvolvimento de um IP Core de Comunicação SPI

### Funcionamento do Código **SPI Master**

Ele atua como o controlador da comunicação, gerando o clock e gerenciando o envio e recebimento de dados simultaneamente (Full-Duplex).

O módulo opera como uma máquina de estados implícita que divide o clock do sistema para gerar o clock do SPI e serializa dados de 8 bits.

**1. Interface e Parâmetros:**
*   **Configuração:** O módulo aceita parâmetros para definir o modo SPI (`MODO_SPI`) e a velocidade da transmissão (`CICLOS_POR_MEIO_BIT`), que determina quantos ciclos do clock principal (`clk`) duram meio período do clock SPI (`spi_clk`).
*   **Sinais de Controle:** Utiliza um sistema de *handshake* (aperto de mão). O sinal `tx_pronto` indica que o mestre está livre. O usuário deve colocar o dado em `tx_dado` e pulsar `tx_valido` para iniciar.

**2. Geração de Clock (Divisor de Frequência):**
*   O sistema conta os ciclos do clock principal usando `contador_clk`. Quando atinge o valor definido em `CICLOS_POR_MEIO_BIT`, ele inverte o estado do `clk_spi_interno`.
*   Ele também gerencia um `contador_bordas`. Como cada bit requer uma subida e uma descida do clock, para transmitir 8 bits, o contador é inicializado em 16 bordas.

**3. Transmissão (MOSI - Master Out Slave In):**
*   O dado é enviado pelo pino `spi_mosi`.
*   O envio é sincronizado pelas *flags* `borda_subida` ou `borda_descida`, dependendo da configuração de fase do clock (`cpha`). O código envia o Bit Mais Significativo (MSB - Bit 7) primeiro e decrementa o contador `contador_bit_tx` até chegar ao Bit 0.

**4. Recepção (MISO - Master In Slave Out):**
*   Simultaneamente ao envio, o módulo lê o pino `spi_miso`.
*   O código amostra o valor do pino na borda oposta à de transmissão (definida por `cpha`) e armazena no registrador `rx_dado` na posição indicada por `contador_bit_rx`.
*   Ao final dos 8 bits, o sinal `rx_valido` é ativado para indicar que um novo byte chegou.

---

### Exemplos de Funcionamento

Para ilustrar, vamos assumir um cenário onde `CICLOS_POR_MEIO_BIT = 2` (velocidade rápida) e estamos transmitindo o valor **0x55** (binário `01010101`).

#### Exemplo 1: Início da Transmissão (Idle -> Active)
1.  **Estado Inicial:** O `rst_n` (reset) é liberado. O sinal `tx_pronto` fica alto (1), indicando que o SPI está ocioso e pode receber comandos.
2.  **Ação do Usuário:** Você coloca o valor `8'h55` no barramento `tx_dado` e coloca `tx_valido` em nível alto (1).
3.  **Resposta do Módulo:**
    *   No próximo clock, o módulo detecta `tx_valido`.
    *   O sinal `tx_pronto` vai para **0** (ocupado).
    *   O `contador_bordas` é carregado com **16**.
    *   O dado `0x55` é copiado para o `registrador_tx` interno.

#### Exemplo 2: Durante a Transmissão (Serialização)
Suponha que o módulo esteja configurado para mudar o dado na borda de descida e amostrar na subida (comum em Modo 0).

1.  **Ciclo 1 (MOSI):** O contador de bits aponta para 7. O módulo coloca o bit 7 de `0x55` (que é **0**) na linha `spi_mosi`.
2.  **Ciclo 1 (MISO):** Na borda de subida do `spi_clk`, o módulo lê o valor que o escravo colocou na linha `spi_miso` (vamos supor que o escravo enviou **1**) e salva no bit 7 de `rx_dado`.
3.  **Avanço:** O `contador_bit_tx` e `contador_bit_rx` são decrementados para 6.
4.  **Repetição:** O processo se repete para os bits 6, 5, 4... até o bit 0. O clock `spi_clk` continua oscilando gerado pelo `contador_clk`.

#### Exemplo 3: Finalização (Active -> Idle)
1.  **Contagem Final:** Quando o `contador_bordas` chega a zero, significa que as 16 bordas (8 ciclos completos de clock SPI) ocorreram.
2.  **Sinalização de Recepção:** O `contador_bit_rx` chega a 0. O sinal `rx_valido` vai para **1** por um ciclo de clock, avisando ao sistema que o dado lido em `rx_dado` está completo e correto.
3.  **Liberação:** O sinal `tx_pronto` volta para **1**, indicando que o módulo está pronto para iniciar uma nova transmissão. O `spi_mosi` mantém o último estado ou vai para 0, e o contador de bits é reiniciado para 7 (`3'b111`).

### Resumo dos Sinais Críticos

*   **Entrada `tx_valido`:** "Tenho um dado para enviar, comece agora."
*   **Saída `tx_pronto`:** "Estou livre, pode mandar dados" (nível 1) ou "Estou ocupado transmitindo" (nível 0).
*   **Saída `spi_clk`:** O sinal físico de clock que vai para o dispositivo escravo, gerado a partir da divisão do clock do sistema.
