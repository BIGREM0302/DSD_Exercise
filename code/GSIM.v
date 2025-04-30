module GSIM(clk, reset, in_en, b_in, out_valid, x_out);
    input               clk;
    input               reset;
    input               in_en;
    input signed [15:0] b_in;

    output        out_valid;
    output [31:0] x_out;

    localparam RECEIVE = 0;
    localparam CALC    = 1;
    localparam SEND    = 2;

    reg signed [15:0] b   [0:15];               //store offsets b1 b2... b16 16bits each
    reg signed [47:0] ans [0:15];               //store answers x1 x2... x16 32bits each

    reg        [ 1:0] state_r, state_w;
    reg        [ 3:0] cnt_r, cnt_w;             //counter to keep track of the number of iterations
    reg        [ 2:0] cnt_stage_r, cnt_stage_w; //counter to keep track of the number of stages
    reg        [ 6:0] cnt_round_r, cnt_round_w; //counter to keep track of the number of rounds
    reg signed [47:0] w1, w2, w3, w4, w5, w6;
    reg signed [47:0] r1_r, r2_r, r3_r, r4_r, r1_w, r2_w, r3_w, r4_w;

    localparam MAX_ITER  = 15; //maximum number of variables
    localparam MAX_ROUND = 69; //maximum number of iterations
    localparam MAX_STAGE = 4;

    assign out_valid = (state_r == SEND); //output valid when in SEND state
    assign x_out     = ans[cnt_r][39:8];        //output the current answer

    function signed [47:0] mul_3;
        input signed [47:0] a;
        begin
            mul_3 = a + (a << 1);
        end
    endfunction

    function signed [47:0] mul_6;
        input signed [47:0] a;
        begin
            mul_6 = mul_3(a) << 1;
        end
    endfunction

    function signed [47:0] mul_13;
        input signed [47:0] a;
        begin
            mul_13 = a + (a << 2) + (a << 3);
        end
    endfunction

    always @(*) begin
        case (cnt_r)
            0: begin
                w1 = 0;
                w2 = 0;
                w3 = 0;
                w4 = ans[1];
                w5 = ans[2];
                w6 = ans[3];
            end
            1: begin
                w1 = ans[0];
                w2 = 0;
                w3 = 0;
                w4 = ans[2];
                w5 = ans[3];
                w6 = ans[4];
            end
            2: begin
                w1 = ans[1];
                w2 = ans[0];
                w3 = 0;
                w4 = ans[3];
                w5 = ans[4];
                w6 = ans[5];
            end
            13: begin
                w1 = ans[12];
                w2 = ans[11];
                w3 = ans[10];
                w4 = ans[14];
                w5 = ans[15];
                w6 = 0;
            end
            14: begin
                w1 = ans[13];
                w2 = ans[12];
                w3 = ans[11];
                w4 = ans[15];
                w5 = 0;
                w6 = 0;
            end
            15: begin
                w1 = ans[14];
                w2 = ans[13];
                w3 = ans[12];
                w4 = 0;
                w5 = 0;
                w6 = 0;
            end
            default: begin
                w1 = ans[cnt_r-1];
                w2 = ans[cnt_r-2];
                w3 = ans[cnt_r-3];
                w4 = ans[cnt_r+1];
                w5 = ans[cnt_r+2];
                w6 = ans[cnt_r+3];
            end
        endcase
    end

    always @(*) begin
        r1_w = r1_r;
        r2_w = r2_r;
        r3_w = r3_r;
        r4_w = r4_r;

        if (state_r == CALC) begin
            case (cnt_stage_r)
                3'd0: begin
                    r1_w = w3 + w6 + {{8{b[cnt_r][15]}}, b[cnt_r], 24'd0};
                    r2_w = mul_6((w2 + w5));
                    r3_w = mul_13((w1 + w4));
                end
                3'd1: r4_w = r1_r - r2_r + r3_r;
                3'd2: r4_w = r4_r + (r4_r >>> 4);
                3'd3: r4_w = r4_r + (r4_r >>> 8);
                3'd4: r4_w = (r4_r >>> 6) + (r4_r >>> 22) + (r4_r >>> 5) + (r4_r >>> 21);
            endcase
        end
    end

    always @(posedge clk) begin
        if (state_r == CALC) begin
            r1_r <= r1_w;
            r2_r <= r2_w;
            r3_r <= r3_w;
            r4_r <= r4_w;
            if (cnt_stage_r == MAX_STAGE) begin
                ans[cnt_r] <= r4_w;
            end
        end
    end

    always @(posedge clk) begin
        if (state_r == RECEIVE && in_en) begin
            b[cnt_r]   <= b_in;
            ans[cnt_r] <= {48'd0};
        end
    end

    //FSM
    always @(*) begin
        state_w     = state_r;
        cnt_w       = cnt_r;
        cnt_stage_w = cnt_stage_r;
        cnt_round_w = cnt_round_r;

        case (state_r)
            RECEIVE: begin
                if (in_en) begin
                    if (cnt_r == 4'd15) begin
                        state_w = CALC;
                        cnt_w   = 0;
                        cnt_stage_w = 0;
                        cnt_round_w = 0;
                    end
                    else begin
                        cnt_w = cnt_r + 1;
                    end
                end
            end

            CALC: begin
                if (cnt_stage_r == MAX_STAGE) begin
                    cnt_stage_w = 0;
                    if (cnt_r == MAX_ITER) begin
                        cnt_w = 0;
                        if (cnt_round_r == MAX_ROUND) begin
                            state_w     = SEND;
                            cnt_round_w = 0;
                        end
                        else cnt_round_w = cnt_round_r + 1;
                    end
                    else cnt_w = cnt_r + 1;
                end
                else cnt_stage_w = cnt_stage_r + 1;
            end

            SEND: begin
                if (cnt_r == 4'd15) begin
                    state_w = RECEIVE;
                    cnt_w   = 0;
                end
                else begin
                    cnt_w = cnt_r + 1;
                end
            end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_r     <= RECEIVE;
            cnt_stage_r <= 0;
            cnt_round_r <= 0;
            cnt_r       <= 0;
            r1_r        <= 0;
            r2_r        <= 0;
            r3_r        <= 0;
            r4_r        <= 0;
        end
        else begin
            state_r     <= state_w;
            cnt_stage_r <= cnt_stage_w;
            cnt_round_r <= cnt_round_w;
            cnt_r       <= cnt_w;
        end
    end
endmodule
