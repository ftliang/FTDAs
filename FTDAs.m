% author:F.Liang
% data/version:18.0503
% filename:FTDAs.m
% describe:�����ﶨ�ƿ�߾���DCԴ�����࣬��װ�棬ÿ�ζ�д���п���tcp���ӡ�
% ĿǰDA������tcpip serverģʽ�����ܵ�ָ����ʽֻ��һ�֣��ַ�������'DA=1;RW=1;ADDR=0x01;VAL=0x00000;'
% DA=(1,2,3,4);RW=(1W,0R);ADDR=0x(01,02,03,04);VAL=0x(00000~FFFFF);
% DA��4��ͨ�����豸��ÿ��ͨ����Ӧһ�Ի������������ԭ��������������ȶ��Ի�ϸ�������ã���Ϊ�������ⲿ����������Ԫ��������Ӱ�����ܡ�
% DA�ڽ���RW=1;��д����ʱ��û���κη���ֵ���ڽ���RW=0;ʱ��ֱ�ӷ��ش�DACָ��ͨ���������ĵ�ѹ����ֵ������������ʽΪ�ַ���'0x00000\n'?�������ɺ��ڵ���Ӳ���޸�����������ơ�
% RW=0ʱ��VAL�����壬�����ǰ��淶��ʽ����ȥ�����Դ���0���롣
% ADDR�����û�ֻʹ��01��������ַΪDAC�������������ͼĴ�����ֻ�Ը߼��û�ʹ�ã����Գ����д��������Ҫ�û��ṩ��ַ��Ϣ��������д����
% VALΪ��ѹ����ֵ��20bit�������룬0x00000��С����Ӧ�����Χ�п�����-2V~+2V��-3.5V~+3.5V��-7V~+7V���ӵ�·ֱ���������������������ڣ���Ҫ���ܷ�ǣ���Ŀǰ�汾Ϊ-7V~+7V
% �����豸���ܲ���18bitDAC������ֵ��ʽ���䣬��20bit��DAC��ֻ�������bit�����塣Ŀǰ�汾Ϊ20bit��
% ʹ�÷�����
% dac_ip='10.0.200.1';
% dac = FTDAs(dac_ip);
% dac.SetValue(1,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
% dac.ReadValue(1,0);
%����Ҫ���п���tcp���ӣ��������ڲ�����ά����cpu�����Ϊ���һ�����ݽ��պ������ر�tcp���ӣ����Ҳ��Ҫ��Ϲر����ӡ�ʹ��ʱע�Ᵽ֤tcp���ӵĿ��ٿ��أ��ɶԳ��֡�
%ԭ���϶��豸����Ҳ����ͻ(ҪС��)������ֵ�����һ��Ϊ׼��
classdef FTDAs <handle
    %��֪��<handle��ʲô���ã�ģ����û�С�
    properties
        ip; %�豸��ַ
        dac_handle;%�豸ָ��
        val_readout;
        str;%�����ַ���
        err_cnt=0;%ͨ�Ŵ����¼
        offset_zeroA=0;
        offset_zeroB=0;
        offset_zeroC=0;
        offset_zeroD=0;
        offset_zero=0;
    end
    methods (Access = protected)%˽�к������ܾ��ⲿ���ÿ������ӣ���Ϊdac�豸��ÿ�ν��շ�����ָ��������ر����ӡ�
        function Open(obj)%��ʱ�᳹�ױ���
            fopen(obj.dac_handle);%�����ʱ�᳹�ױ�����ν����matlab fopenû�з���ֵ���޷��ж�
        end
        
        function Close(obj)%ûë��
            fclose(obj.dac_handle);
        end   
    end
    
    methods
        function obj = FTDAs(ip)%Ҫ�޸����õĽ�����
            obj.dac_handle = tcpip(ip, 5000);
            set(obj.dac_handle,'Terminator','LF');%���ý�������Ӱ���ѯ�����������ò��ԣ����ܵ��¶�ȡ�����ʱ����Ŀǰ����ɶ������Ҳû���Գɹ���
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
                    while(writeval(obj,DA_id, Value + obj.offset_zero + 524288))%whileѭ��ȷ��д�ɹ�������Ҳ�п�����Ϊ����ɳ���ѭ�������Կ�����ೢ��3�Σ������ʧ���򱨴��ء�
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
                obj.Close();%��CPU�еĹر���ϳɶԳ���

                result =  sscanf(obj.str,'0x%05X'); %��obj.str���ַ���ת�������֣�Ŀǰ����ֵ�Ǹ�24λ16����������Ҫ�����ǰ4bit��֮����޸Ĺ̼���ֱ�ӷ���20λʮ������������0x����
                fprintf('Readback Value = %d in DEC (RealCode is 0x%05X in HEX);\n', result - obj.offset_zero -524288,result);%�����ã���ӡһ�»ض�ֵ
             else
                fprintf('DA_id should be 1,2,3,4.\n');    
             end
        end
        
        function send(obj, DA_id,  DA_addr, DA_value)%ԭʼֱд����
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=1;ADDR=0x%02X;VAL=0x%05X',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
        end
        
        function send_raw(obj, raw)%ԭʼֱд����
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
        end
        
        function result = fetch(obj, DA_id,  DA_addr, DA_value)%ԭʼ������
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=0;ADDR=0x%02X;VAL=0x%05X',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
            result =  sscanf(obj.str,'0x%05X'); %��obj.str���ַ���ת�������֣�Ŀǰ����ֵ�Ǹ�24λ16����������Ҫ�����ǰ4bit��֮����޸Ĺ̼���ֱ�ӷ���20λʮ������������0x����
            fprintf('Readback Value = 0x%05X;\n', result);%�����ã���ӡһ�»ض�ֵ
        end
        
        function result = fetch_raw(obj, raw)%ԭʼ������
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
            result =  obj.str; 
            fprintf('Readback Value = %5s;\n', result);%�����ã���ӡһ�»ض�ֵ
        end
        
        function result = writeval(obj, DA_id, DA_value)%ֻд0x01��ַ��ֵ�������һ�λض������ض�ֵ�����ϲ����ý��жԱȼ��飬��С���ʻ�дʧ�ܡ�
            obj.Open();
            obj.str=sprintf('DA=%d;RW=1;ADDR=0x01;VAL=0x%05X',DA_id,DA_value);
            fprintf(obj.dac_handle, obj.str);%дһ��
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
            obj.Open();
            obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X',DA_id,DA_value);
            fprintf(obj.dac_handle, obj.str);%��һ��
            obj.val_readout= fscanf(obj.dac_handle,'%s',7);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
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
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
            result =  sscanf(obj.str,'0x%05X'); %��obj.str���ַ���ת�������֣�Ŀǰ����ֵ�Ǹ�24λ16����������Ҫ�����ǰ4bit��֮����޸Ĺ̼���ֱ�ӷ���20λʮ������������0x����
            fprintf('Tring Fix reading ... 0x%05X;\n', result);%�����ã���ӡһ�»ض�ֵ
        end
        
    end
end

