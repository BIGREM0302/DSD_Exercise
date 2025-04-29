`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);
input   clk ;
input   reset ;
input   in_en;
output out_valid;
input   [15:0]  b_in;
output reg [31:0]  x_out;

reg [1:0] state_r, state_w;
localparam RECEIVE = 0;
localparam CALC = 1; //Do Gauss Seidel approximtiatin
localparam SEND = 2;

reg [15:0] b [0:15]; //store offsets b1 b2... b16 16bits each
reg [31:0] ans [0:15]; //store answers x1 x2... x16 32bits each
reg [3:0] cnt_r, cnt_w; //counter to keep track of the number of iterations

localparam MAX_ITER = 16; //maximum number of iterations

assign out_valid = (state_r == SEND) ? 1 : 0; //output valid when in SEND state


//FSM
always@(*)begin
    
    state_w = state_r;
    cnt_w = cnt_r;

    case(state_r)

        RECEIVE: begin
            if(in_en) begin
                if (cnt_r == 4'd15) begin
                    state_w = CALC;
                    cnt_w = 0;
                end

                else begin
                    cnt_w = cnt_r + 1;
                end
            end
        end

        CALC: begin
            if(cnt_r == MAX_ITER) begin
                state_w = SEND;
                cnt_w = 0;
            end

            else begin
                cnt_w = cnt_r + 1;
            end
        end

        SEND: begin
            if(cnt_r == 4'd15) begin
                state_w = RECEIVE;
                cnt_w = 0;
            end

            else begin
                cnt_w = cnt_r + 1;
            end
        end
    endcase
end

//b_in
always @(posedge clk) begin
    if (state_r == RECEIVE && ien) begin
        b[cnt_r] <= b_in;
    end
end

//x_out
always @(posedge clk) begin
    if (state_r == SEND) begin
        x_out <= ans[cnt_w];
    end
end


always@(posedge clk or posedge reset)begin
    if(reset)begin
        state_r <= IDLE;
        cnt_r <= 0;
    end
    else begin
        cnt_r <= cnt_w;
        state_r <= state_w;
    end
end

endmodule