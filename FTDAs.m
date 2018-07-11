% author:F.Liang
% data/version:18.0711
% filename:FTDAs.m
% describe:梁福田定制款高精度DC源操作类，封装版，每次读写进行开关tcp连接。
% 写给DC源的数据是最底层的基础数据，而用户输入的数据是物理层面的变量，两者需要在软件层进行转换。
% 目前DA工作在tcpip server模式，接受的指令为纯ASIC字符串，字符串格式类似'DA=1;RW=1;ADDR=0x01;VAL=0x00000;'
% DA=(1,2,3,4);RW=(1/W,0/R);ADDR=0x(01,02,03,04);VAL=0x(00000~FFFFF)（设置值固定宽度，必须写满5位）;
% DA有4个通道，设置越界要提前处理。（设备上每个通道对应一对互补反向输出，原则上正端输出的稳定性会较负端输出好，因为负端有外部网络电阻独立元件，可能影响性能。）
% DA在接受RW=1;的写操作时，没有任何返回值，在接受RW=0;时，直接返回从DAC指定通道都回来的电压设置值。返回数据形式为字符串'0x00000\n'其中\n是字符串结束符，matlab里面判断改字符后结束接受。如果十分必要，结束符可后期调整硬件修改以配合软件设计。
% RW=0时，VAL无意义，但还是按规范格式带进去，可以传递0进入。
% ADDR常规用户只使用01，其他地址为DAC其他功能设置型寄存器，只对高级用户使用，所以常规读写函数不需要用户提供地址信息，函数内写死。
% VAL为电压设置值，20bit二进制码，0x00000最小，对应输出范围-7V~+7V。
% 
% 使用范例（用户级）：
% dac_ip='10.0.200.1'; %定义一个DC源IP
% dac = FTDAs(dac_ip); %初始化
% 必要的函数内部参量赋值，尤其指offset，即0偏差，以后可能会有基准数据库读入该数据。
% dac.SetValue(1,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
% dac.ReadValue(1,0); %如果用户忘记设置值，可以进行读出。如果不必要读出，上面的SetValue操作就完成了所有动作。
%不需要进行开关tcp连接，本代码内部自行维护，设备端cpu内设计为完成一次数据接收后主动关闭tcp链接，软件也需要配合关闭链接。使用时注意保证tcp链接的快速开关，成对出现，但也要注意开关的频率/时间间隔，测试时出现过关闭后立刻打开，时间小于0.2s时，设备端响应失败。
%原则上多设备操作也不冲突(要小心)，设置值以最后一次为准。
%更新说明：
%V18.0521，更新注释及说明，用于软件组开发。
%V18.0602，添加ReadTM温度读取函数。需要更新设备固件，连接传感器，测试阶段。
%V18.0613，辅助性代码，设置出错时汇报出错设置值。修改了ReadValue输入参数
%V18.0627,修改出错重读尝试次数限制，通过Max_err_cnt控制，默认是10次。每次读取失败或超时，10次的时间还是挺长的，至少2s。
%V18.0711，修改Open函数为try catch模式，尝试三次open，打开失败概率基本没有，连续运行7天以上。但其他函数没有根据Open的返回值做跟进，有安全隐患。

classdef FTDAs <handle
    %不知道<handle是什么作用，模板里没有。
    properties
        ip; %设备地址
        dac_handle;%设备指针
        val_readout;  %读出字符串，中间变量
        str;%传递字符串，中间变量
        err_cnt=0;%通信错误记录
        Max_err_cnt=10;
        offset_zeroA=0; %四个通道的0值偏置，需要从数据库中读出，然后初始化时更新，matlab里默认位0；
        offset_zeroB=0;
        offset_zeroC=0;
        offset_zeroD=0;
        offset_zero=0; %matlab代码中利用的中间变量。
    end
    methods (Access = protected)%私有函数，拒绝外部调用开关连接，因为dac设备上每次接收发送完指令会主动关闭连接。
      function result = Open(obj)%matlab打开超时会彻底报错，其他语言需要小心
          %目前尝试，打开超时都是设备端状态不好，之前的指令没完成，等待一下就可以了。这里相当于尝试3次打开，目前见到过打开第二次就成功，还没到过打开第三次的时候。
          %但是依旧有风险，如果都打开失败，后继的程序就会出错，而后继程序还没有针对open的返回值做处理。
            result = 0;
            try
               fopen(obj.dac_handle);%如果超时会彻底报错，如何解决？matlab fopen没有返回值，无法判读
            catch 
               warning('Open TCP/IP server failed!'); 
            
                try 
                   pause(10);
                   fopen(obj.dac_handle);%如果超时会彻底报错，如何解决？matlab fopen没有返回值，无法判读
                catch 
                   warning('Open TCP/IP server failed, again!'); 
                   
                   try 
                       pause(20);
                       fopen(obj.dac_handle);%如果超时会彻底报错，如何解决？matlab fopen没有返回值，无法判读
                   catch 
                       warning('Open TCP/IP server failed, 3rd times!'); 
                       result = -1;
                   end
                end
                
            end
        end
        
        function Close(obj)%没毛病
            fclose(obj.dac_handle);
        end   
    end
    
    methods
        function obj = FTDAs(ip)%要修改设置的结束符
            obj.dac_handle = tcpip(ip, 5000); %端口5000，目前为固定值
            set(obj.dac_handle,'Terminator','LF');%设置结束符，影响查询等命令，如果设置不对，可能导致读取结果超时。
            obj.err_cnt =0;
            obj.Max_err_cnt =10;
            obj.offset_zeroA=0;
            obj.offset_zeroB=0;
            obj.offset_zeroC=0;
            obj.offset_zeroD=0;
            obj.offset_zero=0;
        end
        
        function SetValue(obj,DA_id, Value) %用户使用主设置函数
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
                    obj.err_cnt = 0;
                    while(writeval(obj,DA_id, Value + obj.offset_zero + 524288))%while循环确保写成功，但是也有可能因为意外干成死循环，可以考虑最多尝试3次，如果都失败则报错返回。
                        if (obj.err_cnt >= obj.Max_err_cnt)
                            fprintf('SetValue error occured to Maximum Setting(%d times), SetValue give up...\n',obj.Max_err_cnt);
                            return;
                        end
                        fprintf('SetValue error occured, retrying...(DA_id=%d, Value = %d, retring %d times)\n',DA_id, Value, obj.err_cnt);
                        pause(0.2);
                    end
                    
                else
                    fprintf('Value must be in [-524288 - offset_zero,524287 - offset_zero]\n');
                end
            else
                    fprintf('DA_id should be 1,2,3,4.\n');
            end
        end 

        function result = writeval(obj, DA_id, DA_value)%中间函数，服务于SetValue，只写0x01地址的值，并完成一次回读，将回读值用于上层设置进行对比检验，很小概率会写失败。
            pause(0.2)
            obj.Open();
            obj.str=sprintf('DA=%d;RW=1;ADDR=0x01;VAL=0x%05X;',DA_id,DA_value);
            fprintf(obj.dac_handle, obj.str);%写一次
            obj.Close();%和CPU中的关闭配合成对出现
            pause(0.2);
            obj.Open();
            obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X;',DA_id,DA_value);
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

        function result = ReadValue(obj,DA_id) %用户使用主读取函数，DA_value没啥意义，但是最初程序接口为这样，为避免修改其他执行代码，这里一直没删，新写软件可以删除。
%读取操作是要自己先发送一个读取请求，DC源响应后发出相应字符串，上位机程序要及时接收到该返回值。
            if (DA_id >= 1 && DA_id <=4 )
                pause(0.2)
                obj.Open();
                obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x00000;',DA_id);
                fprintf(obj.dac_handle, obj.str);
                obj.str= fscanf(obj.dac_handle,'%s',7); %设置读出长度，也许时matlab的特殊性，注意别超时就行。
                obj.Close();%和CPU中的关闭配合成对出现

                result =  sscanf(obj.str,'0x%05X'); %将obj.str的字符串转换成数字，目前返回值是个20位16进制数（带0x）。
                fprintf('Readback Value = %d in DEC (RealCode is 0x%05X in HEX);\n', result - obj.offset_zero -524288,result);%调试用，打印一下回读值
             else
                fprintf('DA_id should be 1,2,3,4.\n');    
             end
        end
 
        function fix(obj) %及其特殊情况，matlab open了设备，设备也响应了，还没来得及发送任何指令，就被用户中断，这样程序里会提示设备没有被关闭。
            %强行修改，发送也给无意义命令，这里选的读取，然后关闭设备。
            obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X;',1,0);
            fprintf(obj.dac_handle, obj.str);
            obj.str= fscanf(obj.dac_handle,'%s',7);
            obj.Close();%和CPU中的关闭配合成对出现
            
            result =  sscanf(obj.str,'0x%05X'); %将obj.str的字符串转换成数字，目前返回值是个24位16进制数，需要处理掉前4bit，之后会修改固件，直接返回20位十六进制数（带0x）。
            fprintf('Tring Fix reading ... 0x%05X;\n', result);%调试用，打印一下回读值
        end
%%%%再下面的函数不要看，和基础使用没有关系。
        function send(obj, DA_id,  DA_addr, DA_value) %原始直写函数（主要使用到了ADDR），写测试脚本也许能用到，终端用户不需要使用。
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=1;ADDR=0x%02X;VAL=0x%05X;',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%和CPU中的关闭配合成对出现
        end
        
        function send_raw(obj, raw)%原始直写函数，最偷懒的，外部直接传入完整命令字符串。
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%和CPU中的关闭配合成对出现
        end
        
        function result = fetch(obj, DA_id,  DA_addr, DA_value)%原始读函数
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=0;ADDR=0x%02X;VAL=0x%05X;',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7); %这里需要注意长度，硬件端返回长度固定。
            obj.Close();%和CPU中的关闭配合成对出现
            
            result =  sscanf(obj.str,'0x%05X'); %将obj.str的字符串转换成数字，目前返回值是个24位16进制数，需要处理掉前4bit，之后会修改固件，直接返回20位十六进制数（带0x）。
            fprintf('Readback Value = 0x%05X;\n', result);%调试用，打印一下回读值
        end
        
        function result = fetch_raw(obj, raw)%原始读函数，裸传读取命令字符串。
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7); %下位机所有返回值都被规范为5个byte。
            obj.Close();%和CPU中的关闭配合成对出现
            
            result =  obj.str; 
            fprintf('Readback Value = %5s;\n', result);%调试用，打印一下回读值，不知道用户的请求，所以直接返回裸字符串。
        end
        

       
        
        
        function result = ReadTM(obj,DA_id) %用户使用主读取函数，DA_value没啥意义，但是最初程序接口为这样，为避免修改其他执行代码，这里一直没删，新写软件可以删除。
%读取操作是要自己先发送一个读取请求，DC源响应后发出相应字符串，上位机程序要及时接收到该返回值。
            if (DA_id >= 1 && DA_id <=5 )
                pause(0.2)
                obj.Open();
                obj.str=sprintf('TM=%d;',DA_id);
                fprintf(obj.dac_handle, obj.str);
                obj.str= fscanf(obj.dac_handle,'%s',10); %设置读出长度，也许是matlab的特殊性，注意别超时就行。
                obj.Close();%和CPU中的关闭配合成对出现
                result =  sscanf(obj.str,'%f'); %将obj.str的字符串转换成数字，目前返回值是个20位16进制数（带0x）。
                fprintf('Readback Value = %.2f & %s\n', result, obj.str);%调试用，打印一下回读值
             else
                fprintf('TM_id should be 1,2,3,4,5.\n');    
             end
        end
    end
end

