% author:FT.Liang
% data:2018/05/11
% version:1.1
% filename:34470A读数据
% describe:34470A读数据
%% 清理数据
 close all;
 clear; 
 clc;
%% 高精度DAC操作
dac_ip='10.0.200.2';
dac = FTDAs(dac_ip);
dac.SetValue(1,-524288);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(2,524287);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(3,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)
dac.SetValue(4,0);%Value must be in [-524288 - offset_zero,524287 - offset_zero)

%% 设置和打开设备
dmma_ip='10.89.5.149';
dmma = DMM34465A(dmma_ip);
dmma.Open();

% dmmb_ip='10.0.254.8';
% dmmb = DMM34465A(dmmb_ip);
% dmmb.Open();
%% 数据初始化
SUM_TIME=30000;%in hour
eachtime=100;%轮训数据测试
times=SUM_TIME*eachtime;
results_a = zeros(1,times);
results_b = zeros(1,times);


figure;
%plot(time_counts, dmm_value, 'r.', 'MarkerSize', 6);
hold on;

%% 实际运行段
t0= datenum(datestr(now,0));
time_arr = repmat(t0, times, 1);

tic
time_counts=1;
fix(clock)
while( time_counts < times)

    for i=time_counts:(time_counts+eachtime-1)
            time_arr(i) = datenum(datestr(now,0));
            dmm_value = dmma.measure_count(1);
            results_a(i)=dmm_value;
            dmm_value = dmmb.measure_count(1);
            results_b(i)=dmm_value;

    end
 

time_counts = time_counts+eachtime;
if mod(time_counts-1,10) ==0
    disp((time_counts-1)/(times));
    disp((time_counts-1)/eachtime+1)
    fix(clock)
    save __tmp_a results_a;
    save __tmp_b results_b;
    save __tmp_time_arr time_arr;
    
time_offset=1;
subplot(2,1,1);
plot(time_arr(time_offset:1: time_counts-1), results_a(time_offset:1: time_counts-1), 'r.', 'MarkerSize', 6);
datetick('x',0);
subplot(2,1,2);
plot(time_arr(time_offset:1: time_counts-1), results_b(time_offset:1: time_counts-1), 'r.', 'MarkerSize', 6);
datetick('x',0);
drawnow;
toc
end
end
toc
 %% 单独绘图查看
time_offset=1;
time_counts = 300000;
subplot(2,1,1);
plot(time_arr(time_offset:1: time_counts-1), results_a(time_offset:1: time_counts-1), 'r.', 'MarkerSize', 6);
datetick('x',0);
subplot(2,1,2);
plot(time_arr(time_offset:1: time_counts-1), results_b(time_offset:1: time_counts-1), 'r.', 'MarkerSize', 6);
datetick('x',0);
drawnow;
%% 单独保存，注意文件名
    save __tmp_a results_a;
    save __tmp_b results_b;
    save __tmp_time_arr time_arr;
                                
%% 仪表设备关闭
dmma.Close;
dmmb.Close;
