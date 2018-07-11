% author:F.Liang
% data/version:18.0711
% filename:FTDAs.m
% describe:�����ﶨ�ƿ�߾���DCԴ�����࣬��װ�棬ÿ�ζ�д���п���tcp���ӡ�
% д��DCԴ����������ײ�Ļ������ݣ����û�������������������ı�����������Ҫ����������ת����
% ĿǰDA������tcpip serverģʽ�����ܵ�ָ��Ϊ��ASIC�ַ������ַ�����ʽ����'DA=1;RW=1;ADDR=0x01;VAL=0x00000;'
% DA=(1,2,3,4);RW=(1/W,0/R);ADDR=0x(01,02,03,04);VAL=0x(00000~FFFFF)������ֵ�̶���ȣ�����д��5λ��;
% DA��4��ͨ��������Խ��Ҫ��ǰ�������豸��ÿ��ͨ����Ӧһ�Ի������������ԭ��������������ȶ��Ի�ϸ�������ã���Ϊ�������ⲿ����������Ԫ��������Ӱ�����ܡ���
% DA�ڽ���RW=1;��д����ʱ��û���κη���ֵ���ڽ���RW=0;ʱ��ֱ�ӷ��ش�DACָ��ͨ���������ĵ�ѹ����ֵ������������ʽΪ�ַ���'0x00000\n'����\n���ַ�����������matlab�����жϸ��ַ���������ܡ����ʮ�ֱ�Ҫ���������ɺ��ڵ���Ӳ���޸�����������ơ�
% RW=0ʱ��VAL�����壬�����ǰ��淶��ʽ����ȥ�����Դ���0���롣
% ADDR�����û�ֻʹ��01��������ַΪDAC�������������ͼĴ�����ֻ�Ը߼��û�ʹ�ã����Գ����д��������Ҫ�û��ṩ��ַ��Ϣ��������д����
% VALΪ��ѹ����ֵ��20bit�������룬0x00000��С����Ӧ�����Χ-7V~+7V��
% 
% ʹ�÷������û�������
% dac_ip='10.0.200.1'; %����һ��DCԴIP
% dac = FTDAs(dac_ip); %��ʼ��
% ��Ҫ�ĺ����ڲ�������ֵ������ָoffset����0ƫ��Ժ���ܻ��л�׼���ݿ��������ݡ�
% dac.SetValue(1,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
% dac.ReadValue(1,0); %����û���������ֵ�����Խ��ж������������Ҫ�����������SetValue��������������ж�����
%����Ҫ���п���tcp���ӣ��������ڲ�����ά�����豸��cpu�����Ϊ���һ�����ݽ��պ������ر�tcp���ӣ����Ҳ��Ҫ��Ϲر����ӡ�ʹ��ʱע�Ᵽ֤tcp���ӵĿ��ٿ��أ��ɶԳ��֣���ҲҪע�⿪�ص�Ƶ��/ʱ����������ʱ���ֹ��رպ����̴򿪣�ʱ��С��0.2sʱ���豸����Ӧʧ�ܡ�
%ԭ���϶��豸����Ҳ����ͻ(ҪС��)������ֵ�����һ��Ϊ׼��
%����˵����
%V18.0521������ע�ͼ�˵������������鿪����
%V18.0602�����ReadTM�¶ȶ�ȡ��������Ҫ�����豸�̼������Ӵ����������Խ׶Ρ�
%V18.0613�������Դ��룬���ó���ʱ�㱨��������ֵ���޸���ReadValue�������
%V18.0627,�޸ĳ����ض����Դ������ƣ�ͨ��Max_err_cnt���ƣ�Ĭ����10�Ρ�ÿ�ζ�ȡʧ�ܻ�ʱ��10�ε�ʱ�仹��ͦ���ģ�����2s��
%V18.0711���޸�Open����Ϊtry catchģʽ����������open����ʧ�ܸ��ʻ���û�У���������7�����ϡ�����������û�и���Open�ķ���ֵ���������а�ȫ������

classdef FTDAs <handle
    %��֪��<handle��ʲô���ã�ģ����û�С�
    properties
        ip; %�豸��ַ
        dac_handle;%�豸ָ��
        val_readout;  %�����ַ������м����
        str;%�����ַ������м����
        err_cnt=0;%ͨ�Ŵ����¼
        Max_err_cnt=10;
        offset_zeroA=0; %�ĸ�ͨ����0ֵƫ�ã���Ҫ�����ݿ��ж�����Ȼ���ʼ��ʱ���£�matlab��Ĭ��λ0��
        offset_zeroB=0;
        offset_zeroC=0;
        offset_zeroD=0;
        offset_zero=0; %matlab���������õ��м������
    end
    methods (Access = protected)%˽�к������ܾ��ⲿ���ÿ������ӣ���Ϊdac�豸��ÿ�ν��շ�����ָ��������ر����ӡ�
      function result = Open(obj)%matlab�򿪳�ʱ�᳹�ױ�������������ҪС��
          %Ŀǰ���ԣ��򿪳�ʱ�����豸��״̬���ã�֮ǰ��ָ��û��ɣ��ȴ�һ�¾Ϳ����ˡ������൱�ڳ���3�δ򿪣�Ŀǰ�������򿪵ڶ��ξͳɹ�����û�����򿪵����ε�ʱ��
          %���������з��գ��������ʧ�ܣ���̵ĳ���ͻ��������̳���û�����open�ķ���ֵ������
            result = 0;
            try
               fopen(obj.dac_handle);%�����ʱ�᳹�ױ�����ν����matlab fopenû�з���ֵ���޷��ж�
            catch 
               warning('Open TCP/IP server failed!'); 
            
                try 
                   pause(10);
                   fopen(obj.dac_handle);%�����ʱ�᳹�ױ�����ν����matlab fopenû�з���ֵ���޷��ж�
                catch 
                   warning('Open TCP/IP server failed, again!'); 
                   
                   try 
                       pause(20);
                       fopen(obj.dac_handle);%�����ʱ�᳹�ױ�����ν����matlab fopenû�з���ֵ���޷��ж�
                   catch 
                       warning('Open TCP/IP server failed, 3rd times!'); 
                       result = -1;
                   end
                end
                
            end
        end
        
        function Close(obj)%ûë��
            fclose(obj.dac_handle);
        end   
    end
    
    methods
        function obj = FTDAs(ip)%Ҫ�޸����õĽ�����
            obj.dac_handle = tcpip(ip, 5000); %�˿�5000��ĿǰΪ�̶�ֵ
            set(obj.dac_handle,'Terminator','LF');%���ý�������Ӱ���ѯ�����������ò��ԣ����ܵ��¶�ȡ�����ʱ��
            obj.err_cnt =0;
            obj.Max_err_cnt =10;
            obj.offset_zeroA=0;
            obj.offset_zeroB=0;
            obj.offset_zeroC=0;
            obj.offset_zeroD=0;
            obj.offset_zero=0;
        end
        
        function SetValue(obj,DA_id, Value) %�û�ʹ�������ú���
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
                    while(writeval(obj,DA_id, Value + obj.offset_zero + 524288))%whileѭ��ȷ��д�ɹ�������Ҳ�п�����Ϊ����ɳ���ѭ�������Կ�����ೢ��3�Σ������ʧ���򱨴��ء�
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

        function result = writeval(obj, DA_id, DA_value)%�м亯����������SetValue��ֻд0x01��ַ��ֵ�������һ�λض������ض�ֵ�����ϲ����ý��жԱȼ��飬��С���ʻ�дʧ�ܡ�
            pause(0.2)
            obj.Open();
            obj.str=sprintf('DA=%d;RW=1;ADDR=0x01;VAL=0x%05X;',DA_id,DA_value);
            fprintf(obj.dac_handle, obj.str);%дһ��
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            pause(0.2);
            obj.Open();
            obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X;',DA_id,DA_value);
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

        function result = ReadValue(obj,DA_id) %�û�ʹ������ȡ������DA_valueûɶ���壬�����������ӿ�Ϊ������Ϊ�����޸�����ִ�д��룬����һֱûɾ����д�������ɾ����
%��ȡ������Ҫ�Լ��ȷ���һ����ȡ����DCԴ��Ӧ�󷢳���Ӧ�ַ�������λ������Ҫ��ʱ���յ��÷���ֵ��
            if (DA_id >= 1 && DA_id <=4 )
                pause(0.2)
                obj.Open();
                obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x00000;',DA_id);
                fprintf(obj.dac_handle, obj.str);
                obj.str= fscanf(obj.dac_handle,'%s',7); %���ö������ȣ�Ҳ��ʱmatlab�������ԣ�ע���ʱ���С�
                obj.Close();%��CPU�еĹر���ϳɶԳ���

                result =  sscanf(obj.str,'0x%05X'); %��obj.str���ַ���ת�������֣�Ŀǰ����ֵ�Ǹ�20λ16����������0x����
                fprintf('Readback Value = %d in DEC (RealCode is 0x%05X in HEX);\n', result - obj.offset_zero -524288,result);%�����ã���ӡһ�»ض�ֵ
             else
                fprintf('DA_id should be 1,2,3,4.\n');    
             end
        end
 
        function fix(obj) %�������������matlab open���豸���豸Ҳ��Ӧ�ˣ���û���ü������κ�ָ��ͱ��û��жϣ��������������ʾ�豸û�б��رա�
            %ǿ���޸ģ�����Ҳ���������������ѡ�Ķ�ȡ��Ȼ��ر��豸��
            obj.str=sprintf('DA=%d;RW=0;ADDR=0x01;VAL=0x%05X;',1,0);
            fprintf(obj.dac_handle, obj.str);
            obj.str= fscanf(obj.dac_handle,'%s',7);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
            result =  sscanf(obj.str,'0x%05X'); %��obj.str���ַ���ת�������֣�Ŀǰ����ֵ�Ǹ�24λ16����������Ҫ�����ǰ4bit��֮����޸Ĺ̼���ֱ�ӷ���20λʮ������������0x����
            fprintf('Tring Fix reading ... 0x%05X;\n', result);%�����ã���ӡһ�»ض�ֵ
        end
%%%%������ĺ�����Ҫ�����ͻ���ʹ��û�й�ϵ��
        function send(obj, DA_id,  DA_addr, DA_value) %ԭʼֱд��������Ҫʹ�õ���ADDR����д���Խű�Ҳ�����õ����ն��û�����Ҫʹ�á�
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=1;ADDR=0x%02X;VAL=0x%05X;',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
        end
        
        function send_raw(obj, raw)%ԭʼֱд��������͵���ģ��ⲿֱ�Ӵ������������ַ�����
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.Close();%��CPU�еĹر���ϳɶԳ���
        end
        
        function result = fetch(obj, DA_id,  DA_addr, DA_value)%ԭʼ������
            obj.Open();
            obj.str=sprintf('DA=%1d;RW=0;ADDR=0x%02X;VAL=0x%05X;',DA_id, DA_addr, DA_value);
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7); %������Ҫע�ⳤ�ȣ�Ӳ���˷��س��ȹ̶���
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
            result =  sscanf(obj.str,'0x%05X'); %��obj.str���ַ���ת�������֣�Ŀǰ����ֵ�Ǹ�24λ16����������Ҫ�����ǰ4bit��֮����޸Ĺ̼���ֱ�ӷ���20λʮ������������0x����
            fprintf('Readback Value = 0x%05X;\n', result);%�����ã���ӡһ�»ض�ֵ
        end
        
        function result = fetch_raw(obj, raw)%ԭʼ���������㴫��ȡ�����ַ�����
            obj.Open();
            obj.str=raw;
            fprintf(obj.dac_handle, obj.str);
            obj.str = fscanf(obj.dac_handle,'%s',7); %��λ�����з���ֵ�����淶Ϊ5��byte��
            obj.Close();%��CPU�еĹر���ϳɶԳ���
            
            result =  obj.str; 
            fprintf('Readback Value = %5s;\n', result);%�����ã���ӡһ�»ض�ֵ����֪���û�����������ֱ�ӷ������ַ�����
        end
        

       
        
        
        function result = ReadTM(obj,DA_id) %�û�ʹ������ȡ������DA_valueûɶ���壬�����������ӿ�Ϊ������Ϊ�����޸�����ִ�д��룬����һֱûɾ����д�������ɾ����
%��ȡ������Ҫ�Լ��ȷ���һ����ȡ����DCԴ��Ӧ�󷢳���Ӧ�ַ�������λ������Ҫ��ʱ���յ��÷���ֵ��
            if (DA_id >= 1 && DA_id <=5 )
                pause(0.2)
                obj.Open();
                obj.str=sprintf('TM=%d;',DA_id);
                fprintf(obj.dac_handle, obj.str);
                obj.str= fscanf(obj.dac_handle,'%s',10); %���ö������ȣ�Ҳ����matlab�������ԣ�ע���ʱ���С�
                obj.Close();%��CPU�еĹر���ϳɶԳ���
                result =  sscanf(obj.str,'%f'); %��obj.str���ַ���ת�������֣�Ŀǰ����ֵ�Ǹ�20λ16����������0x����
                fprintf('Readback Value = %.2f & %s\n', result, obj.str);%�����ã���ӡһ�»ض�ֵ
             else
                fprintf('TM_id should be 1,2,3,4,5.\n');    
             end
        end
    end
end

