module adaptive_rle_counter #(
    parameter   NB_DATA   = 8,
    parameter   NB_COUNT  = 8
) (
    // Output
    output wire [NB_DATA -1:0] o_data        ,
    output wire [NB_COUNT-1:0] o_marker      ,
    output wire                o_valid       ,
    output wire                o_marker_valid,
    output wire                o_last        ,

    // Input
    input  wire [NB_DATA -1:0] i_data        ,
    input  wire                i_valid       ,
    input  wire                i_last        ,
    input  wire                i_mode        ,
    input  wire                i_start       ,

    // Clock and reset
    input  wire                i_clock       ,
    input  wire                i_reset_n
);

    localparam N_STAGE = 2;

    // Control signals
    wire                                start_run    ;
    wire                                start_literal;
    wire                                start        ;
    wire                                end_count    ;
    reg                                 first_start  ;

    // Counter signals
    reg  signed         [NB_COUNT-1:0]  count        ;
    wire signed         [NB_COUNT-1:0]  next_count   ;
    wire signed         [NB_COUNT-1:0]  incr_sel     ;
    wire                                min_count    ;
    wire                                max_count    ;
    wire                                limit_count  ;

    // Output registers
    reg [N_STAGE -1:0]  [NB_DATA -1:0]  data_sr      ;
    reg [N_STAGE -1:0]                  valid_sr     ;
    reg [NB_COUNT-1:0]                  count_d      ;
    reg                                 end_count_d  ;
    reg                                 filter_valid ;
    wire                                valid_sel    ;

    // Control signals
    reg  [N_STAGE -1:0]                 last_sr      ;
    reg                                 last_ext     ;
    wire                                last_filter  ;
    wire                                valid_ext    ;

    // ---------------------------------------
    // ---  Last control                   ---
    // ---------------------------------------
    assign last_filter = i_last & i_valid;

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            last_sr <= 0;
        end else begin
            last_sr <= {last_sr[0], last_filter };
        end
    end

    assign last_ext  = |last_sr;
    assign valid_ext =  i_valid | last_ext;


    // ---------------------------------------
    // ---  Start logic                    ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n ) begin
            first_start <= 1'b0;
        end else if(last_sr[1]) begin
            first_start <= 1'b0;
        end else if (i_start     ) begin
            first_start <= 1'b1;
        end 
    end

    assign start         =  first_start & i_start     ;
    assign start_run     = i_start      & i_mode      ;
    assign start_literal = i_start      & ~i_mode     ;
    assign end_count     = start  | limit_count | last_sr[0] ;

    // ---------------------------------------
    // ---  Count Logic                    ---
    // ---------------------------------------

    assign incr_sel   = i_mode ? 1 : -1;
    assign next_count = count + incr_sel;

    assign max_count   =  (~next_count[NB_COUNT-1]) & (&next_count[NB_COUNT-2:0]);
    assign min_count   =  ( next_count[NB_COUNT-1]) & (~(|next_count[NB_COUNT-2:0]));
    assign limit_count = valid_ext & (max_count | min_count);

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            count <= 0;
        end else if (start_run | (max_count & valid_ext)) begin
            count <= 1;
        end else if(start_literal | (min_count & valid_ext)) begin
            count <= -1;
        end else if(valid_ext)begin
            count <= next_count;
        end
    end

    // ---------------------------------------
    // ---  Output Registers               ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            data_sr     <= 0;
            valid_sr    <= 0;
            end_count_d <= 0;
        end else if(valid_ext) begin
            data_sr     <= {data_sr[0] , i_data};
            valid_sr    <= {valid_sr[0],   1'b1};
            end_count_d <= end_count;
        end
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            count_d <= 0;
    end else if (end_count) begin
            count_d <= count;
        end
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            filter_valid <= 0;
        end else if (end_count_d | (i_start & (~first_start))) begin
            filter_valid <= i_mode;
        end
    end

    // ---------------------------------------
    // ---  Output Assign                  ---
    // ---------------------------------------
    assign valid_sel      = filter_valid? end_count_d : valid_sr[1];

    assign o_data         = data_sr[1]             ;
    assign o_marker       = count_d                ;
    assign o_valid        = valid_sel & valid_ext  ;
    assign o_marker_valid = end_count_d & valid_ext;
    assign o_last         = last_sr[1]             ;

endmodule