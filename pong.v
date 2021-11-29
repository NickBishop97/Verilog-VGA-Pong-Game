module pong(clk, rst, Movleft, Movright, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, Shoot);
input clk, rst, Movleft, Movright, Shoot;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;


integer start = 1;
integer GameO = 0;

clock_divider VGA_Clock_gen (clk, clk_25M);
hvsync_generator syncgen(.clk(clk_25M), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
  .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
  

///////////////////////////////////////////////////////////////// Paddle movement
reg [8:0] PaddlePosition = 249; // paddle x level location
reg [19:0] accum = 0;
wire pps = (accum == 0);

always @(posedge clk, posedge rst) begin
    if(rst) begin
        PaddlePosition = 249;
    end
    else begin
        accum <= (pps ? 500_000 : accum) - 1; // slows down moving speed so you can see the paddle moving
    
        if (pps && (start == 0) && (GameO==0)) begin
                //always @(posedge clk_25M)
                if(Movright)
                   begin
                   	   if(~&PaddlePosition)begin        // make sure the value doesn't overflow
                   		  PaddlePosition <= PaddlePosition + 1;
                   	   end
                   end
                else if (Movleft)
                   begin
                   	   if(|PaddlePosition)begin        // make sure the value doesn't underflow
                   		   PaddlePosition <= PaddlePosition - 1;
                   	   end;
                   end
        end
        if(start == 1) begin
            PaddlePosition = 249;
        end
    end
end

///////////////////////////////////////////////////////////////// ball size and position
reg ball_inX, ball_inY;
reg [9:0] ballX = 180; // starting ball position
reg [8:0] ballY = 420; // starting ball position

always @(posedge clk_25M)
        if(ball_inX==0) ball_inX <= (CounterX==ballX) & ball_inY; 
        else ball_inX <= !(CounterX==ballX+16); //ball size

always @(posedge clk_25M)
        if(ball_inY==0) ball_inY <= (CounterY==ballY); 
        else ball_inY <= !(CounterY==ballY+16); //ball size
        
wire ball = ball_inX & ball_inY;

///////////////////////////////////////////////////////////////// bacckground objects and main objects
wire border = (CounterX[9:3]==0) || (CounterX[9:3]==78) || (CounterY[8:3]==0) || (CounterY[8:3]==59); //determines border locations
wire paddle = (CounterX>=PaddlePosition+8) && (CounterX<=PaddlePosition+120) && (CounterY[8:4]==27); //contorls locaiton and size of paddle
//             starting paddle collision        ending paddle collision        [8:4]how thick | and height
wire BouncingObject = border | paddle; // active if the border or paddle is redrawing itself

wire deatharea = (CounterX>=0) && (CounterX<=640) && (CounterY[8:4]==28); // controls death area size
//block generation and location data
reg [8:4] y0 = 7; 
reg [8:4] y1 = 7;
reg [8:4] y2 = 7;
reg [8:4] y3 = 7;
reg [8:4] y4 = 7;
reg [8:4] y5 = 7;
reg [8:4] y6 = 7;
reg [8:4] y7 = 7;
reg [8:4] y8 = 7;
wire block0 =  (CounterX>=40) && (CounterX<= 100) && (CounterY[8:4] == y0);
wire block1 = (CounterX>=102) && (CounterX<= 162) && (CounterY[8:4] == y1);
wire block2 = (CounterX>=164) && (CounterX<= 224) && (CounterY[8:4] == y2);
wire block3 = (CounterX>=226) && (CounterX<= 286) && (CounterY[8:4] == y3);
wire block4 = (CounterX>=288) && (CounterX<= 348) && (CounterY[8:4] == y4);
wire block5 = (CounterX>=350) && (CounterX<= 410) && (CounterY[8:4] == y5);
wire block6 = (CounterX>=412) && (CounterX<= 472) && (CounterY[8:4] == y6);
wire block7 = (CounterX>=474) && (CounterX<= 534) && (CounterY[8:4] == y7);
wire block8 = (CounterX>=536) && (CounterX<= 596) && (CounterY[8:4] == y8);

wire blocks = block0 | block1 | block2 | block3 | block4 | block5 | block6 | block7 | block8;
///////////////////////////////////////////////////////////////// collsions
reg ResetCollision;
always @(posedge clk_25M) ResetCollision <= (CounterY==500) & (CounterX==0);  // active only once for every video frame

reg CollisionX1, CollisionX2, CollisionY1, CollisionY2;
always @(posedge clk_25M) if(ResetCollision) CollisionX1<=0; else if(BouncingObject & (CounterX==ballX   ) & (CounterY==ballY+ 8)) CollisionX1<=1;
always @(posedge clk_25M) if(ResetCollision) CollisionX2<=0; else if(BouncingObject & (CounterX==ballX+16) & (CounterY==ballY+ 8)) CollisionX2<=1;
always @(posedge clk_25M) if(ResetCollision) CollisionY1<=0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY   )) CollisionY1<=1;
always @(posedge clk_25M) if(ResetCollision) CollisionY2<=0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY+16)) CollisionY2<=1;

