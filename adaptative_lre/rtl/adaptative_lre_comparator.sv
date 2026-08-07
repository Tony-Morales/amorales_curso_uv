module adaptative_lre_comparator #(
    parameter NB_DATA   = 8
) (
    // Outputs
    output wire [NB_DATA -1:0] o_data      ,
    output wire                o_valid     ,
    output wire                o_mode      ,
    output wire                o_start     ,

    // Inputs
    input  wire [NB_DATA -1:0] i_data      ,
    input  wire                i_valid     ,
    input  wire                i_last      ,

    // Clock and reset
    input  wire                i_clock     ,
    input  wire                i_reset_n
);
    localparam N_STAGE = 2;


    // Buffer registers
    reg  [NB_DATA -1:0] ref_data  ;
    reg  [NB_DATA -1:0] ref_data_d;
    reg  [N_STAGE -1:0] valid_sr  ;

    // Match signals
    wire                match_prev;
    wire                match_next;

    // Decoder signals
    reg                 mode      ;
    reg                 start     ;
    reg                 start_d    ;
    wire                valid     ;

    // ---------------------------------------
    // ---  Input Buffer                   ---
    // ---------------------------------------
    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            ref_data  <= 0;
            ref_data_d <= 0;
            valid_sr <= 0;
        end else if (i_valid) begin
            ref_data  <= i_data;
            ref_data_d <= ref_data;
            valid_sr <= {valid_sr[0], 1'b1};
        end
    end

    // ---------------------------------------
    // ---  Match logic                    ---
    // ---------------------------------------

    assign match_prev = (ref_data_d == ref_data);
    assign match_next = (ref_data   == i_data  );

    // ---------------------------------------
    // ---  Match decoder                  ---
    // ---------------------------------------
    // | match_prev | match_next | mode | start|
    // |------------|------------|------|------|
    // |     0      |     0      |  0   |  0   |
    // |     0      |     1      |  0   |  1   |
    // |     1      |     0      |  1   |  1   |
    // |     1      |     1      |  1   |  0   |
    // start= match_prev XOR match_next
    // mode = match_prev

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            mode        <= 1'b0;
            start       <= 1'b0;
        end else if (i_valid) begin
            mode        <= match_prev; 
            start       <= match_prev ^ match_next; 
        end
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if(~i_reset_n) begin
            start_d <= 0;
        end else begin
            start_d <= start;
        end
    end

    // ---------------------------------------
    // ---  Output Assign                  ---
    // ---------------------------------------
    assign valid   = valid_sr[1] & i_valid;

    assign o_data  = ref_data_d                      ;
    assign o_valid = valid                           ;
    assign o_mode  = mode | (start& valid)           ;
    assign o_start = ~mode  & (start| start_d) & valid;

endmodule