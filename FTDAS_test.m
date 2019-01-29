%% 清理数据
 close all;
 clear; 
 clc
%% 高精度DAC操作，上电后，所有输出应该为0V附近的小值。
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
%% -7v，运行改节后，所有P端应该输出-7V，N端为+7V
dac.SetValue(1,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(2,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(3,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(4,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
%% +7V，运行该节后，所有P端应该输出+7V，N端为-7V
dac.SetValue(1,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(2,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(3,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(4,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
%% 0V，运行该节后，所有P端应该输出0V，N端为0V
dac.SetValue(1,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(2,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(3,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(4,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)