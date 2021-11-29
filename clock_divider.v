`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2021 04:27:43 PM
// Design Name: 
// Module Name: clock_divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_divider #(parameter div_value = 1)(
    input wire clk, // 100MHz
    output reg divided_clk = 0 //25Hz
    );
    //localparam div_value = 49999999;  //1MHz
    
    //division_value = 100Mhz / (2*desired frequequency) - 1 // for 1Hz it will be 49999999
    
    //counter
    integer counter_value = 0; // 32 bit wide reg bus
    
    always@ (posedge clk) //sensitivity list
        begin
            //keep counting untill div_value
            if (counter_value == div_value)
                counter_value <=0; //reset value
            else
                counter_value <= counter_value+1;        
        end
      //divide clock
     always@(posedge clk)
     begin
        if(counter_value == div_value)
            divided_clk <= ~divided_clk; // flip the signal
        else 
            divided_clk <= divided_clk; // store value
     
     end
endmodule