reg Block00Collision, Block01Collision, Block10Collision, Block11Collision, Block20Collision, Block21Collision, Block30Collision, Block31Collision, Block40Collision, Block41Collision, Blcok50Collision, Blcok51Collision, Block60Collision, Block61Collision, Block70Collision, Block71Collision, Block80Collision, Block81Collision;
always @(posedge clk_25M) if(ResetCollision) Block00Collision<=0; else if(block0 & (CounterX==ballX) & (CounterY==ballY+8)) Block00Collision<=1; //block 0
always @(posedge clk_25M) if(ResetCollision) Block01Collision<=0; else if(block0 & (CounterX==ballX+8) & (CounterY==ballY)) Block01Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Block10Collision<=0; else if(block1 & (CounterX==ballX) & (CounterY==ballY+8)) Block10Collision<=1; //block 1
always @(posedge clk_25M) if(ResetCollision) Block11Collision<=0; else if(block1 & (CounterX==ballX+8) & (CounterY==ballY)) Block11Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Block20Collision<=0; else if(block2 & (CounterX==ballX) & (CounterY==ballY+8)) Block20Collision<=1; //bock 2
always @(posedge clk_25M) if(ResetCollision) Block21Collision<=0; else if(block2 & (CounterX==ballX+8) & (CounterY==ballY)) Block21Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Block30Collision<=0; else if(block3 & (CounterX==ballX) & (CounterY==ballY+8)) Block30Collision<=1; //block 3
always @(posedge clk_25M) if(ResetCollision) Block31Collision<=0; else if(block3 & (CounterX==ballX+8) & (CounterY==ballY)) Block31Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Block40Collision<=0; else if(block4 & (CounterX==ballX) & (CounterY==ballY+8)) Block40Collision<=1; //block 4
always @(posedge clk_25M) if(ResetCollision) Block41Collision<=0; else if(block4 & (CounterX==ballX+8) & (CounterY==ballY)) Block41Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Blcok50Collision<=0; else if(block5 & (CounterX==ballX) & (CounterY==ballY+8)) Blcok50Collision<=1; //block 5
always @(posedge clk_25M) if(ResetCollision) Blcok51Collision<=0; else if(block5 & (CounterX==ballX+8) & (CounterY==ballY)) Blcok51Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Block60Collision<=0; else if(block6 & (CounterX==ballX) & (CounterY==ballY+8)) Block60Collision<=1; //block 6
always @(posedge clk_25M) if(ResetCollision) Block61Collision<=0; else if(block6 & (CounterX==ballX+8) & (CounterY==ballY)) Block61Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Block70Collision<=0; else if(block7 & (CounterX==ballX) & (CounterY==ballY+8)) Block70Collision<=1; //block 6
always @(posedge clk_25M) if(ResetCollision) Block71Collision<=0; else if(block7 & (CounterX==ballX+8) & (CounterY==ballY)) Block71Collision<=1;
always @(posedge clk_25M) if(ResetCollision) Block80Collision<=0; else if(block8 & (CounterX==ballX) & (CounterY==ballY+8)) Block80Collision<=1; //block 6
always @(posedge clk_25M) if(ResetCollision) Block81Collision<=0; else if(block8 & (CounterX==ballX+8) & (CounterY==ballY)) Block81Collision<=1;

