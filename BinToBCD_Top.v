`timescale 1ns / 1ps

module BinToBCD_Top(

input mclk,
output wire [6:0] seg,
output wire [3:0] an);


 reg [15:0] stat_bcd = 16'b0;
 
 wire en;
 wire [11:0] bin_d_in;
 wire [15:0] bcd_d_out;
 wire rdy;
 wire clock_out;
 
 example_count uut1(clock_out,en,bin_d_in);
 bin2BCD uut2(clock_out, en,bin_d_in,bcd_d_out,rdy);
 multi_seg_drive uut3(clock_out,stat_bcd,an, seg);
 clk_divider uut4(mclk,clock_out);
 
 always @(posedge mclk)
    begin
    if(rdy)
       begin
       stat_bcd<=bcd_d_out;
       end
     end
    
endmodule

module bin2BCD(

   
    input           clk,
    input           en,
    input   [11:0]  bin_d_in,
    output  [15:0]  bcd_d_out,
   output          rdy
    );
    
    //State variables
    parameter IDLE      = 3'b000;
    parameter SETUP     = 3'b001;
    parameter ADD       = 3'b010;
    parameter SHIFT     = 3'b011;
    parameter DONE      = 3'b100;
    
    //reg [11:0]  bin_data    = 0;
    reg [27:0]  bcd_data    = 0;
    reg [2:0]   state       = 0;
    reg         busy        = 0;
    reg [3:0]   sh_counter  = 0;
    reg [1:0]   add_counter = 0;
    reg         result_rdy  = 0;
    
    
    always @(posedge clk)
        begin
        if(en)
            begin
                if(~busy)
                    begin
                    bcd_data    <= {16'b0, bin_d_in};
                    state       <= SETUP;
                    end
            end
        
        case(state)
        
            IDLE:
                begin
                    result_rdy  <= 0;
                    busy        <= 0;
                end
                
            SETUP:
                begin
                busy        <= 1;
                state       <= ADD;
                end
                    
            ADD:
                begin
                
                case(add_counter)
                    0:
                        begin
                        if(bcd_data[15:12] > 4)
                            begin
                                bcd_data[27:12] <= bcd_data[27:12] + 3;
                            end
                            add_counter <= add_counter + 1;
                        end
                    
                    1:
                        begin
                        if(bcd_data[19:16] > 4)
                            begin
                                bcd_data[27:16] <= bcd_data[27:16] + 3;
                            end
                            add_counter <= add_counter + 1;
                        end
                        
                    2:
                        begin
                        if((add_counter == 2) && (bcd_data[23:20] > 4))
                            begin
                                bcd_data[27:20] <= bcd_data[27:20] + 3;
                            end
                            add_counter <= add_counter + 1;
                        end
                        
                    3:
                        begin
                        if((add_counter == 3) && (bcd_data[27:24] > 4))
                            begin
                                bcd_data[27:24] <= bcd_data[27:24] + 3;
                            end
                            add_counter <= 0;
                            state   <= SHIFT;
                        end
                    endcase
                end
                
            SHIFT:
                begin
                sh_counter  <= sh_counter + 1;
                bcd_data    <= bcd_data << 1;
                
                if(sh_counter == 11)
                    begin
                    sh_counter  <= 0;
                    state       <= DONE;
                    end
                else
                    begin
                    state   <= ADD;
                    end

                end
 
            
            DONE:
                begin
                result_rdy  <= 1;
                state       <= IDLE;
                end
            default:
                begin
                state <= IDLE;
                end
            
            endcase
            
        end
    assign bcd_d_out    = bcd_data[27:12];
   assign rdy          = result_rdy;
endmodule

module example_count(

input clk,
output done,
output [11:0] bin_cnt);

parameter c_reg_size = 34;

reg [c_reg_size -1:0] count = 0;
reg fin = 0;
reg old_b = 0;


 always @(posedge clk)
    begin
    count <= count+1;
        if((old_b && !count[c_reg_size-12]) || (!old_b && count[c_reg_size-12]))
            begin
            fin <=1;
            end
        else
            begin
            fin <=0;
            end
         old_b <=count[c_reg_size-12];
         end
     
assign bin_cnt =  count[c_reg_size-1: c_reg_size-12];
assign done = fin;   
 
endmodule

module clk_divider(clock_in,clock_out
    );
input clock_in; // input clock on FPGA
output reg clock_out; // output clock after dividing the input clock by divisor
reg[27:0] counter=28'd0;
parameter DIVISOR = 28'd2;
// The frequency of the output clk_out
//  = The frequency of the input clk_in divided by DIVISOR
// For example: Fclk_in = 50Mhz, if you want to get 1Hz signal to blink LEDs
// You will modify the DIVISOR parameter value to 28'd50.000.000
// Then the frequency of the output clk_out = 50Mhz/50.000.000 = 1Hz
always @(posedge clock_in)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;
 clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;
end
endmodule


module multi_seg_drive(
input clk,
 input [15:0] bcd_in,
 output [3:0] sseg_a_o,
 output [6:0] sseg_c_o);

parameter g_s = 5;
parameter gt = 4;

wire [6:0] sseg_o;
reg [3:0] anode =4'b0001;
reg [3:0] bcd_seg =4'b0000;
reg [g_s-1:0] g_count =0;

ss_decode ss_dec(clk, bcd_seg,sseg_o);

    always @(posedge clk)
    begin
    g_count =g_count+1;
        if(g_count == 0)
            begin
            if(anode == 4'b0001)
                begin
                anode = 4'b1000;
                end   
            else 
                begin
                anode = anode >>1;
                end
             end
             
         if(&g_count[g_s-1:gt])
            begin
            case (anode) //case statement
            4'b1000 : bcd_seg = bcd_in[15:12];
            4'b0100 : bcd_seg = bcd_in[11:8];
            4'b0010 : bcd_seg = bcd_in[7:4];
            4'b0001 : bcd_seg = bcd_in[3:0];
            //switch off 7 segment character when the bcd digit is not a decimal number.
            default : bcd_seg = 4'b1111; 
            endcase
         end 
         
         else 
            begin
            bcd_seg = 4'b1111; 
            end 
          end
assign  sseg_a_o = ~anode;   
assign  sseg_c_o =  sseg_o;    
       
endmodule

module ss_decode(clk, bcd,seg);
 input clk;
 input [3:0] bcd;
 output reg[6:0] seg;
// output [3:0] an;
// assign an = 4'b1110;
 
    
//always block for converting bcd digit into 7 segment format
    always @(posedge clk)
    begin
        case (bcd) //case statement
        
            0 : seg = 7'b1000000;
            1 : seg = 7'b1111001;
            2 : seg = 7'b0100100;
            3 : seg = 7'b0110000;
            4 : seg = 7'b0011001;
            5 : seg = 7'b0010010;
            6 : seg = 7'b0000010;
            7 : seg = 7'b1111000;
            8 : seg = 7'b0000000;
            9 : seg = 7'b0010000;
            //switch off 7 segment character when the bcd digit is not a decimal number.
            default : seg = 7'b1111111; 
            
        endcase
        
        end 
        
       
endmodule
