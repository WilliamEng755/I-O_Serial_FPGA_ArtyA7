module UART_RX (
    clk,
    rst,
    i_rx_bit,
    o_data_vld,
    o_rx_data
);
  parameter CLK_FREQ = 100_000_000;
  parameter DATA_WIDTH = 8;
  parameter OVERSAMPLING_RATE = 16;
  parameter BAUD_RATE = 9600;

  input clk;
  input rst;
  input i_rx_bit;
  output reg o_data_vld;
  output reg [DATA_WIDTH-1:0] o_rx_data;

  localparam OVS_CNT_TH = CLK_FREQ / BAUD_RATE / OVERSAMPLING_RATE;
  localparam CNT_WIDTH = $clog2(OVS_CNT_TH);
  localparam OVSC_WIDTH = $clog2(OVERSAMPLING_RATE);

  reg [CNT_WIDTH-1:0] oversampling_clk_cnt;
  reg oversampling_pulse;
  reg [2:0] rx_bit_samples;
  reg rx_bit;
  reg [DATA_WIDTH-1:0] rx_data;
  reg [OVSC_WIDTH-1:0] oversample_cnt;
  reg [ $clog2(DATA_WIDTH)-1 : 0 ] rx_bit_cnt;
  reg d_meta, input_bit;

  // Estados
  localparam IDLE = 2'b00;
  localparam START = 2'b01;
  localparam READ_DATA = 2'b10;
  localparam STOP = 2'b11;
  reg [1:0] uart_rx_state;

  // Sincronizador de entrada
  always @(posedge clk) begin
    d_meta <= i_rx_bit;
    input_bit <= d_meta;
  end

  // Pulso de oversampling
  always @(posedge clk) begin
    if (rst) begin
      oversampling_clk_cnt <= 0;
      oversampling_pulse <= 0;
    end else if (oversampling_clk_cnt < OVS_CNT_TH - 1) begin
      oversampling_clk_cnt <= oversampling_clk_cnt + 1;
      oversampling_pulse <= 0;
    end else begin
      oversampling_clk_cnt <= 0;
      oversampling_pulse <= 1;
    end
  end

  // Votação majoritária
  always @(posedge clk) begin
    if (oversampling_pulse) begin
      rx_bit_samples <= { rx_bit_samples[1:0], input_bit };
      if (rx_bit_samples == 3'b000 ||
          rx_bit_samples == 3'b001 ||
          rx_bit_samples == 3'b010 ||
          rx_bit_samples == 3'b100)
        rx_bit <= 0;
      else
        rx_bit <= 1;
    end
  end

  // FSM
  always @(posedge clk) begin
    if (rst) begin
      uart_rx_state <= IDLE;
      o_data_vld <= 0;
      rx_bit_cnt <= 0;
      oversample_cnt <= 0;
    end else if (oversampling_pulse) begin
      case (uart_rx_state)
        IDLE: begin
          o_data_vld <= 0;
          oversample_cnt <= 0;
          if (input_bit == 0) begin
            uart_rx_state <= START;
            oversample_cnt <= 1;
          end
        end

        START: begin
          if (oversample_cnt == (OVERSAMPLING_RATE/2 + 1)) begin
            oversample_cnt <= 0;
            if (rx_bit == 0)
              uart_rx_state <= READ_DATA;
            else
              uart_rx_state <= IDLE;
          end else begin
            oversample_cnt <= oversample_cnt + 1;
          end
        end

        READ_DATA: begin
          if (oversample_cnt == OVERSAMPLING_RATE - 1) begin
            oversample_cnt <= 0;
            rx_data <= {rx_bit, rx_data[DATA_WIDTH-1:1]};
            if (rx_bit_cnt < DATA_WIDTH-1) begin
              rx_bit_cnt <= rx_bit_cnt + 1;
            end else begin
              uart_rx_state <= STOP;
              rx_bit_cnt <= 0;
            end
          end else begin
            oversample_cnt <= oversample_cnt + 1;
          end
        end

        STOP: begin
          if (oversample_cnt == OVERSAMPLING_RATE - 1) begin
            oversample_cnt <= 0;
            if (rx_bit == 1) begin
              o_data_vld <= 1;
              uart_rx_state <= IDLE;
            end
          end else begin
            oversample_cnt <= oversample_cnt + 1;
          end
        end
      endcase
    end
  end

  always @(posedge clk) begin
    if (o_data_vld) o_rx_data <= rx_data;
  end

endmodule