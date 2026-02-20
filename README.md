# 🧠 IP Core SPI em FPGA

> **Estudo e Desenvolvimento de um IP Core de Comunicação SPI em FPGA**  
> Universidade Estadual do Maranhão (UEMA) – Programa de Pós-Graduação em Engenharia da Computação e Sistemas (PECS)  
> Curso: Especialização em Microeletrônica para Front-End Digital – 2026

---

## 🎯 Objetivo

Desenvolver e validar um **IP Core do protocolo SPI (Serial Peripheral Interface)** implementado em FPGA, com **arquitetura modular, parametrizável e de alta reutilização**.  
O projeto foi descrito em **Verilog HDL**, modelado em nível RTL e validado por meio de simulações funcionais e temporais.

---

## ⚙️ Características do IP Core

| Componente | Descrição |
|-------------|------------|
| 🧩 **Linguagem** | Verilog HDL |
| 🧱 **Nível de modelagem** | RTL (Register Transfer Level) |
| ⚙️ **Modo de operação** | Mestre (Master) |
| 🔄 **Modos SPI suportados** | CPOL = {0,1}, CPHA = {0,1} (Modos 0, 1, 2 e 3) |
| 📏 **Largura de dados** | Parametrizável (`DATA_WIDTH`) |
| ⏱️ **Divisor de clock (Prescaler)** | Parametrizável (`PRESCALE`) |
| 🧮 **FSM** | 4 estados (IDLE → LOAD → TRANSFER → DONE) |
| 🧪 **Verificação** | Simulação funcional e temporal |
| 🧰 **Síntese FPGA** | Intel Quartus Prime |

---

## 🧩 Estrutura do Projeto

```

spi_master/
│
├── src/
│   ├── spi_master.v        # Módulo principal
│   ├── spi_prescaler.v     # Geração de clock SPI (Prescaler)
│
├── sim/
│   ├── tb_spi_modes.v      # Testbench para os 4 modos SPI
│
├── docs/
│   ├── README.md           # Este arquivo
│   └── relatorio_tcc.pdf   # Documento técnico (opcional)
│
└── synthesis/
├── quartus_project.qpf # Projeto de síntese
└── timequest_report.rpt

````

---

## 🔩 Descrição dos Módulos

### `spi_master.v`
Implementa o protocolo SPI em modo mestre, controlando o fluxo de dados via FSM e fazendo interface com o barramento SPI.

**Parâmetros:**
```verilog
parameter DATA_WIDTH = 8;
parameter PRESCALE   = 4;
parameter CPOL       = 0;
parameter CPHA       = 0;
````

| Sinal      | Direção | Descrição                  |
| ---------- | ------- | -------------------------- |
| `clk`      | Entrada | Clock principal            |
| `rst`      | Entrada | Reset síncrono             |
| `start`    | Entrada | Inicia transmissão         |
| `data_in`  | Entrada | Dado paralelo a transmitir |
| `data_out` | Saída   | Dado recebido              |
| `busy`     | Saída   | Indica transmissão ativa   |
| `SCLK`     | Saída   | Clock SPI                  |
| `MOSI`     | Saída   | Mestre → Escravo           |
| `MISO`     | Entrada | Escravo → Mestre           |
| `CS`       | Saída   | Chip Select ativo em 0     |

---

### `spi_prescaler.v`

Gera o sinal de clock `SCLK` a partir do clock do sistema (`clk`), dividindo a frequência por um fator configurável (`DIVISOR`).

| Parâmetro | Descrição                                                  |
| --------- | ---------------------------------------------------------- |
| `DIVISOR` | Número de ciclos do clock principal para inverter o `SCLK` |

Saídas:

* `sclk`: clock SPI gerado
* `enable`: pulso para sincronização da FSM

---

## 🧠 Máquina de Estados (FSM)

| Estado     | Descrição                                        |
| ---------- | ------------------------------------------------ |
| `IDLE`     | Núcleo em repouso, aguardando `start`.           |
| `LOAD`     | Carrega o dado paralelo a transmitir.            |
| `TRANSFER` | Envia/recebe bits sincronizados com o clock SPI. |
| `DONE`     | Indica o fim da transmissão e libera o escravo.  |

