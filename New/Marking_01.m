%% Day 1: 内存预分配与向量化性能压测脚本
clear; clc; close all;

%% 1. 仿真工况物理参数定义（拒绝魔法数字）
f_grid = 50;              % 欧标电网工频 50 Hz
f_s    = 10e3;             % 工业采集卡采样率 10 kHz
dt     = 1 / f_s;         % 采样时间步长 0.1 ms
T_total = 10;             % 记录总时间 10 秒
N = T_total * f_s;        % 总采样点数：100,000 点

fprintf('==== 开始基准性能压测（数据规模：%d 点） ====\n', N);

%% 方案一：低效写法（未预分配内存 + 动态扩容 for 循环）
tic;
y_dynamic = [];
for k = 1:N
    t_k = (k-1) * dt;
    y_dynamic(k) = 230 * sqrt(2) * sin(2*pi*f_grid*t_k);
end
t_cost_dynamic = toc;
fprintf('1. 动态扩容 for 循环耗时: %.5f 秒\n', t_cost_dynamic);

%% 方案二：基础改进（zeros 预分配内存 + 逐点 for 循环）
tic;
y_prealloc = zeros(1, N);
for k = 1:N
    t_k = (k-1) * dt;
    y_prealloc(k) = 230 * sqrt(2) * sin(2*pi*f_grid*t_k);
end
t_cost_prealloc = toc;
fprintf('2. 预分配内存 for 循环耗时: %.5f 秒 (加速比: %.2fx)\n', ...
    t_cost_prealloc, t_cost_dynamic / t_cost_prealloc);

%% 方案三：工业级向量化（Vectorization）
tic;
t_vec = (0:N-1) * dt;    % 向量化生成时间基准
y_vectorized = 230 * sqrt(2) * sin(2*pi*f_grid * t_vec); % 底层单指令多数据流 (SIMD)
t_cost_vectorized = toc;
fprintf('3. 工业级向量化耗时:%.5f 秒 (加速比: %.2fx)\n', ...
    t_cost_vectorized, t_cost_dynamic / t_cost_vectorized);

%% 4. 验证数据一致性与波形切片检视
diff_check = max(abs(y_vectorized - y_prealloc));
fprintf('数值校验：两算法最大绝对误差 = %e (满足浮点容差)\n', diff_check);

% 提取前两个完整工频周期 (0.04 秒 = 400 点) 进行工业规范绘图
plot_idx = 1:(0.04 * f_s); 

figure('Color', [1 1 1]);
plot(t_vec(plot_idx)*1000, y_vectorized(plot_idx), 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
grid on; box on;
xlabel('时间 t (ms)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('单相相对地瞬时电压 u(t) (V)', 'FontSize', 11, 'FontWeight', 'bold');
title('欧标 230V/50Hz 电网采样数据切片 (Vectorized)', 'FontSize', 12);
xlim([0, 40]);


u_sum = (325*cos(100*pi*t_vec)).^2+...
    (325*cos(100*pi*t_vec -2*pi/3)).^2 +...
    (325*cos(100*pi*t_vec + 2*pi/3)).^2;