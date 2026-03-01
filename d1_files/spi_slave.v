module spi_slave#
(
    parameter NB_PACKET = 8
)
(
    input wire                  resetb  ,
    input wire                  sclk    ,
    input wire                  csb     ,
    input wire                  mosi    ,
    input wire  [NB_PACKET-1:0] rd_data ,

    output wire                 miso    ,
    output wire [NB_PACKET-1:0] addr_out,
    output wire [NB_PACKET-1:0] wr_data ,
    output wire                 wr_req  , 
    output wire                 rd_req 
);
    //****************************************
    //          LOCALPARAMETERS
    //****************************************
    localparam NB_CLOCK_COUNTER = 3;
    localparam N_PACKETS        = 3;
    localparam NB_SR_CONTROL    = 3;

    localparam CMD_PACKET_IDX  = 0;
    localparam ADDR_PACKET_IDX = 1;
    localparam DATA_PACKET_IDX = 2;

    wire internal_reset;
    assign internal_reset = ~resetb | csb;
    
    //****************************************
    //          CLOCK_COUNTER
    //****************************************
    reg [NB_CLOCK_COUNTER -1:0] clock_counter       ;
    wire                        clock_counter_pulse ;

    always @(posedge sclk or posedge internal_reset) begin
        if(internal_reset ) begin
            clock_counter <= {NB_CLOCK_COUNTER{1'b0}};
        end else begin 
            clock_counter <= clock_counter + 1'b1;
        end
    end

    assign clock_counter_pulse = clock_counter == (NB_PACKET -1);

    //****************************************
    //           MOSI SHIFT REGISTER
    //****************************************
    reg     [NB_PACKET-1:0] mosi_sr;
    wire    [NB_PACKET-1:0] mosi_sr_next;

    always @(posedge sclk or posedge internal_reset) begin
        if(internal_reset) begin
            mosi_sr <= {NB_PACKET{1'b0}};
        end else begin 
            mosi_sr <= mosi_sr_next;
        end
    end

    assign mosi_sr_next = {mosi_sr[NB_PACKET-2:0], mosi};

    //****************************************
    //           CONTROL LOGIC
    //****************************************
    reg  [NB_SR_CONTROL -1:0]   control_sr        ;

    always @(posedge sclk or posedge internal_reset) begin
        if(internal_reset) begin
            control_sr <= {{NB_SR_CONTROL-1{1'b0}}, 1'b1};
        end else if(clock_counter_pulse) begin 
            control_sr <= {control_sr[NB_SR_CONTROL-2:0], control_sr[NB_SR_CONTROL-1]};
        end
    end



    //****************************************
    //           CMD, ADDR and DATA ASSIGN
    //****************************************

    reg  [N_PACKETS -1:0][NB_PACKET -1:0] packet      ;
    wire [N_PACKETS -1:0]                 packet_valid;
    wire                                  is_write_cmd; 

    assign is_write_cmd                  = ~packet[CMD_PACKET_IDX][NB_PACKET-1];
    assign packet_valid[CMD_PACKET_IDX ] = control_sr[0]               ; //cmd valid
    assign packet_valid[ADDR_PACKET_IDX] = control_sr[1]               ; //addr valid
    assign packet_valid[DATA_PACKET_IDX] = control_sr[2] & is_write_cmd; //data valid

    generate
        for (genvar i = 0; i< N_PACKETS; i++) begin: gen_packet_reg
            always @(posedge sclk or posedge internal_reset) begin
                if(internal_reset) begin
                    packet[i] <= {NB_PACKET{1'b0}};
                end else if( clock_counter_pulse & packet_valid[i]) begin 
                    packet[i] <= mosi_sr_next;
                end
            end
        end
    endgenerate

    //****************************************
    //           WR and RD ASSIGN
    //****************************************
    reg rd_req_gen;
    reg wr_req_gen;

    always @(posedge sclk or posedge internal_reset or posedge csb) begin
        if(internal_reset) begin
            rd_req_gen <= 1'b0;
        end else  begin 
            rd_req_gen <= ~is_write_cmd & packet_valid[ADDR_PACKET_IDX] & clock_counter_pulse;
        end
    end

    always @(posedge sclk or posedge internal_reset or posedge csb) begin
        if(internal_reset) begin
            wr_req_gen <= 1'b0;
        end else begin 
            wr_req_gen <= is_write_cmd & packet_valid[DATA_PACKET_IDX] & clock_counter_pulse;
        end
    end

    //****************************************
    //           DATA OUT ASSIGN
    //****************************************
    reg bit_out;

    always @(posedge sclk or posedge internal_reset) begin
        if(internal_reset) begin
            bit_out <= 1'b0;
        end else if(control_sr[2] & ~is_write_cmd) begin 
            bit_out <= rd_data[NB_PACKET - clock_counter -1];
        end
    end


    //****************************************
    //           OUTPUT ASSIGN
    //****************************************

    assign miso     = bit_out                   ;
    assign addr_out = packet[ADDR_PACKET_IDX]   ;
    assign wr_data  = packet[DATA_PACKET_IDX]   ;
    assign wr_req   = wr_req_gen                ;
    assign rd_req   = rd_req_gen                ;


endmodule