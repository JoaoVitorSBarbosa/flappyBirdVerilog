// synthesis VERILOG_INPUT_VERSION SYSTEMVERILOG_2005
module main(
	input MAX10_CLK1_50,
	input [1:0] KEY,
	input [9:0] SW,
	output [7:0] HEX0,
	output [1:0] VGA_B,
	output [2:0] VGA_G,
	output [2:0] VGA_R,
	output VGA_HS,
	output VGA_VS
	);

wire an;


//enabling & debouncing
reg jump;
reg enable;
initial enable = 0;
reg enable_d;
initial enable_d = 0;
always @ (posedge bird_clk)
	if(~SW[0] && !enable_d && state == 2)
	begin
		enable <= !enable;
	end
	else if (state != 2)
		enable <= 0;
		
always @ (posedge bird_clk)
begin
	enable_d <= ~SW[0];
	jump <= ~KEY[0];
end

// 7-segment clock interconnect
wire segclk;

// VGA display clock interconnect
wire dclk;

// disable the 7-segment decimal points
assign HEX0[7] = 1;

//bird stuff
wire [10:0] bird_coord;
wire bird_clk, pixel_tick;

//pipe stuff
wire [7:0] random;
reg [7:0] pipe_array0;
initial pipe_array0 <= 100;
reg [7:0] pipe_array1;

//game state
reg [1:0] state; //00-lost 01-reset 02-start
initial state = 1;
always @ (posedge bird_clk)
begin
	if(state == 2)
	begin
		if(284 > (784-pipe_pos-345) && 244 < (784-pipe_pos+50-345)) //hc
			if((480-bird_coord)-20 < pipe_array0+75 || (480-bird_coord)+20 > pipe_array0+215) //vc
				state <= 0;
		else if(bird_coord == 0)
			state <= 0;
		if(current_score > high_score)
			high_score <= current_score;
	end
	else if( !state && ~SW[1])
	begin
		state <= 1;
	end
	else if(jump && state==1)
		state <= 2;
end

reg [17:0] pos;
initial pos = 0;
always @ (posedge dclk)
begin
		pos <= pos + 1;
end

reg [9:0] pipe_pos;
initial pipe_pos = 0;
always @ (posedge pos[17])
begin
	if(!enable && state == 2 && pipe_pos < 345)
		pipe_pos <= pipe_pos+1;
	else if(!enable && state == 2)
	begin
		pipe_pos <= 0;
		pipe_array0 <= pipe_array1;
		pipe_array1 <= random;
		current_score <= current_score + 1;
	end
	if(state == 1)
	begin
		pipe_pos <= 0;
		current_score <= 0;
		pipe_array0 <= 100;
	end
end

//scorekeeping
reg [3:0] current_score;
reg [3:0] high_score;
initial current_score = 0;
initial high_score = 0;
reg [11:0] rgb_reg;
wire [11:0] rgb_next;

// generate 7-segment clock & display clock
clockdiv U1(
	.clk(MAX10_CLK1_50),
	.clr(~KEY[1]),
	.segclk(segclk),
	.dclk(dclk),
	.bird_clk(bird_clk)
	);

// 7-segment display controller
segdisplay U2(
	.score(high_score),
	.segclk(segclk),
	.clr(~KEY[1]),
	.seg(HEX0[6:0]),
	.an(an)
	);

// VGA controller
vga640x480 U3(
	.bird_coord(bird_coord),
	.pipe_pos(pipe_pos),
	.pipe_array0(pipe_array0),
	.pipe_array1(pipe_array1),
	.current_score(current_score),
	.dclk(MAX10_CLK1_50),
	.clr(~KEY[1]),
	.hsync(VGA_HS),
	.vsync(VGA_VS),
	.red(rgb_next[11:8]),
	.green(rgb_next[7:4]),
	.blue(rgb_next[3:0]),
	.p_tick(pixel_tick)
	);
	
bird flappy(
	.clk(bird_clk),
	.enable(!enable),
	.jump(jump),
	.state(state),
	.fall_accel(1),
	.y_coord(bird_coord)
);

RNG pipe_gen(
		.clk(MAX10_CLK1_50),
		.out(random)
	);

	always@(posedge MAX10_CLK1_50)
		if(pixel_tick)
			rgb_reg <= rgb_next;
	// output
	assign {VGA_R, VGA_G, VGA_B} = rgb_reg;

endmodule