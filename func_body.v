module snake_head (
  input [9:0] pixel_row, pixel_column,
  input vert_sync, horz_sync,
  input reset,
  input [3:0] button,
  input clock,
  output red, blue,
  output green,
  output led
);
  //apple setup
  wire [9:0] apple_size, apple_x_pos, apple_y_pos;
  reg apple_on;
  // fix the size and  position
  assign apple_size = 10'd8;
  assign apple_x_pos = 10'd160;
  assign apple_y_pos = 10'd160;
  
  always @(*) begin
    if ((apple_x_pos <= (pixel_column + apple_size)) && (apple_x_pos >= pixel_column) && (apple_y_pos <= (pixel_row + apple_size)) && ((apple_y_pos) >= pixel_row)) begin
      apple_on = 1'b1;
    end else begin
      apple_on = 1'b0;
      end
  end
  // only if showing apple display red
  assign red = (apple_on) ? 1'b1 : 1'b0;
  
/////////////////////snake head////////////////////////////////////////////////////////////////////////////////////
  assign led = button[0];
  wire [9:0] size;
  assign size = 10'd8;
  reg [9:0] len;
  integer i;
  reg [9:0] snake_x_motion[0:31]; //must have own motion for turn
  reg [9:0] snake_y_motion[0:31];
  reg [9:0] snake_x_pos[0:31]; //each indices will have an x and y position
  reg [9:0] snake_y_pos[0:31];
  reg [9:0] corner_x, corner_y;
  reg snake_on;
  reg [1:0] direction, temp_dir;
  reg end_game = 1;
  reg btn_press_y = 0; //may need to be a reg to hold the value
  reg btn_press_x = 0; //may need to be a reg to hold the value
  reg btn_press_x_set, btn_press_x_clr, btn_press_y_set, btn_press_y_clr;
  assign btn_press = button[0] || button[1] || button[2] || button[3]; //if a button is pressed, btn_press flag goes high
  always @(*) begin
    if(btn_press_x_set) btn_press_x <= 1;    
    else if(btn_press_x_clr) btn_press_x <= 0;
  end
  always @(*) begin
    if(btn_press_y_set) btn_press_y <= 1;
    else if(btn_press_y_clr) btn_press_y <= 0;
  end
  //assign buttons
  always @(posedge clock or posedge reset) begin
    if(reset) begin
        direction <= 2'b10; //default: go right
        btn_press_x_set <= 0;
        btn_press_y_set <= 0;
        corner_x <= snake_x_pos[0];
        corner_y <= snake_y_pos[0];
    end
    else begin
        if(button[0] && (direction != 2'b11)) begin //if up button and not going down
            temp_dir <= direction; //hold direction to maintain until corner
            direction <= 2'b00;
            btn_press_y_set <= 1;
            corner_x <= snake_x_pos[0];
            corner_y <= snake_y_pos[0];
        end
        else if (button[1] && (direction != 2'b10)) begin //if left button and not going right
            temp_dir <= direction;
            direction <= 2'b01;
            btn_press_x_set <= 1;
            corner_x <= snake_x_pos[0];
            corner_y <= snake_y_pos[0];
        end
        else if (button[2] && (direction != 2'b01)) begin //if right button and not going left
            temp_dir <= direction;
            direction <= 2'b10;
            btn_press_x_set <= 1;
            corner_x <= snake_x_pos[0];
            corner_y <= snake_y_pos[0];
        end
        else if (button[3] && (direction != 2'b00)) begin //if down button and not going up
            temp_dir <= direction;
            direction <= 2'b11;
            btn_press_y_set <= 1;
            corner_x <= snake_x_pos[0];
            corner_y <= snake_y_pos[0];
        end
        else begin
            btn_press_x_set <= 0;
            btn_press_y_set <= 0;
        end
    end
  end
  integer temp_pos;
  // generate motion and vertical position of the ball
  always @ (posedge vert_sync or posedge reset) begin //vert_sync is inversed so posedge is when not in sync
      if(reset)begin 
        end_game <= 1'b1;
        len = 4; //start with 4 indices
        btn_press_x_clr <= 0;
        btn_press_y_clr <= 0;
        for(i = 0; i < len; i = i + 1) begin 
            temp_pos = i * size;
            snake_x_pos[i] <= 10'd44 - temp_pos; //set start positions
            snake_y_pos[i] <= 10'd240;
        end
      end
      else if(end_game == 1'b1) begin //if not paused
          for(i = 0; i < len; i = i + 1) begin
            if(btn_press_x == 1) begin //if left or right btn, move head asap and maintain other direction until pos == corner
                    if(snake_y_pos[i] == corner_y) begin // if at corner, turn appropriately
                        if (snake_x_pos[i] >= (630)) begin //hits right edge
                            snake_x_motion[i] <= 10'd0;
                            end_game <= 1'b0;          
                        end 
                        else if (direction == 2'b10) begin //move right
                            snake_x_motion[i] <= 10'd2;
                            snake_y_motion[i] <= 10'd0;
                        end
                        else if (direction == 2'b01) begin //move left
                            snake_x_motion[i] <= -10'd2;
                            snake_y_motion[i] <= 10'd0;
                        end  
                        snake_x_pos[i] <= snake_x_pos[i] + snake_x_motion[i];  
                        if(i == len - 1) begin
                            btn_press_x_clr <= 1;
                        end
                    end //corner
                    else begin //otherwise, keep moving up or down until hit corner
                        if (snake_y_pos[i] >= (10'd470) || snake_y_pos[i] <= 10'd8) begin //hits top or bottom
                            snake_y_motion[i] <= 10'd0;
                            end_game <= 1'b0;          
                        end 
                        else if (temp_dir == 2'b00) begin //move up
                            snake_y_motion[i] <= -10'd2;
                            snake_x_motion[i] <= 10'd0;
                        end
                        else if (temp_dir == 2'b11) begin //move down
                            snake_y_motion[i] <= 10'd2;
                            snake_x_motion[i] <= 10'd0;
                        end
                        snake_y_pos[i] <= snake_y_pos[i] + snake_y_motion[i];
                    end //not corner
            end //btn_x
            else if (btn_press_y == 1) begin //if going horiz and up or down is pressed
                    if(snake_x_pos[i] == corner_x) begin // if at corner, turn appropriately
                        if (snake_y_pos[i] >= (10'd470) || snake_y_pos[i] <= 10'd8) begin //hits top or bottom
                            snake_y_motion[i] <= 10'd0;
                            end_game <= 1'b0;          
                        end 
                        else if (direction == 2'b00) begin //move up
                            snake_y_motion[i] <= -10'd2;
                            snake_x_motion[i] <= 10'd0;
                        end
                        else if (direction == 2'b11) begin //move down
                            snake_y_motion[i] <= 10'd2;
                            snake_x_motion[i] <= 10'd0;
                        end 
                        snake_y_pos[i] <= snake_y_pos[i] + snake_y_motion[i];  
                        if(i == len - 1) begin
                            btn_press_y_clr <= 1;
                        end
                    end //corner
                    else begin //keep moving until corner
                        if (snake_x_pos[i] >= (630)) begin //hits right edge
                            snake_x_motion[i] <= 10'd0;
                            end_game <= 1'b0;          
                        end 
                        else if (temp_dir == 2'b10) begin //move right
                            snake_x_motion[i] <= 10'd2;
                            snake_y_motion[i] <= 10'd0;
                        end
                        else if (temp_dir == 2'b01) begin //move left
                            snake_x_motion[i] <= -10'd2;
                            snake_y_motion[i] <= 10'd0;
                        end   
                        snake_x_pos[i] <= snake_x_pos[i] + snake_x_motion[i];
                    end //maintain dir
            end //btn_y
            else begin
                  if (snake_x_pos[i] >= (630)) begin //hits right edge
                      snake_x_motion[i] <= 10'd0;
                      end_game <= 1'b0;          
                  end 
                  else if (direction == 2'b10) begin //move right
                      snake_x_motion[i] <= 10'd2;
                      snake_y_motion[i] <= 10'd0;
                  end
                  else if (direction == 2'b01) begin //move left
                      snake_x_motion[i] <= -10'd2;
                      snake_y_motion[i] <= 10'd0;
                  end        
                  if (snake_y_pos[i] >= (10'd470) || snake_y_pos[i] <= 10'd8) begin //hits top or bottom
                      snake_y_motion[i] <= 10'd0;
                      end_game <= 1'b0;          
                  end 
                  else if (direction == 2'b00) begin //move up
                      snake_y_motion[i] <= -10'd2;
                      snake_x_motion[i] <= 10'd0;
                  end
                  else if (direction == 2'b11) begin //move down
                      snake_y_motion[i] <= 10'd2;
                      snake_x_motion[i] <= 10'd0;
                  end
                snake_x_pos[i] <= snake_x_pos[i] + snake_x_motion[i];
                snake_y_pos[i] <= snake_y_pos[i] + snake_y_motion[i];
            end //else
        end //for
    end //endgame
  end //always

  // based on the current pixels and the current position of the snake, determine whether you should show the snake or the background
  // not the most efficient but it'll do
  always @ (*) begin
    if ((snake_x_pos[0] <= (pixel_column + size)) && (snake_x_pos[0] >= pixel_column) && (snake_y_pos[0] <= (pixel_row + size)) && ((snake_y_pos[0]) >= pixel_row)) begin
        snake_on = 1'b1;
    end else if ((snake_x_pos[1] <= (pixel_column + size)) && (snake_x_pos[1] >= pixel_column) && (snake_y_pos[1] <= (pixel_row + size)) && ((snake_y_pos[1]) >= pixel_row)) begin
        snake_on = 1'b1;
    end else if ((snake_x_pos[2] <= (pixel_column + size)) && (snake_x_pos[2] >= pixel_column) && (snake_y_pos[2] <= (pixel_row + size)) && ((snake_y_pos[2]) >= pixel_row)) begin
        snake_on = 1'b1; 
    end else if ((snake_x_pos[3] <= (pixel_column + size)) && (snake_x_pos[3] >= pixel_column) && (snake_y_pos[3] <= (pixel_row + size)) && ((snake_y_pos[3]) >= pixel_row)) begin
        snake_on = 1'b1;
    end else if ((snake_x_pos[4] <= (pixel_column + size)) && (snake_x_pos[4] >= pixel_column) && (snake_y_pos[4] <= (pixel_row + size)) && ((snake_y_pos[4]) >= pixel_row)) begin
        snake_on = 1'b1;              
    end else if ((snake_x_pos[5] <= (pixel_column + size)) && (snake_x_pos[5] >= pixel_column) && (snake_y_pos[5] <= (pixel_row + size)) && ((snake_y_pos[5]) >= pixel_row)) begin
        snake_on = 1'b1;
    end else if ((snake_x_pos[6] <= (pixel_column + size)) && (snake_x_pos[6] >= pixel_column) && (snake_y_pos[6] <= (pixel_row + size)) && ((snake_y_pos[6]) >= pixel_row)) begin
        snake_on = 1'b1; 
    end else if ((snake_x_pos[7] <= (pixel_column + size)) && (snake_x_pos[7] >= pixel_column) && (snake_y_pos[7] <= (pixel_row + size)) && ((snake_y_pos[7]) >= pixel_row)) begin
        snake_on = 1'b1;
    end else if ((snake_x_pos[8] <= (pixel_column + size)) && (snake_x_pos[8] >= pixel_column) && (snake_y_pos[8] <= (pixel_row + size)) && ((snake_y_pos[8]) >= pixel_row)) begin
        snake_on = 1'b1;
    end else if ((snake_x_pos[9] <= (pixel_column + size)) && (snake_x_pos[9] >= pixel_column) && (snake_y_pos[9] <= (pixel_row + size)) && ((snake_y_pos[9]) >= pixel_row)) begin
        snake_on = 1'b1;
    end else if ((snake_x_pos[10] <= (pixel_column + size)) && (snake_x_pos[10] >= pixel_column) && (snake_y_pos[10] <= (pixel_row + size)) && ((snake_y_pos[10]) >= pixel_row)) begin
        snake_on = 1'b1; 
//    end else if ((snake_x_pos[11] <= (pixel_column + size)) && (snake_x_pos[11] >= pixel_column) && (snake_y_pos[11] <= (pixel_row + size)) && ((snake_y_pos[11]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[12] <= (pixel_column + size)) && (snake_x_pos[12] >= pixel_column) && (snake_y_pos[12] <= (pixel_row + size)) && ((snake_y_pos[12]) >= pixel_row)) begin
//        snake_on = 1'b1;              
//    end else if ((snake_x_pos[13] <= (pixel_column + size)) && (snake_x_pos[13] >= pixel_column) && (snake_y_pos[13] <= (pixel_row + size)) && ((snake_y_pos[13]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[14] <= (pixel_column + size)) && (snake_x_pos[14] >= pixel_column) && (snake_y_pos[14] <= (pixel_row + size)) && ((snake_y_pos[14]) >= pixel_row)) begin
//        snake_on = 1'b1; 
//    end else if ((snake_x_pos[15] <= (pixel_column + size)) && (snake_x_pos[15] >= pixel_column) && (snake_y_pos[15] <= (pixel_row + size)) && ((snake_y_pos[15]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[16] <= (pixel_column + size)) && (snake_x_pos[16] >= pixel_column) && (snake_y_pos[16] <= (pixel_row + size)) && ((snake_y_pos[16]) >= pixel_row)) begin
//        snake_on = 1'b1;            
//    end else if ((snake_x_pos[17] <= (pixel_column + size)) && (snake_x_pos[17] >= pixel_column) && (snake_y_pos[17] <= (pixel_row + size)) && ((snake_y_pos[17]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[18] <= (pixel_column + size)) && (snake_x_pos[18] >= pixel_column) && (snake_y_pos[18] <= (pixel_row + size)) && ((snake_y_pos[18]) >= pixel_row)) begin
//        snake_on = 1'b1; 
//    end else if ((snake_x_pos[19] <= (pixel_column + size)) && (snake_x_pos[19] >= pixel_column) && (snake_y_pos[19] <= (pixel_row + size)) && ((snake_y_pos[19]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[20] <= (pixel_column + size)) && (snake_x_pos[20] >= pixel_column) && (snake_y_pos[20] <= (pixel_row + size)) && ((snake_y_pos[20]) >= pixel_row)) begin
//        snake_on = 1'b1;              
//    end else if ((snake_x_pos[21] <= (pixel_column + size)) && (snake_x_pos[21] >= pixel_column) && (snake_y_pos[21] <= (pixel_row + size)) && ((snake_y_pos[21]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[22] <= (pixel_column + size)) && (snake_x_pos[22] >= pixel_column) && (snake_y_pos[22] <= (pixel_row + size)) && ((snake_y_pos[22]) >= pixel_row)) begin
//        snake_on = 1'b1; 
//    end else if ((snake_x_pos[23] <= (pixel_column + size)) && (snake_x_pos[23] >= pixel_column) && (snake_y_pos[23] <= (pixel_row + size)) && ((snake_y_pos[23]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[24] <= (pixel_column + size)) && (snake_x_pos[24] >= pixel_column) && (snake_y_pos[24] <= (pixel_row + size)) && ((snake_y_pos[24]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[25] <= (pixel_column + size)) && (snake_x_pos[25] >= pixel_column) && (snake_y_pos[25] <= (pixel_row + size)) && ((snake_y_pos[25]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[26] <= (pixel_column + size)) && (snake_x_pos[26] >= pixel_column) && (snake_y_pos[26] <= (pixel_row + size)) && ((snake_y_pos[26]) >= pixel_row)) begin
//        snake_on = 1'b1; 
//    end else if ((snake_x_pos[27] <= (pixel_column + size)) && (snake_x_pos[27] >= pixel_column) && (snake_y_pos[27] <= (pixel_row + size)) && ((snake_y_pos[27]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[28] <= (pixel_column + size)) && (snake_x_pos[28] >= pixel_column) && (snake_y_pos[28] <= (pixel_row + size)) && ((snake_y_pos[28]) >= pixel_row)) begin
//        snake_on = 1'b1;              
//    end else if ((snake_x_pos[29] <= (pixel_column + size)) && (snake_x_pos[29] >= pixel_column) && (snake_y_pos[29] <= (pixel_row + size)) && ((snake_y_pos[29]) >= pixel_row)) begin
//        snake_on = 1'b1;
//    end else if ((snake_x_pos[30] <= (pixel_column + size)) && (snake_x_pos[30] >= pixel_column) && (snake_y_pos[30] <= (pixel_row + size)) && ((snake_y_pos[30]) >= pixel_row)) begin
//        snake_on = 1'b1; 
//    end else if ((snake_x_pos[31] <= (pixel_column + size)) && (snake_x_pos[31] >= pixel_column) && (snake_y_pos[31] <= (pixel_row + size)) && ((snake_y_pos[31]) >= pixel_row)) begin
//        snake_on = 1'b1;   
    end else begin
        snake_on = 1'b0;
    end
  end
  
  // show snake where it should be and disappear when the game ends
  assign green = (snake_on) ? 1'b1 : 1'b0;
  
  ///////////////////border//////////////////////////////////////////////////////////
  reg border_on;
  wire [9:0] left;
  wire [9:0] right;
  wire [9:0] top;
  wire [9:0] bottom;
  assign left = 10'd12;
  assign right = 10'd632;
  assign top = 10'd8;
  assign bottom = 10'd472;
    always @ (*) begin
    if(pixel_column <= left || pixel_column >= right || pixel_row <= top || pixel_row >= bottom) begin  
      border_on = 1'b1;
    end else begin
      border_on = 1'b0;
    end
  end
  assign blue = (border_on) ? 1'b1 : 1'b0;

endmodule
