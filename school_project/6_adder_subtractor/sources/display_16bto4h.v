//数码管显示模块
//能将16位的二进制数以十六进制形式显示到4个七段数码管上
//负数则小数点代表负号
//BASYS3板子自带的时钟CLK频率是100MHz，即每秒tick 10^8次。所以10^5即为 1ms
module display_16bto4h #(parameter INTERVAL = 10**5/2)//控制数码管频率，为1/INTERVAL Hz
                        (input CLK,//板子自带的clock
                         input [15:0] x, //要显示的16位数
                         input neg, //negative，是否为负数（小数点亮），小数点只亮最后一位
                         output reg[11:0] DISP); // DISPLAY，数码管

    integer counter = 0;//计数器，记CLK tick的次数

    reg[1:0] sel = 0; //select，选择显示哪一位，取十进制数0~3，最后转换成posb四位独热码
    reg[3:0] posb; //pos binary，四位独热码，对应DISP前4位控制位，由sel控制，低电平有效，作用为：“DISP <= {posb, btohDISP(digit), dp};”
    reg[3:0] digit; //取输入端口x的某4位

    always @(posedge CLK) begin
        if (counter == INTERVAL)begin
            //sel依次取0, 1, 2, 3, 0, 1, 2, 3...每次控制一个数码管
            if (sel == 3) 
                sel <= 0;
            else
                sel <= sel + 1;

            counter <= 0; //重置counter
        end else begin
            counter <= counter + 1; //CLK tick一次，counter计数一次
        end
    end

    always @(sel) begin
        //digit对应取x的某4位
        digit[0] = x[sel*4];
        digit[1] = x[sel*4 + 1];
        digit[2] = x[sel*4 + 2];
        digit[3] = x[sel*4 + 3];
    end

    //posb低电平有效, 把0, 1, 2, 3对应转换成1110, 1101, 1011, 0111
    always @(sel) begin
        case (sel)
            0: posb = 4'b1110;
            1: posb = 4'b1101;
            2: posb = 4'b1011;
            3: posb = 4'b0111;
            default: posb = 4'b0;
        endcase
    end

    //控制显示数字的7~1位abcdefg
    function [6:0] btohDISP; 
        input[3:0] digit;
        case (digit)
            4'h0:    btohDISP = 7'b0000001;
            4'h1:    btohDISP = 7'b1001111;
            4'h2:    btohDISP = 7'b0010010;
            4'h3:    btohDISP = 7'b0000110;
            4'h4:    btohDISP = 7'b1001100;
            4'h5:    btohDISP = 7'b0100100;
            4'h6:    btohDISP = 7'b0100000;
            4'h7:    btohDISP = 7'b0001111;
            4'h8:    btohDISP = 7'b0000000;
            4'h9:    btohDISP = 7'b0000100;
            4'ha:    btohDISP = 7'b0001000;
            4'hb:    btohDISP = 7'b1100000;
            4'hc:    btohDISP = 7'b0110001;
            4'hd:    btohDISP = 7'b1000010;
            4'he:    btohDISP = 7'b0110000;
            4'hf:    btohDISP = 7'b0111000;
            default: btohDISP = 7'b1111111;
        endcase

    endfunction

    always @(posedge CLK) begin
        if (counter == INTERVAL)begin
            //把各个位组合起来显示在数码管上
            if (sel == 0)
                //小数点显示在最低位
                DISP <= {posb, btohDISP(digit), ~neg};
            else
                DISP <= {posb, btohDISP(digit), 1'b1};

        end
    end

endmodule