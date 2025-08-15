module loopback (
    CLK,
    RST_BTN,
    UART_RX,
    SW,
    UART_TX
);
  input CLK;
  input RST_BTN;
  input UART_RX;
  input SW;
  output UART_TX;

  wire [7:0] uart_rx_data;
  wire [7:0] uart_tx_data;
  wire tx_enable;
  wire tx_busy;

  assign uart_tx_data = (SW == 1'b0) ? uart_rx_data : 8'b01000001;

  UART_TX #(
    .BAUD_RATE(9600),
    .DATA_WIDTH(8),
    .CLK_FREQ(100_000_000)
  ) uart_tx1 (
    .clk(CLK),
    .rst(RST_BTN),
    .i_txdata(uart_tx_data),
    .i_tx_enable(tx_enable),
    .o_tx(UART_TX),
    .o_busy(tx_busy)
  );

  UART_RX #(
    .BAUD_RATE(9600),
    .DATA_WIDTH(8),
    .CLK_FREQ(100_000_000),
    .OVERSAMPLING_RATE(16)
  ) uart_rx1 (
    .clk(CLK),
    .rst(RST_BTN),
    .i_rx_bit(UART_RX),
    .o_data_vld(tx_enable),
    .o_rx_data(uart_rx_data)
  );

endmodule