wire BlockCollision = Block00Collision | Block01Collision | Block10Collision | Block11Collision | Block20Collision | Block21Collision | Block30Collision | Block31Collision | Block40Collision | Block41Collision | Blcok50Collision | Blcok51Collision | Block60Collision | Block61Collision | Block70Collision | Block71Collision | Block80Collision | Block81Collision;

reg CollisionDeath;
always @(posedge clk_25M) if(ResetCollision) CollisionDeath<=0; else if(deatharea & (CounterX==ballX   ) & (CounterY==ballY+ 8)) CollisionDeath<=1; // detects ball collision with death box

/////////////////////////////////////////////////////////////////block collsions and movement
wire BCollision = ResetCollision;

reg [2:0] lives = 3;
integer livereset = 0;
integer exitstart = 0;
integer respawn = 0;
integer death = 1;

always @(posedge clk_25M, posedge rst) begin
if(rst) begin
    lives=3;
    GameO=0;
    y0 = 7; y1 = 7; y2 = 7; y3 = 7; y4 = 7; y5 = 7; y6 = 7; y7 = 7; y8 = 7;
    livereset = 0;
    respawn = 0;
    start = 1;
end
else begin
        if(BCollision | CollisionDeath | (lives==0) | Shoot)
        begin 
            if((Block00Collision | Block01Collision) & (respawn==0))
                y0 = 30;
            else if((Block10Collision | Block11Collision) & (respawn==0))
                y1 = 30;
            else if((Block20Collision | Block21Collision) & (respawn==0))
                y2 = 30;
            else if((Block30Collision | Block31Collision) & (respawn==0))
                y3 = 30;
            else if((Block40Collision | Block41Collision) & (respawn==0))
                y4 = 30;
            else if((Blcok50Collision | Blcok51Collision) & (respawn==0))
                y5 = 30;
            else if((Block60Collision | Block61Collision) & (respawn==0))
                y6 = 30;
            else if((Block70Collision | Block71Collision) & (respawn==0))
                y7 = 30;
            else if((Block80Collision | Block81Collision) & (respawn==0))
                y8 = 30;
            else if(CollisionDeath && (livereset <= 0) && (GameO==0) && (start==0)) begin       //when out of lives do this
                lives <= lives-1;
                livereset = 1;
                end
            else if (Shoot && (GameO==0)) livereset = 0;
             if(Shoot && (GameO==1)) begin
                y0 = 7; y1 = 7; y2 = 7; y3 = 7; y4 = 7; y5 = 7; y6 = 7; y7 = 7; y8 = 7;
                lives = 3;
                livereset = 1;
                start = 1;
                GameO=0;
            end
            if(lives == 0) begin
                 GameO=1;
            end
            if((exitstart == 1) && (start == 1)) begin
                start = 0;
            end
        end
        else if(y0==30 & y1==30 & y2==30 & y3==30 & y4==30 & y5==30 & y6==30 & y7==30 & y8==30)
        begin
            respawn = 1;
            lives = lives+1;
            y0 = 7; y1 = 7; y2 = 7; y3 = 7; y4 = 7; y5 = 7; y6 = 7; y7 = 7; y8 = 7;
        end
        if(death==1 & respawn==1) begin
            respawn = 0;
        end
    end
end
/////////////////////////////////////////////////////////////////Game Over State
reg [8:4] a0 = 30; //y = 11
reg [8:4] a1 = 30; //y = 15
reg [8:4] a2 = 30; //y = 13
reg [8:4] a3 = 30; //y = 19
reg [8:4] a4 = 30; //y = 21
reg [8:4] a5 = 30; //y = 23

reg [9:0] b0 = 136; //x = 125
reg [9:0] b1 = 191; //x = 180
reg [9:0] b2 = 221; //x = 210
reg [9:0] b3 = 276; //x = 265
reg [9:0] b4 = 306; //x = 295
reg [9:0] b5 = 361; //x = 350
reg [9:0] b6 = 334; //x = 322
reg [9:0] b7 = 391; //x = 380
reg [9:0] b8 = 231; //x = 220
reg [9:0] b9 = 266; //x = 255
reg [9:0] b10 = 446; //x = 435


