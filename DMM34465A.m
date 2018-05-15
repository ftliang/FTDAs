% author:guocheng
% data:2017/1/3
% version:1.0
% filename:DMM34465A.m
% describe:万用表类
classdef DMM34465A < handle
    
    properties
        dmm;
        ip;
    end
    
    properties(Constant = true)
        driver_vendor = 'ni';
        prefix = 'TCPIP::';
        suffix = '::INSTR';
    end
    
    methods
        function  obj = DMM34465A(ip)
            device = [DMM34465A.prefix ip DMM34465A.suffix];
            obj.dmm = visa(DMM34465A.driver_vendor,device);
            obj.dmm.InputBufferSize = 200000;
            obj.dmm.OutputBufferSize = 200000;
            obj.dmm.TimeOut = 100;
        end
        
        function init(obj)
            fwrite(obj.dmm,'CONF:VOLT:DC 10');
            fwrite(obj.dmm,'VOLT:DC:NPLC 10');
%             fwrite(obj.dmm,'RES:NPLC 1');
%             fwrite(obj.dmm,'CONF:RES 100');
%              fwrite(obj.dmm,'CONF:CURR:DC 0.000001');
%              fwrite(obj.dmm,'CURR:DC:NPLC 10');

            fwrite(obj.dmm,'TRIG:SOUR BUS');
        end
        
        function result = measure(obj)
            fwrite(obj.dmm,'SAMP:COUN 1');
            fwrite(obj.dmm,'INIT');
            fwrite(obj.dmm,'*TRG');
            X = query (obj.dmm,'FETC?');
            X = regexp(X,',','split');
            result = str2double(X);
        end
        
        function result = measure_count(obj,count)
            para = ['SAMP:COUN ',num2str(count)];
            fwrite(obj.dmm,para);
            fwrite(obj.dmm,'INIT');
            fwrite(obj.dmm,'*TRG');
            X = query (obj.dmm,'FETC?');
            X = regexp(X,',','split');
            result = str2double(X);
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