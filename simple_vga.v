module simple_vga (
//  input CLK100MHZ,
  input clk,
  input [2:0] SW, 
  input [3:0] BTN,
  output [3:0] LED,
  //[2]: color display, stays on; [1]: direction; [0]: game reset
  output [3:0] VGA_RED, VGA_GREEN, VGA_BLUE,
  output VGA_HS, VGA_VS
);

  wire red_sig_out, blue_sig_out, green_sig_out;
  wire red_out, blue_out, green_out;
  wire [9:0] h_count, v_count;
  wire vert_sync;
  wire horz_sync;
  assign reset = SW[0];
//  wire BTNU, BTND, BTNL, BTNR;
  assign BTNU = BTN[0];
  assign BTNL = BTN[1];
  assign BTNR = BTN[2];
  assign BTND = BTN[3];
  wire [3:0] button;
  assign button = {BTND, BTNR, BTNL, BTNU};

  wire led0;
//    assign LED[0] = button[0];
//    assign LED[1] = button[1];
//    assign LED[2] = !(BTNR);
//    assign LED[3] = !(BTND);

  // generate a 25 MHz clock from the board oscillator
  ip_clk_gen clock_25M_gen (
    .clk_out1(clk_25M),
    .clk_in1(clk)
  );

  // instantiate the vga_sync module to control the VGA protocol
  vga_sync vga_sync_inst (
    .clock_25mhz(clk_25M),
    .red(red_out),
    .green(green_out),
    .blue(blue_out),
    .red_out(red_sig_out),
    .blue_out(blue_sig_out),
    .green_out(green_sig_out),
    .horiz_sync_out(horz_sync),
    .vert_sync_out(vert_sync),
    .h_count(h_count),
    .v_count(v_count)
//    .reset(reset)
  );

snake_head snake_head_inst(
  .pixel_row(v_count), 
  .pixel_column(h_count),
  .vert_sync(vert_sync),
  .button(button),
  .red(red_out), 
  .green(green_out), 
  .blue(blue_out),
  .reset(reset),
  .clock(clk_25M),
  .led(led0)
);

//part1 part1_inst(
//  .pixel_row(v_count), 
//  .pixel_column(h_count),
//  .vert_sync(vert_sync),
//  .red(red_out), 
//  .green(green_out), 
//  .blue(blue_out),
//  .reset(reset)
//);
  assign VGA_RED = {4{red_sig_out}};
  assign VGA_BLUE = {4{blue_sig_out}};
  assign VGA_GREEN = {4{green_sig_out}};
  assign VGA_VS = vert_sync;
  assign VGA_HS = horz_sync;
  assign LED[0] = led0;

endmodule