wire Gtop = (CounterX>=125) && (CounterX<=190) && (CounterY[8:4]==a0);      //up y = 11
wire Gbottom = (CounterX>=125) && (CounterX<=190) && (CounterY[8:4]==a1);   //up  y = 15
wire Gmiddle = (CounterX>=165) && (CounterX<=190) && (CounterY[8:4]==a2);   //up y = 13
wire Gleft = (CounterX>=b0) && (CounterX<=135) && (CounterY[8:6]==3);      //left x = 125
wire Gright = (CounterX>=b1) && (CounterX<=190) && (CounterY[8:5]==7);     //left x = 180

wire Aleft = (CounterX>=b2) && (CounterX<=220) && (CounterY[8:6]==3);      //left x = 210
wire Aright = (CounterX>=b3) && (CounterX<=275) && (CounterY[8:6]==3);     //left x = 265
wire Atop = (CounterX>=210) && (CounterX<=275) && (CounterY[8:4]==a0);      //up y = 11
wire Amid = (CounterX>=210) && (CounterX<=275) && (CounterY[8:4]==a2);      //up y = 13
    
wire Mleft = (CounterX>=b4) && (CounterX<=305) && (CounterY[8:6]==3);      //left x = 295
wire Mright = (CounterX>=b5) && (CounterX<=360) && (CounterY[8:6]==3);     //left x = 350
wire Mtop1 = (CounterX>=295) && (CounterX<=322) && (CounterY[8:4]==a0);     //up y = 11
wire Mtop2 = (CounterX>=333) && (CounterX<=360) && (CounterY[8:4]==a0);     //up y = 13
wire Mmid = (CounterX>=b6) && (CounterX<=333) && (CounterY[8:6]==3);       //left x = 322

wire Eleft = (CounterX>=b7) && (CounterX<=390) && (CounterY[8:6]==3);      //left x = 380
wire Etop = (CounterX>=380) && (CounterX<=445) && (CounterY[8:4]==a0);      //up y = 11
wire Emid = (CounterX>=380) && (CounterX<=445) && (CounterY[8:4]==a2);      //up y = 13
wire Ebottom = (CounterX>=380) && (CounterX<=445) && (CounterY[8:4]==a1);   //up y = 15

wire Oleft = (CounterX>=b0) && (CounterX<=135) && (CounterY[8:6]==5);      //left x = 125
wire Oright = (CounterX>=b1) && (CounterX<=190) && (CounterY[8:6]==5);     //left x = 180
wire Otop = (CounterX>=125) && (CounterX<=190) && (CounterY[8:4]==a3);      //up y = 19
wire Obottom = (CounterX>=125) && (CounterX<=190) && (CounterY[8:4]==a5);   //up y = 23

wire Vleft = (CounterX>=b2) && (CounterX<=220) && (CounterY[8:5]==10);      //left x = 210
wire Vleft1 = (CounterX>=b2) && (CounterX<=220) && (CounterY[8:4]==19);     //left x = 210
wire Vleft2 = (CounterX>=b8) && (CounterX<=230) && (CounterY[8:4]==22);     //left x = 220
wire Vright = (CounterX>=b3) && (CounterX<=275) && (CounterY[8:5]==10);     //left x = 265
wire Vright1 = (CounterX>=b3) && (CounterX<=275) && (CounterY[8:4]==19);    //left x = 265
wire Vright2 = (CounterX>=b9) && (CounterX<=265) && (CounterY[8:4]==22);    //left x = 255
wire Vbottom = (CounterX>=230) && (CounterX<=255) && (CounterY[8:4]==a5);    //up y = 23

wire E2left = (CounterX>=b4) && (CounterX<=305) && (CounterY[8:6]==5);     //left x = 295
wire E2top = (CounterX>=295) && (CounterX<=360) && (CounterY[8:4]==a3);     //up y = 19
wire E2mid = (CounterX>=295) && (CounterX<=360) && (CounterY[8:4]==a4);     //up y = 21
wire E2bottom = (CounterX>=295) && (CounterX<=360) && (CounterY[8:4]==a5);  //up y = 23

