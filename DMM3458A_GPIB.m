% author:guocheng
% data:2017/1/3
% version:1.0
% filename:DMM3458A_GPIB.m
% describe:万用表类
classdef DMM3458A_GPIB < handle
    
    properties
        dmm;
        ip;
        data;
        datab;
    end
    
    properties(Constant = true)
%        driver_vendor = 'AGILENT';
        driver_vendor = 'ni';
        prefix = 'GPIB0::';
        suffix = '::INSTR';
    end
    
    methods
        function  obj = DMM3458A_GPIB(ip)
            device = [DMM3458A_GPIB.prefix ip DMM3458A_GPIB.suffix];
            obj.dmm = visa(DMM3458A_GPIB.driver_vendor,device);
            set (obj.dmm,'InputBufferSize',400000);
            set (obj.dmm,'timeout', 100);   %Set timeout to 25 seconds
            set (obj.dmm, 'ByteOrder', 'bigEndian');
        end
        
        function init(obj)
            fprintf (obj.dmm,'reset');
            fprintf (obj.dmm,'preset norm'); %configures for DCV Digitizing see page 218 user's manual
            fprintf (obj.dmm,'oformat ascii');
            fprintf (obj.dmm,'dcv 1');
%            fprintf (obj.dmm,'dci 0.0000001');
%fprintf (obj.dmm,'ohm 100');
            fprintf (obj.dmm,'tarm hold');
            fprintf (obj.dmm,'trig auto');
            fprintf (obj.dmm,'nplc 10');%与nplc相对的时间
            fprintf (obj.dmm,'mem off'); %clears any previous data in memory and sets for fifo operation
            fprintf (obj.dmm,'end on');  %sets up the correct EOL, use end always if memory off
            fprintf (obj.dmm,'ndig 9');
            fprintf (obj.dmm,'azero on');
            fprintf (obj.dmm,'disp on');

        end
        
        function result = measure(obj)

                fprintf (obj.dmm,'nrdgs 1,auto');
                fprintf (obj.dmm,'tarm sgl'); %Arm the instrument once
                %pause(2); %wait for the reading to get into memory before pulling them out
                %fprintf (obj.dmm,'RMEM 1,1');

                %[data] = fread(obj.dmm,1,'short');  %read data from instrument
                [obj.data] = fscanf(obj.dmm,'%s',1000);  %read data from instrument
                result = parsestr(obj.data);
%                result = str2double(obj.data);
%                 fprintf (obj.dmm,'iscale?'); %get scaling factor for SINT format (set by Preset Dig)
%                 scale = fscanf (obj.dmm,'%f');
% 
%                 scaledreadings = scale*data;  %multiply data by scaling factor
        end
        
        function result = measure_count(obj,count)%数据会被连起来，有解析bug暂不使用

                fprintf (obj.dmm,'nrdgs %d,auto',count);
                fprintf (obj.dmm,'tarm sgl'); %Arm the instrument once
                %pause(1); %wait for the reading to get into memory before pulling them out
                %fprintf (obj.dmm,'RMEM 1,%d',count);

                %[data] = fread(obj.dmm,1,'short');  %read data from instrument
                [obj.data] = fscanf(obj.dmm,'%s',20*count);  %read data from instrument
                result = parsestr(obj.data);
%                 if (strcmp('-', obj.data(1)))
%                     for i = 1:count
%                         result(i) = str2double(obj.data(16*(i-1)+1:16*i));
%                     end
%                 else
%                      for i = 1:count
%                         result(i) = str2double(obj.data(15*(i-1)+1:15*i));
%                     end                   
%                 end

%                 fprintf (obj.dmm,'iscale?'); %get scaling factor for SINT format (set by Preset Dig)
%                 scale = fscanf (obj.dmm,'%f');
% 
%                 scaledreadings = scale*data;  %multiply data by scaling factor
        end
        
        function Open(obj)
            fopen(obj.dmm);
            init(obj);
        end
        
        function Close(obj)
            fclose(obj.dmm);
        end
    end
end