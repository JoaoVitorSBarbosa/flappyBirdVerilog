module pipes(clk, enable, pos, pipe_array
    );
	input clk;
	input enable;
	input pos;
	output reg [2:0] pipe_array [3:0];
	
	reg [7:0] random;
	
	RNG pipe_gen(
		.clk(clk),
		.rst(rst),
		.pos(pos),
		.out(random)
	);
	
	always @ (posedge clk)
		if(&pos && enable)
		begin
			pipe_array[3:1] <= pipe_array[2:0];
			pipe_array[0] <= random[2:0];
		end

endmodule