wire Rleft = (CounterX>=b7) && (CounterX<=390) && (CounterY[8:6]==5);      //left x = 380
wire Rtop = (CounterX>=380) && (CounterX<=445) && (CounterY[8:4]==a3);      //up y = 19
wire Rmid = (CounterX>=380) && (CounterX<=435) && (CounterY[8:4]==a4);      //up y = 21
wire Rright = (CounterX>=b7) && (CounterX<=390) && (CounterY[8:5]==11);    //left x = 380
wire Rright2 = (CounterX>=b10) && (CounterX<=445) && (CounterY[8:4]==20);   //left x = 435
wire Rright3 = (CounterX>=b10) && (CounterX<=445) && (CounterY[8:5]==11);   //left x = 435


wire GameOver = Rright2 | Rright3 | Rleft | Rtop | Rmid | Rright | Gtop | Gbottom |Gmiddle | Gleft | Gright | Aleft | Aright | Atop | Amid | Mleft | Mright | Mtop1 | Mtop2 | Mmid | Eleft | Etop | Emid | Ebottom | Oleft | Oright | Otop | Obottom | Vleft | Vright | Vbottom | E2left | E2top | E2mid | E2bottom | Vleft2 | Vright2 | Vright1 | Vleft1;
///////////////////////////////////////////////////////////////////Part of the Game Over state
always @(posedge clk_25M, posedge rst)begin
    if(rst) begin
        a0 = 30; a1 = 30; a2 = 30; a3 = 30; a4 = 30; a5 = 30; b0 = 136; b1 = 191; b2 = 221; b3 = 276; b4 = 306; b5 = 361; b6 = 334; b7 = 391; b8 = 231; b9 = 266; b10 = 446;
    end
    else begin
        if(GameO == 1)begin
            a0 = 11; a1 = 15; a2 = 13; a3 = 19; a4 = 21; a5 = 23; b0 = 125; b1 = 180; b2 = 210; b3 = 265; b4 = 295; b5 = 350; b6 = 322; b7 = 380; b8 = 220; b9 = 255; b10 = 435;
        end
        else if(GameO == 0)begin
            a0 = 30; a1 = 30; a2 = 30; a3 = 30; a4 = 30; a5 = 30; b0 = 136; b1 = 191; b2 = 221; b3 = 276; b4 = 306; b5 = 361; b6 = 334; b7 = 391; b8 = 231; b9 = 266; b10 = 446;
        end
    end
end
//////////////////////////////////////////////////////////////////Game Start State Numbers
reg [8:4] c = 30; //11
reg [8:4] c0 = 30; //11
reg [8:4] c1 = 30; //13
reg [8:4] c2 = 30; //15

//reg [9:0] d0 = 268; //257
reg [9:0] d1 = 268; //257
reg [9:0] d2 = 296; //285
reg [9:0] d3 = 323; //312
reg [9:0] d4 = 323; //312

wire threetop = (CounterX>=257) && (CounterX<=322) && (CounterY[8:4]==c0); //up y = 11
wire threemid = (CounterX>=257) && (CounterX<=322) && (CounterY[8:4]==c1); //up y = 13
wire threebottom = (CounterX>=257) && (CounterX<=322) && (CounterY[8:4]==c2); //up y = 15
wire threeleft = (CounterX>=d4) && (CounterX<=322) && (CounterY[8:6]==3); //left x = 312

wire twoleft = (CounterX>=d1) && (CounterX<= 267) && (CounterY[8:5]==7); //left x = 257 ,to make a two do twoleft tworight, threetop, threemid, threebottom
wire tworight = (CounterX>=d3) && (CounterX<=322) && (CounterY[8:5]==6); //left x = 312

wire onemid = (CounterX>=d2) && (CounterX<=295) && (CounterY[8:6]==3); //left 285, to make a one do onemid onetop threebottom
wire onetop = (CounterX>=257) && (CounterX<=295) && (CounterY[8:4]==c);//up y = 11

wire countdown = onemid | onetop | threebottom | threetop | threemid | threeleft | twoleft | tworight;

