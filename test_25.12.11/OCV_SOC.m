%% 1. 加载数据
% 请确保 Excel 文件在当前 MATLAB 目录下，或者修改为绝对路径
data = readtable('10_16_2015_Initial capacity_SP20-1.xlsx');

% 提取核心列
time = data.Test_Time_s_;   % 时间
current = data.Current_A_;  % 电流
voltage = data.Voltage_V_;  % 电压
step = data.Step_Index;     % 步骤索引

%% 2. 提取 Step 6 (恒流放电阶段) 的数据
% 逻辑：只取出 step == 6 的那些行
idx_discharge = (step == 6);

t_dis = time(idx_discharge);
i_dis = current(idx_discharge);
v_dis = voltage(idx_discharge);

% 把时间归零（让放电从 0 秒开始）
t_dis = t_dis - t_dis(1);

%% 3. 计算 SOC (Coulomb Counting)
% 也就是计算累计放出了多少电量
% NCM 18650 电池标称容量通常在 2.0Ah - 3.0Ah 之间，我们通过积分计算实际容量
capacity_discharged = cumtrapz(t_dis, abs(i_dis)) / 3600; % 单位转换 As -> Ah
total_capacity = max(capacity_discharged); % 总放电容量

% 计算 SOC 序列 (从 100% 降到 0%)
% SOC = 1 - (已放容量 / 总容量)
soc_dis = 1 - (capacity_discharged / total_capacity);

%% 4. 获取 OCV 曲线 (简化近似法)
% 理论公式：V_term = OCV - I * R
% 因为是恒流放电(I是负值)，V_term < OCV。
% 为了简单验证，我们可以粗略认为低倍率放电电压近似等于 OCV
% 或者加一个固定的压降补偿（假设内阻 R0 = 0.1 欧姆，具体稍后算）
R0_est = 0.08; % 初始估计值，单位欧姆
ocv_est = v_dis + abs(i_dis) * R0_est;

%% 5. 绘图验证
figure;
plot(soc_dis, ocv_est, 'LineWidth', 2);
xlabel('SOC (0-1)');
ylabel('OCV (V)');
title('提取的 OCV - SOC 曲线');
grid on;
set(gca, 'XDir', 'reverse'); % SOC 通常习惯从 1 到 0 看

%% 6. 保存参数供 Simulink 使用
% 生成 lookup table 数据
SOC_Vector = linspace(0, 1, 100); % 生成 0 到 1 的 100 个点
OCV_Vector = interp1(soc_dis, ocv_est, SOC_Vector, 'linear', 'extrap'); % 插值得到对应电压

% 保存到 Workspace，Simulink 模块会自动读取这两个变量
assignin('base', 'SOC_LUT', SOC_Vector);
assignin('base', 'OCV_LUT', OCV_Vector);
assignin('base', 'Bat_Capacity', total_capacity); 

fprintf('建模完成！\n电池总容量为: %.4f Ah\nOCV曲线已保存至 Workspace\n', total_capacity);