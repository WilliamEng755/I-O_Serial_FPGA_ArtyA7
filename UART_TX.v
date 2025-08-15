module UART_TX (
    clk,
    rst,
    i_txdata,
    i_tx_enable,
    o_tx,
    o_busy
);
  parameter BAUD_RATE = 9600;
  parameter DATA_WIDTH = 8;
  parameter CLK_FREQ = 100_000_000;

  input clk;
  input rst;
  input [DATA_WIDTH-1:0] i_txdata;
  input i_tx_enable;
  output reg o_tx;
  output reg o_busy;

  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  localparam CNT_WIDTH = $clog2(CLKS_PER_BIT);

  reg [CNT_WIDTH-1:0] clk_cnt;
  reg tx_pulse;
  reg [DATA_WIDTH-1:0] tx_data;
  reg [ $clog2(DATA_WIDTH)-1 : 0 ] tx_bit_cnt;

  // Estados codificados manualmente
  localparam IDLE = 2'b00;
  localparam START = 2'b01;
  localparam SEND_DATA = 2'b10;
  localparam STOP = 2'b11;
  reg [1:0] uart_txstate;

  // Geração do pulso de baud
  always @(posedge clk) begin
    if (rst) begin
      clk_cnt <= 0;
      tx_pulse <= 0;
    end else if (clk_cnt < CLKS_PER_BIT - 1) begin
      clk_cnt <= clk_cnt + 1;
      tx_pulse <= 0;
    end else begin
      clk_cnt <= 0;
      tx_pulse <= 1;
    end
  end

  // Máquina de estados
  always @(posedge clk) begin
    if (rst) begin
      uart_txstate <= IDLE;
      o_tx <= 1;
      o_busy <= 0;
      tx_bit_cnt <= 0;
    end else begin
      case (uart_txstate)
        IDLE: begin
          o_tx <= 1;
          if (i_tx_enable) begin
            tx_data <= i_txdata;
            o_busy <= 1;
            uart_txstate <= START;
          end else begin
            o_busy <= 0;
          end
        end

        START: begin
          if (tx_pulse) begin
            o_tx <= 0;
            uart_txstate <= SEND_DATA;
            tx_bit_cnt <= 0;
          end
        end

        SEND_DATA: begin
          if (tx_pulse) begin
            o_tx <= tx_data[tx_bit_cnt];        //Uma solução é jogar para o if de baixo
            if (tx_bit_cnt < DATA_WIDTH - 1) begin
              o_tx <= tx_data[tx_bit_cnt];
            end else begin
              uart_txstate <= STOP;
            end
          end
        end

        STOP: begin
          if (tx_pulse) begin
            o_tx <= 1;
            o_busy <= 0;
            uart_txstate <= IDLE;
          end
        end

      endcase
    end
  end

endmodule
