module ucsbece154b_icache #(
    parameter NUM_SETS    = 8,
    parameter NUM_WAYS    = 4,
    parameter TAG_SIZE    = 25,
    parameter BLOCK_WORDS = 4,
    parameter WORD_SIZE   = 32
)(
    input                      clk,
    input                      Reset,
    input flush,

    // core fetch interface
    input                      ReadEnable,
    input       [31:0]         ReadAddress,
    input       [31:0]         PCF_o,
    output reg  [WORD_SIZE-1:0] Instruction,
    output reg                 Ready,
    output reg                 Busy,

    // SDRAM-controller interface
    output reg  [31:0]         MemReadAddress,
    output reg                 MemReadRequest,
    input       [31:0]         MemDataIn,
    input                      MemDataReady
);
`include "ucsbece154b_defines.vh"
// cache storage
reg [WORD_SIZE-1:0] cache_data [0:NUM_SETS-1][0:NUM_WAYS-1][0:BLOCK_WORDS-1];
reg [TAG_SIZE:0] tag_array [0:NUM_SETS-1][0:NUM_WAYS-1];
reg cachebuz;
reg cachehit;
reg prebuz;

// buffers and internal control
reg bypass;
reg waiting_for_mem;
reg init;
reg [31:0] SDRAMAddress;
reg [$clog2(BLOCK_WORDS):0] cycle;
reg [$clog2(NUM_WAYS):0] tar;
reg [31:0] buffadd;
wire [31:0] mux;
assign mux = bypass ? buffadd : ReadAddress;

reg [WORD_SIZE-1:0] buff[0:BLOCK_WORDS-1];
reg [WORD_SIZE-1:0] addres[0:BLOCK_WORDS-1];

// Prefetch buffer
reg [WORD_SIZE-1:0] prefetcher[0:BLOCK_WORDS-1];
reg [27:0] storetag;
reg iprefetch;
reg [31:0] pre_address;
reg [31:0] pre_address2;
reg  prehit;
reg reading;
// loop variablesd
integer i, j, k, hit, fyef, precount, phit,cachemiss,accesstot,  rea;
reg flushed;
always @(posedge clk)  begin
    flushed<=flush;
    if(flushed  &  !Ready)begin
        buffadd<=PCF_o;
    end
end
always @(posedge clk) begin
    if (Reset) begin
        for (i = 0; i < NUM_SETS; i = i + 1)
            for (j = 0; j < NUM_WAYS; j = j + 1)
                for (k = 0; k < BLOCK_WORDS; k = k + 1)
                    cache_data[i][j][k] <= 0;

        for (i = 0; i < NUM_SETS; i = i + 1)
            for (j = 0; j < NUM_WAYS; j = j + 1)
                tag_array[i][j] <= 0;

        waiting_for_mem <= 0;
        init <= 0;
        bypass <= 0;
        fyef = 0;
        precount=0;
        cachebuz <=0;
        cachehit <=0;
        cachemiss=0;
        accesstot=0;
    end
    else begin
        if (ReadEnable | bypass) begin
            hit = -1;

            for (i = 0; i < BLOCK_WORDS; i = i + 1) begin
                if (addres[i] == mux) begin
                    Instruction <= buff[i];
                    rea=0;
                    Ready <= 1'b1;
                    bypass <= 0;
                    hit = 1;
                    fyef = fyef + 1;
                    accesstot=accesstot+1;
                end
                if(mux[31:4]==storetag & reading !=1) begin
                    if (mux!=PCF_o & bypass)
                    begin
                        buffadd <= PCF_o;
                         bypass<=1;

                    end
                    else begin
                        accesstot=accesstot+1;
                    Instruction<=prefetcher[mux[3:2]];
                    Ready <= 1'b1;
                    bypass <= 0;
                    hit=1;
                    rea=0;
                    precount=precount+1;
                    tag_array[mux[6:4]][2] <= {1'b1, mux[31:7]};
                    if(prebuz==0)begin
                    iprefetch <= 1;
                    prehit <=0;
                    pre_address <= {mux[31:4], 4'b0} + 5'b10000;
                    end
                    for (j = 0; j < BLOCK_WORDS; j = j + 1) begin
                    cache_data[mux[6:4]][2][j]<=prefetcher[j];
                    end
                    end
                   
                    
                end
            end
            
            if (hit == -1) begin
                
                    hit=-1;
                    for (i = 0; i < NUM_WAYS; i = i + 1) begin
                        if (tag_array[mux[6:4]][i][24:0] == mux[31:7] && tag_array[mux[6:4]][i][25] == 1)
                            hit = i;
                    end

                    if (hit != -1) begin
                        rea=0;
                        Instruction <= cache_data[mux[6:4]][hit][mux[3:2]];
                        accesstot=accesstot+1;
                        Ready <= 1'b1;
                        Busy <= 1'b0;
                        bypass <= 0;
                    end
                    else begin
                        if (rea==0)  begin
                        cachemiss= cachemiss+1;
                        accesstot=accesstot+1;
                        rea=1;
                        end
                        if (!waiting_for_mem & !prebuz & !cachehit) begin
                            Ready <= 1'b0;
                            Busy <= 1'b1;
                            waiting_for_mem <= 1'b1;
                            SDRAMAddress <= mux;
                            MemReadAddress <= mux;
                            MemReadRequest <= 1'b1;
                            cycle <= 0;
                            init <= 1;
                            bypass <= 0;
                            iprefetch <= 1;
                            cachebuz <=1;
                             
                            pre_address <= {mux[31:4], 4'b0} + 5'b10000;
                             
                        end
                        else begin
                            Ready <= 1'b0;
                            buffadd <= mux;
                            bypass <= 1;
                        end
                    end
                
            end
        end

        if (waiting_for_mem & !prebuz & !cachehit) begin
            if (cycle == 0) begin
                if (MemDataReady) begin
                    if (init) begin
                        if((PCF_o==SDRAMAddress) | (PCF_o ==pc_start)) begin
                        Instruction <= MemDataIn;
                        MemReadRequest <= 1'b0;
                        Ready <= 1'b1; 
                        init<=0;
                        end
                        else begin
                            Ready <= 1'b0; 
                            buffadd <= PCF_o;
                            bypass<=1;
                            MemReadRequest <= 1'b0;
                            cachebuz <=0;
                            cachehit <=0;
                            prehit <=0;
                            waiting_for_mem <= 1'b0;
                            iprefetch <= 0;
                        end
                    end
                    else begin
                        hit = -1;
                        for (i = 0; i < NUM_WAYS; i = i + 1)
                            if (!tag_array[SDRAMAddress[6:4]][i][25])
                                hit = i;

                        if (hit != -1)
                            tar <= hit;
                        else begin
                            tar = ($random & 32'h7FFFFFFF) % NUM_WAYS;
                            tar<=hit;
                        end
                        
                    
                        cache_data[SDRAMAddress[6:4]][hit][cycle] <= MemDataIn;
                        addres[cycle] <= {SDRAMAddress[31:4], cycle[1:0], 2'b0};
                        buff[cycle] <= MemDataIn;
                        cycle <= cycle + 1;
                        MemReadRequest <= 1'b0;
                    end
                end
            end
            else if (cycle > 0) begin
                if (cycle < BLOCK_WORDS-1) begin
                    cache_data[SDRAMAddress[6:4]][tar][cycle] <= MemDataIn;
                    addres[cycle] <= {SDRAMAddress[31:4], cycle[1:0], 2'b0};
                    buff[cycle] <= MemDataIn;
                    cycle <= cycle + 1;
                end
                else if (cycle == BLOCK_WORDS-1) begin
                    cache_data[SDRAMAddress[6:4]][tar][cycle] <= MemDataIn;
                    tag_array[SDRAMAddress[6:4]][tar] <= {1'b1, SDRAMAddress[31:7]};
                    addres[cycle] <= {SDRAMAddress[31:4], cycle[1:0], 2'b0};
                    buff[cycle] <= MemDataIn;
                    cycle <= cycle + 1;
                end
                else if (cycle == BLOCK_WORDS) begin
                    Busy <= 1'b0;
                    waiting_for_mem <= 1'b0;
                    cachebuz <=0;
                    cachehit <=1;
                    prehit <=0;
                    cycle <= 0;
                end
            end
        end
    end
end

// Prefetch logic
reg [1:0] prefetch_cycle;
reg initpre;

always @(posedge clk) begin
    if (Reset) begin
        prebuz <=0;
        iprefetch <= 0;
        pre_address <= 0;
        storetag <= 0;
        reading<= 0;
        for (i = 0; i < BLOCK_WORDS; i = i + 1)
            prefetcher[i] <= 0;
    end

    if (iprefetch & !cachebuz & !prehit) begin
        if (!waiting_for_mem) begin
            waiting_for_mem <= 1'b1;
            MemReadAddress <= pre_address;
            pre_address2 <=pre_address;
            MemReadRequest <= 1'b1;
            prefetch_cycle <= 0;
            iprefetch <= 0;
            
            reading <=1;
            prebuz<=1;
            initpre<=1;
            prehit<=0;
        end
    end
    else if (reading==1 &!cachebuz & MemDataReady) begin
        if (initpre==1 & MemDataReady) begin
            waiting_for_mem <= 1'b0;
            initpre<=0;
            MemReadRequest <= 1'b0;
        end
        else if (prefetch_cycle < BLOCK_WORDS-1) begin
            prefetcher[prefetch_cycle] <= MemDataIn;
            prefetch_cycle <= prefetch_cycle + 1;
        end
        else if (prefetch_cycle == BLOCK_WORDS-1) begin
        prefetcher[prefetch_cycle] <= MemDataIn;
        prefetch_cycle <= 0;
        reading <=0;
        prebuz<=0;
        cachehit<=0;
        prehit<=1;
        storetag <= pre_address2[31:4];
    end
    end
end

endmodule