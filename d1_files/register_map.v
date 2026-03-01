module register_map #(
    parameter NB_DATA = 8,
    parameter NB_ADDR = 8
) 

(
    input wire                  clk                           , // Clock signal
    input wire                  resetb                        , // Active low reset signal

    input wire                  wr_req                        , // Write request signal
    input wire                  rd_req                        , // Read request signal
    input wire [NB_DATA-1:0]    data_in                       , // Data input bus
    input wire [NB_ADDR-1:0]    addr_in                       , // Address input bus

    // STATUS BITS
    //Status
    input wire                  pll_locked                    ,
    input wire                  pll_in_range                  ,
    input wire                  pga_saturate                  ,
    input wire  [2     -1:0]    vco_gear                      ,

    //rx_packets
    input wire                  rx_status_packet_detected     ,
    input wire                  rx_infoframe_detected         ,
    input wire                  rx_color_correct_detected     ,
    input wire                  rx_content_protection_detected,
    input wire                  rx_video_id_detected          ,
    input wire                  rx_audio_id_detected          ,
    input wire                  rx_aux_data_detected          ,


    output wire [NB_DATA-1:0]   data_out                      , // Data output bus
    // CONTROL BITS
    // power_down
    output wire                 master_powerdown              ,
    output wire                 afe_powerdown                 ,
    output wire                 aaf_powerdown                 ,
    output wire                 pga_powerdown                 ,
    output wire                 pll_powerdown                 ,
    output wire                 pads_powerdown                ,
    // tx_controls
    output wire                 tx_enable                     ,
    output wire                 tx_clk_gen_enable             ,
    output wire                 tx_despreader_enable          ,
    output wire                 tx_freq_diversity_enable      ,
    output wire [2     -1:0]    tx_lane_sel                   ,
    //tx_serdes_controls
    output wire [3     -1:0]    tx_slew_rate                  ,
    output wire [2     -1:0]    tx_phase_interpolation        ,
    //rx_audio_out
    output wire [4     -1:0]    rx_audio_out_enable           ,
    output wire [2     -1:0]    rx_audio_out_format
);


    //****************************************
    //              LOCALPARAMETERS
    //****************************************
    localparam N_REGISTERS                = 2 ** NB_ADDR;

    localparam ADDR_POWER_DOWN            = 'h00;
    localparam ADDR_STATUS                = 'h10;
    localparam ADDR_TX_CONTROLS           = 'h34;
    localparam ADDR_RX_PACKETS            = 'h48;
    localparam ADDR_TX_SERDES_CONTROLS    = 'h52;
    localparam ADDR_RX_AUDIO_OUT          = 'h68;

    localparam DEFAULT_POWER_DOWN         ='h80;
    localparam DEFAULT_TX_CONTROLS        ='h84;
    localparam DEFAULT_TX_SERDES_CONTROLS ='hF0;
    localparam DEFAULT_RX_AUDIO_OUT       ='hFC;

    //****************************************
    //              READ-ONLY CHECKER
    //****************************************
    wire [NB_DATA     -1:0]                status_packet;
    wire [NB_DATA     -1:0]                rx_packets;
    wire                                   rd_only_addr;

    assign rd_only_addr = addr_in == ADDR_STATUS || addr_in == ADDR_RX_PACKETS;

    assign status_packet = {pll_locked, pll_in_range             , pga_saturate         , vco_gear[1]              , vco_gear[0]                  , 1'b0                    ,1'b0                    , 1'b0                   }; // status
    assign rx_packets     = {1'b0      , rx_status_packet_detected,rx_infoframe_detected ,rx_color_correct_detected ,rx_content_protection_detected, rx_video_id_detected , rx_audio_id_detected, rx_aux_data_detected}; // ss
    
    //****************************************
    //              MEMORY
    //****************************************
    reg  [N_REGISTERS -1:0] [NB_DATA -1:0] mem;
    reg  [N_REGISTERS -1:0] [NB_DATA -1:0] mem_d;

    always@(*) begin
        mem                   = mem_d;
        mem [ADDR_STATUS    ] = status_packet; // status
        mem [ADDR_RX_PACKETS] = rx_packets; // rx_packets
    end

    always @(posedge clk or negedge resetb) begin
        if(!resetb) begin
            mem_d                          <= {NB_DATA * N_REGISTERS {1'b0}};
            mem_d[ADDR_POWER_DOWN]         <= DEFAULT_POWER_DOWN;
            mem_d[ADDR_TX_CONTROLS]        <= DEFAULT_TX_CONTROLS;
            mem_d[ADDR_TX_SERDES_CONTROLS] <= DEFAULT_TX_SERDES_CONTROLS;
            mem_d[ADDR_RX_AUDIO_OUT]       <= DEFAULT_RX_AUDIO_OUT;
        end else if(wr_req & ~rd_only_addr)begin
            mem_d[addr_in]         <=  data_in;
        end else begin
            mem_d    <= mem; // status
        end 
    end


    //****************************************
    //              OUTPUT ASSIGN
    //****************************************
    assign data_out = mem[addr_in];
    assign {master_powerdown      , afe_powerdown          , aaf_powerdown         , pga_powerdown            , pll_powerdown             , pads_powerdown        } =  mem_d[ADDR_POWER_DOWN        ][NB_DATA -1:2];
    assign {tx_enable             , tx_clk_gen_enable      , tx_despreader_enable  , tx_freq_diversity_enable , tx_lane_sel[1]            , tx_lane_sel[0]        } =  mem_d[ADDR_TX_CONTROLS       ][NB_DATA -1:2];
    assign {tx_slew_rate[2]       , tx_slew_rate[1]        , tx_slew_rate[0]       , tx_phase_interpolation[1], tx_phase_interpolation[0]                         } =  mem_d[ADDR_TX_SERDES_CONTROLS][NB_DATA -1:3];
    assign {rx_audio_out_enable[3], rx_audio_out_enable[2] , rx_audio_out_enable[1], rx_audio_out_enable[0]   , rx_audio_out_format[1]    , rx_audio_out_format[0]} =  mem_d[ADDR_RX_AUDIO_OUT      ][NB_DATA -1:2];
   
endmodule