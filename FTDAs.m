% author:F.Liang
% data/version:18.0503
% filename:FTDAs.m
% describe:梁福田定制款高精度DC源操作类，封装版，每次读写进行开关tcp连接。
% 目前DA工作在tcpip server模式，接受的指令形式只有一种，字符串类型'DA=1;RW=1;ADDR=0x01;VAL=0x00000;'
% DA=(1,2,3,4);RW=(1W,0R);ADDR=0x(01,02,03,04);VAL=0x(00000~FFFFF);
% DA有4个通道，设备上每个通道对应一对互补反向输出，原则上正端输出的稳定性会较负端输出好，因为负端有外部网络电阻独立元件，可能影响性能。
% DA在接受RW=1;的写操作时，没有任何返回值，在接受RW=0;时，直接返回从DAC指定通道都回来的电压设置值。返回数据形式为字符串'0x00000\n'?结束符可后期调整硬件修改以配合软件设计。
% RW=0时，VAL无意义，但还是按规范格式带进去，可以传递0进入。
% ADDR常规用户只使用01，其他地址为DAC其他功能设置型寄存器，只对高级用户使用，所以常规读写函数不需要用户提供地址信息，函数内写死。
% VAL为电压设置值，20bit二进制码，0x00000最小，对应输出范围有可能是-2V~+2V，-3.5V~+3.5V，-7V~+7V，视电路直接配置情况（不能随意调节，需要开密封盖），目前版本为-7V~+7V
% 部分设备可能采用18bitDAC，设置值形式不变，传20bit到DAC，只是最低两bit无意义。目前版本为20bit。
% 使用范例：
% dac_ip='10.0.200.1';
% dac = FTDAs(dac_ip);
% dac.SetValue(1,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
% dac.ReadValue(1,0);
%不需要进行开关tcp连接，本代码内部自行维护，cpu内设计为完成一次数据接收后主动关闭tcp链接，软件也需要配合关闭链接。使用时注意保证tcp链接的快速开关，成对出现。
%原则上多设备操作也不冲突(要小心)，设置值以最后一次为准。
classdef FTDAs <handle
    %不知道<handle是什么作用，模板里没有。
    properties
        ip; %设备地址
        dac_handle;%设备指针
        val_readout;
        str;%传递字符串
        err_cnt=0;%通信错误记录
        offset_zeroA=0;
        offset_zeroB=0;
        offset_zeroC=0;
        offset_zeroD=0;
        offset_zero=0;
    end
    methods (Access = protected)%私有函数，拒绝外部调用开关连接，因为dac设备上每次接收发送完指令会主动关闭连接。
        function Open(obj)%超时会彻底报错
            fopen(obj.dac_handle);%如果超时会彻底报错，如何解决？matlab fopen没有返回值，无法判读
        end
        
        function Close(obj)%没毛病
            fclose(obj.dac_handle);
        end   
    end
    
    methods
        function obj = FTDAs(ip)%要修改设置的结束符
            obj.dac_handle = tcpip(ip, 5000);
            set(obj.dac_handle,'Terminator','LF');%设置结束符，影响查询等命令，如果设置不对，可能导致读取结果超时，但目前设置啥结束符也没测试成功。
            obj.err_cnt =0;
            obj.offset_zeroA=0;
            obj.offset_zeroB=0;
            obj.offset_zeroC=0;
            obj.offset_zeroD=0;
            obj.offset_zero=0;
        end
        
        function SetValue(obj,DA_id, Value)
            if (DA_id >= 1 && DA_id <=4 )
                switch DA_id
                    case {1} 
                        obj.offset_zero = obj.offset_zeroA; 
                    case {2}
                        obj.offset_zero = obj.offset_zeroB; 
                    case {3}
                        obj.offset_zero = obj.offset_zeroC;
                    case {4}
                        obj.offset_zero = obj.offset_zeroD;
                end
                if (((Value + obj.offset_zero) >= -524288) && ((Value + obj.offset_zero)  <524288))
                    while(writeval(obj,DA_id, Value + obj.offset_zero + 524288))%while循环确保写成功，但是也有可能因为意外干成死循环，可以考虑最多尝试3次，如果都失败则报错返回。
                        fprintf('SetValule error occured, retrying...\n');
                    end
                    pause(0.2);
                else
                    fprintf('Value must be in [-524288 - offset_zero,524287 - offset_zero]\n');
                end
            else
                    fprintf('DA_id should be 1,2,3,4.\n');
            end
        end 
        
        function result = ReadValue(obj,DA_id, DA_value)
             if (DA_id >= 1 && DA_id <=4 )
                obj.Open();
                obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X',DA_id, DA_value-DA_value);
                fprintf(obj.dac_handle, obj.str);
                obj.str= fscanf(obj.dac_handle,'%s',7);
                obj.Close();%和CPU中的关闭配合成对出现

                result =  sscanf(obj.str,'0x%05X'); %将obj.str的字符串转换成数字，目前返回值是个24位16进制数，需要处理掉前4bit，之后会修改固件，直接返回20位十六进制数（带0x）。
                fprintf('Readback Value = %d in DEC (RealCode is 0x%05X in HEX);\n', result - obj.offset_zero -524288,result);%调试用，打印一下回读值
             else
                fprintf('DA_id should be 1,2,3,4.\n');    
             end
        end
        
        function send(obj, DA_id,  DA_addr, DA_value)%原始直写函数
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=1;ADDR=0x%02X;VAL=0x%05X',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%和CPU中的关闭配合成对出现
        end
        
        function send_raw(obj, raw)%原始直写函数
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%和CPU中的关闭配合成对出现
        end
        
        function result = fetch(obj, DA_id,  DA_addr, DA_value)%原始读函数
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=0;ADDR=0x%02X;VAL=0x%05X',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7);
            obj.Close();%和CPU中的关闭配合成对出现
            
            result =  sscanf(obj.str,'0x%05X'); %将obj.str的字符串转换成数字，目前返回值是个24位16进制数，需要处理掉前4bit，之后会修改固件，直接返回20位十六进制数（带0x）。
            fprintf('Readback Value = 0x%05X;\n', result);%调试用，打印一下回读值
        end
        
        function result = fetch_raw(obj, raw)%原始读函数
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7);
            obj.Close();%和CPU中的关闭配合成对出现
            
            result =  obj.str; 
            fprintf('Readback Value = %5s;\n', result);%调试用，打印一下回读值
        end
        
        function result = writeval(obj, DA_id, DA_value)%只写0x01地址的值，并完成一次回读，将回读值用于上层设置进行对比检验，很小概率会写失败。
            obj.Open();
            obj.str=sprintf('DA=%d;RW=1;ADDR=0x01;VAL=0x%05X',DA_id,DA_value);
            fprintf(obj.dac_handle, obj.str);%写一次
            obj.Close();%和CPU中的关闭配合成对出现
            
            obj.Open();
            obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X',DA_id,DA_value);
            fprintf(obj.dac_handle, obj.str);%读一次
            obj.val_readout= fscanf(obj.dac_handle,'%s',7);
            obj.Close();%和CPU中的关闭配合成对出现
            
            obj.str = sprintf('0x%05X',DA_value);
            if (~isempty(obj.val_readout) && strcmp(obj.str, obj.val_readout))
                result=0;
            else
                result=1;
                obj.err_cnt = obj.err_cnt+1;
            end
            
        end

       
        
        function fix(obj)
            obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X',1,0);
            fprintf(obj.dac_handle, obj.str);
            obj.str= fscanf(obj.dac_handle,'%s',7);
            obj.Close();%和CPU中的关闭配合成对出现
            
            result =  sscanf(obj.str,'0x%05X'); %将obj.str的字符串转换成数字，目前返回值是个24位16进制数，需要处理掉前4bit，之后会修改固件，直接返回20位十六进制数（带0x）。
            fprintf('Tring Fix reading ... 0x%05X;\n', result);%调试用，打印一下回读值
        end
        
    end
end

