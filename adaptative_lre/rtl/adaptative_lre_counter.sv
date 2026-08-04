module adaptative_lre_counter #(
    parameter   NB_DATA   = 8,
    parameter   NB_COUNT  = 8
) (
    // Output
    output wire [NB_DATA -1:0] o_data      ,
    output wire [NB_COUNT-1:0] o_count     ,
    output wire                o_valid     ,
    output wire                o_end_count ,

    //Input
    input  wire [NB_DATA -1:0] i_data      ,
    input  wire                i_valid     ,
    input  wire                i_last      ,
    input  wire                i_mode      ,
    input  wire                i_start_mode,

    // Clock and reset
    input  wire                i_clock     ,
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

    // ---------------------------------------
    // ---  Control logic                  ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            first_start <= 1'b0;
        end else if (i_start_mode) begin
            first_start <= 1'b1;
        end
    end

    assign start         =  first_start & i_start_mode;
    assign start_run     = i_start_mode & i_mode      ;
    assign start_literal = i_start_mode & ~i_mode     ;
    assign end_count = start  | limit_count| i_last   ;

    // ---------------------------------------
    // ---  Count Logic                    ---
    // ---------------------------------------

    assign incr_sel   = i_mode ? 1 : -1;
    assign next_count = count + incr_sel;

    assign max_count   =  (~next_count[NB_COUNT-1]) & (&next_count[NB_COUNT-2:0]);
    assign min_count   =  ( next_count[NB_COUNT-1]) & (~(|next_count[NB_COUNT-2:0]));
    assign limit_count = i_valid & (max_count | min_count);

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            count <= 0;
        end else if (start_run) begin
            count <= 1;
        end else if(start_literal) begin
            count <= -1;
        end else if(i_valid)begin
            count <= next_count;
        end
    end

    // ---------------------------------------
    // ---  Output Registers               ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            count_d <= 0;
        end if (end_count) begin
            count_d <= count;
        end
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            data_sr     <= 0;
            valid_sr    <= 0;
            end_count_d <= 0;
        end if(i_valid) begin
            data_sr     <= {data_sr[0] , i_data};
            valid_sr    <= {valid_sr[0],   1'b1};
            end_count_d <= end_count;
        end
    end

    // ---------------------------------------
    // ---  Output Assign                  ---
    // ---------------------------------------

    assign o_data       = data_sr[1];
    assign o_count      = count_d;
    assign o_valid      = valid_sr[1] &  i_valid;
    assign o_end_count  = end_count_d & i_valid;

endmodule