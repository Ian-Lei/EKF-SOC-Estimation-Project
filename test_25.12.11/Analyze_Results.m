%% Analyze_Results.m - 提取并可视化 EKF 仿真结果
% 1. 确保数据预处理和仿真已完成
if ~exist('SOC_LUT', 'var')
    run('OCV_SOC.m');
end

if ~exist('sim_out', 'var')
    fprintf('正在运行仿真...\n');
    sim_out = sim('EKF', 'StopTime', '20138');
end

% 2. 从 ScopeData_1 (Simulink.SimulationData.Dataset) 提取信号
% 假设信号 1 是 EKF SOC，信号 2 是 True SOC
try
    ekf_values = sim_out.ScopeData_1{1}.Values;
    true_values = sim_out.ScopeData_1{2}.Values;
    
    time = ekf_values.Time;
    ekf_soc = ekf_values.Data;
    true_soc = true_values.Data;
    
    % 3. 在基础工作区创建数据表
    % 我们将时间、EKF SOC、理论 SOC 以及它们的误差合并到一个表中
    error = ekf_soc - true_soc;
    SOC_Results_Table = table(time, ekf_soc, true_soc, error, ...
        'VariableNames', {'Time_s', 'EKF_SOC', 'True_SOC', 'Error'});
    
    assignin('base', 'SOC_Results_Table', SOC_Results_Table);
    
    % 4. 绘图对比
    figure('Name', 'SOC Estimation Comparison', 'NumberTitle', 'off');
    plot(time, true_soc, 'k--', 'LineWidth', 1.5); hold on;
    plot(time, ekf_soc, 'r-', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (s)');
    ylabel('SOC (0-1)');
    legend('True SOC (Coulomb Counting)', 'Estimated SOC (EKF)');
    title('EKF SOC Estimation Performance');
    
    % 绘制误差曲线
    figure('Name', 'SOC Estimation Error', 'NumberTitle', 'off');
    plot(time, error, 'b-', 'LineWidth', 1.5);
    grid on;
    xlabel('Time (s)');
    ylabel('Error (EKF - True)');
    title('SOC Estimation Error Over Time');
    
    fprintf('分析完成！\n数据表 "SOC_Results_Table" 已创建并在工作区可见。\n');
    
    % 显示前 10 行预览
    disp('SOC 结果预览 (前 10 行):');
    disp(SOC_Results_Table(1:10, :));
    
catch ME
    fprintf('提取数据时出错: %s\n', ME.message);
    fprintf('请检查 ScopeData_1 的索引和内容。\n');
end
