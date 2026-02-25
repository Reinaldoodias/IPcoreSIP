module spi_master #(
    parameter DATA_WIDTH = 8,
    parameter PRESCALE   = 50,
    parameter CPOL       = 0
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output wire busy,

    output wire SCLK,
    output reg  MOSI,
    input  wire MISO,
    output reg  CS
);

    // ============================================
    // Ajuste para botões da DE1 (ativos em 0)
    // ============================================

    wire real_reset = ~rst;
    wire real_start = ~start;

    reg start_d;
    wire start_pulse;

    always @(posedge clk or posedge real_reset) begin
        if (real_reset)
            start_d <= 1'b0;
        else
            start_d <= real_start;
    end

    assign start_pulse = real_start & ~start_d;

    // ============================================
    // Prescaler
    // ============================================

    wire spi_clk;
    wire spi_clk_en;

    spi_prescaler #(.DIVISOR(PRESCALE)) prescaler_inst (
        .clk(clk),
        .rst(real_reset),
        .sclk(spi_clk),
        .enable(spi_clk_en)
    );

    // ============================================
    // Registradores
    // ============================================

    reg [DATA_WIDTH-1:0] tx_shift;
    reg [DATA_WIDTH-1:0] rx_shift;
    reg [3:0] bit_cnt;

    reg [1:0] state;

    localparam IDLE     = 2'b00;
    localparam LOAD     = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam DONE     = 2'b11;

    // ============================================
    // FSM
    // ============================================

    always @(posedge clk or posedge real_reset) begin
        if (real_reset) begin
            state     <= IDLE;
            CS        <= 1'b1;
            MOSI      <= 1'b0;
            tx_shift  <= 0;
            rx_shift  <= 0;
            bit_cnt   <= 0;
            data_out  <= 0;
        end else begin

            case (state)

                // =========================
                IDLE:
                // =========================
                begin
                    CS <= 1'b1;

                    if (start_pulse)
                        state <= LOAD;
                end

                // =========================
                LOAD:
                // =========================
                begin
                    CS       <= 1'b0;
                    tx_shift <= data_in;
                    rx_shift <= 0;
                    bit_cnt  <= DATA_WIDTH;
                    state    <= TRANSFER;
                end

                // =========================
					TRANSFER: begin
						 if (spi_clk_en) begin

							  // Primeiro envia o bit atual
							  MOSI <= tx_shift[DATA_WIDTH-1];

							  // Depois desloca TX
							  tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};

							  // Só captura depois que MOSI já foi atualizado
							  rx_shift <= {rx_shift[DATA_WIDTH-2:0], tx_shift[DATA_WIDTH-1]};

							  if (bit_cnt > 1)
									bit_cnt <= bit_cnt - 1;
							  else
									state <= DONE;
						 end
					end

                // =========================
                DONE:
                // =========================
                begin
                    CS <= 1'b1;
                    data_out <= rx_shift;
                    state <= IDLE;
                end

            endcase
        end
    end

    // ============================================
    // Saídas
    // ============================================

    assign SCLK = (state == TRANSFER) ? 
                  (CPOL ? ~spi_clk : spi_clk) 
                  : CPOL;

    assign busy = (state != IDLE);

endmodule