reg [27:0] accum1 = 0;
wire pps1 = (accum1 == 0);
reg [3:0] i = 0;
reg s = 0;
///////////////////////////////////////////////////////////////////Game Start State
always @(posedge clk, posedge rst) begin
    if(rst) begin
        accum1 = 0;
        i = 0;
        s = 0;
        c = 30; c0 = 30; c1 = 30; c2 = 30; d1 = 268; d2 = 296; d3 = 323; d4 = 323;
    end
    else begin
        accum1 <= (pps1 ? 200_000_000 : accum1) - 1;
        if(pps1 && (start==1))begin
            i = i+1;
        end
        else if(start == 0) begin
            s = 0;
        end
        if(i==1)begin
            c0 = 11; c1 = 13; c2 = 15; d4 = 312;
        end
        if(i==2)begin
            d1 =257; d3 = 312; d4 = 323;
        end
        if(i==3)begin
            d1 = 268; d2 = 285; d3 = 323; c0 = 30; c1 = 30; c = 11;
        end
        if(i==4)begin
            s = 1;
            c2 = 30; d2 = 296; c = 30;
            i=0;
        end
    end
end
always @(posedge clk_25M, posedge rst)begin
    if(rst) begin
        exitstart = 0;
    end
    else begin
       if(s==1) begin
           exitstart = 1;
       end
       if((start==0) && (exitstart==1))begin
           exitstart = 0;
       end
    end
end
/////////////////////////////////////////////////////////////////ball direction movement and collsions
wire UpdateBallPosition = ResetCollision;  // update the ball position at the same time that we reset the collision detectors
reg ball_dirX, ball_dirY;

integer negX = 0;
integer negY = 0;
integer posX = 0;
integer posY = 0;

always @(posedge clk_25M, posedge rst) begin
if(rst)begin
    negX =0; negY = 0; posX =0; posY = 0;
    death = 1;
    ballY <= 420;
end
else begin
        if(UpdateBallPosition && (GameO==0))
        begin
        	if(~(CollisionX1 & CollisionX2) & !death & (respawn==0) | BlockCollision)        // if collision on both X-sides, don't move in the X direction
        	begin
        		ballX <= ballX + (ball_dirX ? negX : posX); //Ball speed
        		if(CollisionX2) ball_dirX <= 1; 
        		else if(CollisionX1) ball_dirX <= 0;
        		
        		else if(BlockCollision & (posX == 0) & (negX == 0)) begin
        		      posX = 2;
        		      negX = -2;
        		      ball_dirY <= 0;
        		      if(PaddlePosition > 249)
        		          ball_dirX<=0;
        		      else if(PaddlePosition < 249)
        		          ball_dirX<=1;
        		end
        		else if(BlockCollision & (ball_dirX==1) & (ball_dirY==0)) ball_dirY <=1;
        		else if(BlockCollision & (ball_dirX==0) & (ball_dirY==0)) ball_dirY <=1;
        		else if(BlockCollision & (ball_dirX==1) & (ball_dirY==1)) ball_dirY <=0;
        		else if(BlockCollision & (ball_dirX==0) & (ball_dirY==1)) ball_dirY <=0;
        	end
        
        	if(~(CollisionY1 & CollisionY2 & (respawn==0)) & !death | BlockCollision)        // if collision on both Y-sides, don't move in the Y direction
        	begin
        		ballY <= ballY + (ball_dirY ? negY : posY); //ball speed
        		if(CollisionY2) ball_dirY <= 1; 
        		else if(CollisionY1) begin
        		  ball_dirY <= 0;
        		  negX = -2;
        		  posX = 2;
        		end
        	end
        	if(CollisionDeath | (respawn==1)) //when you die do this stuff \/
        	begin
        	   ballX <= PaddlePosition+50;
               ballY <= 420;
               negX = 0; //sets balls negative movement speed to zero
               posX = 0; //sets balls postive movements speed to zero
               negY = 0;
               posY = 0;
               death = 1; //set death state to 1
        	end
        	else if(death==1) begin
        	   ballX <= PaddlePosition+55;
        	   if(Shoot && (start==0))begin //When shoot is pressed and were not in the start state
        	       negY = -2;
        	       posY = 2;
        	       death = 0;
        	    end
        	end
        end
    end
end
///////////////////////////////////////////////////////////////// output to screen
wire R = BouncingObject | ball | GameOver; //| (CounterX[3] ^ CounterY[3])
wire G = BouncingObject | ball | blocks | GameOver;
wire B = BouncingObject | ball | blocks | GameOver | countdown;

reg vga_R, vga_G, vga_B;
always @(posedge clk_25M)
begin
	vga_R <= R & inDisplayArea;
	vga_G <= G & inDisplayArea;
	vga_B <= B & inDisplayArea;
end

endmodule