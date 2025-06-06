module GSIM(clk, reset, in_en, b_in, out_valid, x_out);
    input               clk;
    input               reset;
    input               in_en;
    input signed [15:0] b_in;
    output              out_valid;
    output       [31:0] x_out;

    reg [1:0] state_r, state_w;

    localparam RECEIVE = 0;
    localparam CALC    = 1; //Do Gauss Seidel approximtiatin
    localparam SEND    = 2;

    reg signed [15:0] b            [0:15];   //store offsets b1 b2... b16 16bits each
    reg signed [31:0] ans          [0:15];   //store answers x1 x2... x16 32bits each

    reg signed [35:0] pipeline_r   [0:5 ];
    reg signed [35:0] pipeline_w   [0:5 ];
    reg signed [35:0] pipeline_src [0:5 ];

    reg signed [35:0] pipeline_support_1;
    reg signed [35:0] pipeline_support_2;
    reg signed [35:0] pipeline_support_3;
    reg        [11:0] cnt_r, cnt_w;
    reg        [ 3:0] mapping;

    wire [3:0] idx0 = (cnt_r[3] | cnt_r[2]) ? 4'd13 : 4'd12;
    wire [3:0] idx1 = (cnt_r[3] & cnt_r[2]) ? 4'd4 : 4'd3;
    wire [3:0] idx2 = (cnt_r[3])? 4'd9 : 4'd8 ;
    wire [3:0] idx3 = (cnt_r[3])? 4'd8 : 4'd7 ;
    wire [3:0] idx4 = (cnt_r[3] & cnt_r[2]) ? 4'd5 : 4'd4;
    wire [3:0] idx5 = (cnt_r[3] | cnt_r[2]) ? 4'd12 : 4'd11;

    localparam MAX_ITER     = 77; //maximum number of iterations
    localparam PIPELINE_MAX = (16 * MAX_ITER) - 1;

    assign out_valid = (state_r == SEND) ? 1 : 0; //output valid when in SEND state
    assign x_out = ans[mapping];

    function signed [35:0] mul_3_2;
        input signed [35:0] a;
        begin
            mul_3_2 = (a>>>2) + (a>>>1);
        end
    endfunction

    function signed [35:0] mul_18_2;
        input signed [35:0] a;
        begin
            mul_18_2 = (a<<<2) + (a>>>1);
        end
    endfunction

    function signed [35:0] mul_39_2;
        input signed [35:0] a;
        begin
            mul_39_2 = (a<<<3)  + a  + (a>>>1)  + (a>>>2);
        end
    endfunction

    //pipeline choose
    always @(*) begin
        pipeline_src[0] = {{2{ans[idx0][31]}},ans[idx0],2'sd0};  // future 3
        pipeline_src[1] = {{2{ans[idx1][31]}},ans[idx1],2'sd0};  // past 3
        pipeline_src[2] = {{2{ans[idx2][31]}},ans[idx2],2'sd0};  // future 2
        pipeline_src[3] = {{2{ans[idx3][31]}},ans[idx3],2'sd0};  // past 2
        pipeline_src[4] = {{2{ans[idx4][31]}},ans[idx4],2'sd0};  // future 1
        pipeline_src[5] = {{2{ans[idx5][31]}},ans[idx5],2'sd0};  // past 1

        case (cnt_r[3:0])  
            0: begin
                pipeline_src[1] = 0;
                pipeline_src[3] = 0;
                pipeline_src[5] = 0;
            end
            4: begin
                pipeline_src[1] = 0;
                pipeline_src[3] = 0;
            end
            7: begin
                pipeline_src[0] = 0;
            end
            8: begin
                pipeline_src[1] = 0;
            end
            11: begin
                pipeline_src[0] = 0;
                pipeline_src[2] = 0;
            end
            15: begin
                pipeline_src[0] = 0;
                pipeline_src[2] = 0;
                pipeline_src[4] = 0;
            end
        endcase
    end

    //pipeline count
    always @(*) begin

        pipeline_w[0] = mul_3_2({{2{b[mapping][15]}},b[mapping],18'sd0});
        pipeline_w[1] = mul_3_2(pipeline_src[0] + pipeline_src[1]);
        pipeline_w[2] = mul_18_2(pipeline_src[2] + pipeline_src[3]);
        pipeline_w[3] = mul_39_2(pipeline_src[4] + pipeline_src[5]);

        pipeline_support_1 = ((pipeline_r[0] - pipeline_r[2]) >>>2) + ((pipeline_r[1] + pipeline_r[3]) >>>2);
        pipeline_w[4] = pipeline_support_1 + (pipeline_support_1 >>> 4);

        pipeline_w[5] = pipeline_r[4] + (pipeline_r[4] >>> 8);

        pipeline_support_2 = pipeline_r[5] + (pipeline_r[5] >>> 16);
        pipeline_support_3 = pipeline_support_2 >>> 2;

    end

    //FSM
    always @(*) begin
        state_w = state_r;
        cnt_w   = cnt_r;

        case (state_r)
            RECEIVE: begin
                if (in_en) begin
                    if (cnt_r == 15) begin
                        state_w = CALC;
                        cnt_w   = 0;
                    end
                    else begin
                        cnt_w = cnt_r + 1;
                    end
                end
            end

            CALC: begin
                if (cnt_r == PIPELINE_MAX) begin
                    state_w = SEND;
                    cnt_w   = 0;
                end
                else begin
                    cnt_w = cnt_r + 1;
                end
            end

            SEND: begin
                if (cnt_r == 15) begin
                    state_w = RECEIVE;
                    cnt_w   = 0;
                end
                else begin
                    cnt_w = cnt_r + 1;
                end
            end
        endcase
    end

    always @(*) begin
        case (cnt_r[3:0])
            4'd0:  mapping = 4'd0;
            4'd1:  mapping = 4'd4;
            4'd2:  mapping = 4'd8;
            4'd3:  mapping = 4'd12;
            4'd4:  mapping = 4'd1;
            4'd5:  mapping = 4'd5;
            4'd6:  mapping = 4'd9;
            4'd7:  mapping = 4'd13;
            4'd8:  mapping = 4'd2;
            4'd9:  mapping = 4'd6;
            4'd10: mapping = 4'd10;
            4'd11: mapping = 4'd14;
            4'd12: mapping = 4'd3;
            4'd13: mapping = 4'd7;
            4'd14: mapping = 4'd11;
            4'd15: mapping = 4'd15;
        endcase
    end

    //b_in
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            b[0]  <= 0;
            b[1]  <= 0;
            b[2]  <= 0;
            b[3]  <= 0;
            b[4]  <= 0;
            b[5]  <= 0;
            b[6]  <= 0;
            b[7]  <= 0;
            b[8]  <= 0;
            b[9]  <= 0;
            b[10] <= 0;
            b[11] <= 0;
            b[12] <= 0;
            b[13] <= 0;
            b[14] <= 0;
            b[15] <= 0;
        end
        else begin
            if (state_r == RECEIVE && in_en) begin
                b[cnt_r] <= b_in;
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_r       <= RECEIVE;
            cnt_r         <= 0;
            pipeline_r[0] <= 0;
            pipeline_r[1] <= 0;
            pipeline_r[2] <= 0;
            pipeline_r[3] <= 0;
            pipeline_r[4] <= 0;
            pipeline_r[5] <= 0;
        end
        else begin
            state_r       <= state_w;
            cnt_r         <= cnt_w;
            pipeline_r[0] <= pipeline_w[0];
            pipeline_r[1] <= pipeline_w[1];
            pipeline_r[2] <= pipeline_w[2];
            pipeline_r[3] <= pipeline_w[3];
            pipeline_r[4] <= pipeline_w[4];
            pipeline_r[5] <= pipeline_w[5];
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ans[0]  <= 0;
            ans[1]  <= 0;
            ans[2]  <= 0;
            ans[3]  <= 0;
            ans[4]  <= 0;
            ans[5]  <= 0;
            ans[6]  <= 0;
            ans[7]  <= 0;
            ans[8]  <= 0;
            ans[9]  <= 0;
            ans[10] <= 0;
            ans[11] <= 0;
            ans[12] <= 0;
            ans[13] <= 0;
            ans[14] <= 0;
            ans[15] <= 0;
        end
        else begin
            if (state_r == CALC) begin
                ans[0]  <= ans[1];
                ans[1]  <= ans[2];
                ans[2]  <= ans[3];
                ans[3]  <= ans[4];
                ans[4]  <= ans[5];
                ans[5]  <= ans[6];
                ans[6]  <= ans[7];
                ans[7]  <= ans[8];
                ans[8]  <= ans[9];
                ans[9]  <= ans[10];
                ans[10] <= ans[11];
                ans[11] <= ans[12];
                ans[12] <= pipeline_support_3[33:2];
                ans[13] <= ans[14];
                ans[14] <= ans[15];
                ans[15] <= ans[0];
            end
        end
    end
endmodule
