`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);
input   clk ;
input   reset ;
input   in_en;
output  out_valid;
input   [15:0]  b_in;
output  [31:0]  x_out;

reg [1:0] state_r, state_w;
localparam IDLE = 0;
localparam RECEIVE = 1;
localparam CALC = 2; //Do Gauss Seidel approximtiatin
localparam SEND = 3;

assign state_w == ()

reg [255:0] b; //store offsets b1 b2... b16 16bits each
reg [31:0] ans [0:15]; //store answers x1 x2... x16 32bits each

//FSM
always@(*)begin

end



always@(posedge clk or posedge reset)begin
    if(reset)begin
        state_r <= IDLE;
    end
    else begin
        if(ien) begin
            b <= {b[]};
        end
    end
end

endmodule