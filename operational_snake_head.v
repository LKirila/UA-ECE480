module snake_head (
  input [9:0] pixel_row, pixel_column,
  input vert_sync, horz_sync,
  input reset,
  input [3:0] button,
  input clock,
  output red, green, blue,
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
  
////snake setup////////////////////////////////////////////////////////////////////////////////////
    assign led = button[0];
  wire [9:0] snake_len;
  assign snake_len = 10'd8;
  wire [9:0] snake_wid;
  assign snake_wid = 10'd8; 
  reg [9:0] snake_x_motion, snake_x_pos;
  reg [9:0] snake_y_pos, snake_y_motion;
  reg snake_on;
  reg [1:0] direction;
//  assign snake_y_pos = 10'd240;
  reg end_game = 1;
  
  //assign buttons
  always @(posedge clock or posedge reset) begin
    if(reset) direction <= 2'b10; //default: go right
    else begin
        if(button[0] && (direction != 2'b11)) begin //if up button and not going down
            direction <= 2'b00;
        end
        else if (button[1] && (direction != 2'b10)) begin //if left button and not going right
            direction <= 2'b01;
        end
        else if (button[2] && (direction != 2'b01)) begin //if right button and not going left
            direction <= 2'b10;
        end
        else if (button[3] && (direction != 2'b00)) begin //if down button and not going up
            direction <= 2'b11;
        end
    end
  end
  
  // generate motion and vertical position of the ball
  always @ (posedge vert_sync or posedge reset) begin //vert_sync is inversed so posedge is when not in sync
      if(reset)begin 
        snake_x_pos <= 10'd12;
        snake_y_pos <= 10'd240;
        end_game <= 1'b1;
      end
      else if(end_game == 1'b1) begin
          if (snake_x_pos >= (630)) begin //hits right edge
              snake_x_motion <= 10'd0;
              end_game <= 1'b0;          
          end 
          else if (direction == 2'b10) begin //move right
              snake_x_motion <= 10'd2;
              snake_y_motion <= 10'd0;
          end
          else if (direction == 2'b01) begin //move left
              snake_x_motion <= -10'd2;
              snake_y_motion <= 10'd0;
          end        
          if (snake_y_pos >= (10'd470) || snake_y_pos <= 10'd8) begin //hits top or bottom
              snake_y_motion <= 10'd0;
              end_game <= 1'b0;          
          end 
          else if (direction == 2'b00) begin //move up
              snake_y_motion <= -10'd2;
              snake_x_motion <= 10'd0;
          end
          else if (direction == 2'b11) begin //move down
              snake_y_motion <= 10'd2;
              snake_x_motion <= 10'd0;
          end
        snake_x_pos <= snake_x_pos + snake_x_motion;
        snake_y_pos <= snake_y_pos + snake_y_motion;
        end
  end

  // based on the current pixels and the current position of the snake, determine whether you should show the snake or the background
  always @ (*) begin
//    if(snake_x_pos <= 10'd12) flag = 1'b1;
    if ((snake_x_pos <= (pixel_column + snake_wid)) && (snake_x_pos >= pixel_column) && (snake_y_pos <= (pixel_row + snake_len)) && ((snake_y_pos) >= pixel_row)) begin
      snake_on = 1'b1;
    end else begin
      snake_on = 1'b0;
    end
  end
  
  // show snake where it should be and disappear when the game ends
  assign green = (snake_on) ? 1'b1 : 1'b0;
  
  //border//////////////////////////////////////////////////////////
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