---

## 🧪 Verificação Funcional — Testbench Universal

Arquivo: `sim/tb_spi_modes.v`

```verilog
// ------------------------------------------------------------
// Testbench Universal - Verifica os 4 modos SPI (0,1,2,3)
// ------------------------------------------------------------
`timescale 1ns/1ps
module tb_spi_modes;

    reg clk = 0, rst = 0, start = 0;
    reg [7:0] data_in = 8'b10101100;
    wire [7:0] data_out;
    wire busy, SCLK, MOSI, CS;
    reg MISO = 0;

    // Clock principal (50 MHz)
    always #10 clk = ~clk;

    // Parâmetros de teste
    integer CPOL, CPHA;
    integer modo;

    // Loop para testar os 4 modos SPI
    initial begin
        for (modo = 0; modo < 4; modo = modo + 1) begin
            CPOL = modo[1];
            CPHA = modo[0];

            $display("==== Testando Modo %0d (CPOL=%0d, CPHA=%0d) ====", modo, CPOL, CPHA);
            run_mode(CPOL, CPHA);
        end
        #1000 $finish;
    end

    task run_mode(input integer cpol, input integer cpha);
        begin
            // Instancia temporária do SPI
            spi_master #(
                .DATA_WIDTH(8),
                .PRESCALE(4),
                .CPOL(cpol),
                .CPHA(cpha)
            ) DUT (
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

            // Reset e início
            rst = 1; #40; rst = 0;
            #50 start = 1; #20 start = 0;

            // Gera bits de MISO conforme clock
            fork
                forever @(posedge SCLK or negedge SCLK)
                    MISO = $random;
            join_none

            #1000;
        end
    endtask
endmodule
```

💡 Este testbench varre automaticamente os modos SPI:

* **Modo 0:** CPOL=0, CPHA=0
* **Modo 1:** CPOL=0, CPHA=1
* **Modo 2:** CPOL=1, CPHA=0
* **Modo 3:** CPOL=1, CPHA=1

---

## 🧪 Simulação

No terminal do **QuestaSim/ModelSim**, execute:

```bash
vlog src/spi_master.v src/spi_prescaler.v sim/tb_spi_modes.v
vsim tb_spi_modes
add wave -r /*
run 4000ns
```

Verifique nas formas de onda:

* Nível ocioso do clock (`SCLK`) de acordo com o `CPOL`;
* Amostragem e troca de dados conforme `CPHA`;
* `CS` ativo durante a transação;
* `busy` ativo durante a transmissão.

---

## 📊 Métricas de Desempenho

| Métrica                | Descrição                        | Ferramenta         |
| ---------------------- | -------------------------------- | ------------------ |
| Utilização de LUTs/FFs | Recursos lógicos consumidos      | Quartus Prime      |
| Frequência máxima      | Determinada via análise temporal | TimeQuest Analyzer |
| Latência               | Ciclos por transação SPI         | QuestaSim          |
| Throughput             | Taxa efetiva de transferência    | Simulação temporal |

---

## 🧰 Ferramentas Utilizadas

* 🧠 **Intel Quartus Prime** – Modelagem, síntese e análise temporal
* 🧪 **QuestaSim / ModelSim** – Simulação funcional
* ⚙️ **Verilog HDL** – Linguagem de descrição de hardware
* 🔌 **FPGA Cyclone V** – Plataforma de teste (exemplo)

---

## 🧠 Referências

* Liu, Tianxiang; Wang, Yunfeng. *IP design of universal multiple devices SPI interface*. IEEE, 2011.
* Sandya, M.; Rajasekhar, K. *Design and verification of serial peripheral interface*. IJETT, 2012.
* Kurapati, Jyothsna. *A design methodology for implementation of serial peripheral interface using VHDL*. 2005.
* Nalina, H. D. et al. *FPGA implementation of SPI protocol*. IJTRET, 2024.
* Digital Core Design. *Enhanced SPI Master/Slave Controller (DESPI)*, 2026.

---

## 🪪 Licença

Projeto acadêmico desenvolvido no âmbito do TCC da Especialização em Microeletrônica da UEMA/PECS.
Uso livre para fins **educacionais e não comerciais**, com citação da fonte original.
