%% ��������
 close all;
 clear; 
 clc
%% �߾���DAC�������ϵ���������Ӧ��Ϊ0V������Сֵ��
dac_ip='10.0.200.10';
dac = FTDAs(dac_ip);
%%
for ii = 1:1000
dac.ReadValue(4);
dac.ReadValue(3);
dac.ReadValue(2);
dac.ReadValue(1);
ii
end
%% -7v�����иĽں�����P��Ӧ�����-7V��N��Ϊ+7V
dac.SetValue(1,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(2,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(3,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(4,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
%% +7V�����иýں�����P��Ӧ�����+7V��N��Ϊ-7V
dac.SetValue(1,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(2,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(3,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(4,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
%% 0V�����иýں�����P��Ӧ�����0V��N��Ϊ0V
dac.SetValue(1,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(2,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(3,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(4,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)