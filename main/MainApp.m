classdef MainApp < matlab.apps.AppBase
    properties (Access = public)
        V10UIFigure       matlab.ui.Figure
        EditField_2       matlab.ui.control.EditField
        Panel_3           matlab.ui.container.Panel
        Button_8          matlab.ui.control.Button
        Button_2          matlab.ui.control.Button
        Panel_2           matlab.ui.container.Panel
        EditField_angle   matlab.ui.control.NumericEditField
        Label_5           matlab.ui.control.Label
        cleanData         matlab.ui.control.Button
        cleanPlot         matlab.ui.control.Button
        EditField         matlab.ui.control.EditField
        Label_2           matlab.ui.control.Label
        Button            matlab.ui.control.Button
        DropDown          matlab.ui.control.DropDown
        Label             matlab.ui.control.Label
        Panel             matlab.ui.container.Panel
        EditField_result  matlab.ui.control.EditField
        Label_3           matlab.ui.control.Label
        Button_5          matlab.ui.control.Button
        Button_4          matlab.ui.control.Button
        Button_3          matlab.ui.control.Button
        UIAxes_5          matlab.ui.control.UIAxes
        UIAxes_4          matlab.ui.control.UIAxes
        UIAxes_3          matlab.ui.control.UIAxes
        UIAxes_2          matlab.ui.control.UIAxes
        UIAxes            matlab.ui.control.UIAxes
    end
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end
    properties (Access = private)
        tumor_boundary = []
        correctUsername = 'admin'
        correctPassword = '123456'
        controller = 4
        simulationData
        dx = 0.2e-3
        dy = 0.2e-3
        Nx = 400
        Ny = 400
        folderPath
    end
    methods (Access = private)
        function rootPath = getProjectRoot(app)
            rootPath = fileparts(fileparts(mfilename('fullpath')));
        end
        function addProjectPaths(app)
            rootPath = getProjectRoot(app);
            addpath(genpath(fullfile(rootPath, 'drl_pid')));
            addpath(fullfile(rootPath, 'main'));
        end
        function onRunButtonPushed(app, event)
            runUltrasoundSimulation(app)
        end
        function plot_tumor_boundary(app)
            x_values = (0:app.Nx-1) * app.dx * 1000
            y_values = (0:app.Ny-1) * app.dy * 1000
            new_mask_50 = ones(400,400) * 37
            [B, ~] = bwboundaries(app.tumor_boundary, 'noholes')
            boundary = B{1}
            new_tumor_boundary = zeros(app.Nx, app.Ny)
            for i = 1:size(boundary,1)
                new_tumor_boundary(boundary(i,1), boundary(i,2)) = 2
            end
            ax = app.UIAxes_5
            imagesc(ax, x_values, y_values, new_mask_50)
            hold(ax, 'on')
            h2 = contour(ax, x_values, y_values, new_tumor_boundary, [1 1], 'k', 'LineWidth', 2)
            axis(ax, 'image')
            xlabel(ax, '距离(mm)')
            ylabel(ax, '距离(mm)')
            title(ax, '前列腺形状')
            drawnow
        end
        function plotThermalMap(app, x_values, y_values, mask_52, tumor_boundary, tt, data_abliation)
            new_mask_50 = mask_52
            new_mask_50(new_mask_50 == 0) = 37
            [B, ~] = bwboundaries(tumor_boundary, 'noholes')
            boundary = B{1}
            new_tumor_boundary = zeros(app.Nx, app.Ny)
            for i = 1:size(boundary,1)
                new_tumor_boundary(boundary(i,1), boundary(i,2)) = 2
            end
            ax = app.UIAxes
            imagesc(ax, x_values, y_values, new_mask_50)
            hold(ax, 'on')
            axis(ax, 'image')
            xlabel(ax, '距离(mm)')
            ylabel(ax, '距离(mm)')
            title(ax, ['温度分布（' num2str(size(data_abliation, 2)) 's）'])
            low_T = 20
            hight_T = 100
            cb = colorbar(ax)
            ylabel(cb, '[degC]')
            clim(ax, [low_T, hight_T])
            h3 = contour(ax, x_values, y_values, tt, [1 1], 'c', 'LineWidth', 2)
            n = 256
            split_point = round((51 - low_T) / (hight_T - low_T) * n)
            blue_to_light_blue = [linspace(0,0,split_point)', linspace(0,0.8,split_point)', linspace(1,1,split_point)']
            yellow_to_red = [linspace(1,1,n-split_point)', linspace(1,0,n-split_point)', linspace(0,0,n-split_point)']
            custom_cmap = [blue_to_light_blue; yellow_to_red]
            colormap(ax, jet(256))
            drawnow
        end
        function plotThermalMap1(app, x_values, y_values, mask_52, tumor_boundary, tt)
            new_mask_50 = mask_52
            new_mask_50(new_mask_50 == 0) = 37
            [B, ~] = bwboundaries(tumor_boundary, 'noholes')
            boundary = B{1}
            new_tumor_boundary = zeros(app.Nx, app.Ny)
            for i = 1:size(boundary,1)
                new_tumor_boundary(boundary(i,1), boundary(i,2)) = 2
            end
            ax = app.UIAxes_2
            imagesc(ax, x_values, y_values, new_mask_50)
            hold(ax, 'on')
            axis(ax, 'image')
            xlabel(ax, '距离(mm)')
            ylabel(ax, '距离(mm)')
            title(ax, '消融区域')
            low_T = 20
            hight_T = 100
            cb = colorbar(ax)
            ylabel(cb, '[degC]')
            clim(ax, [low_T, hight_T])
            h1 = contour(ax, x_values, y_values, mask_52, [55 55], 'r', 'LineWidth', 2, 'LineStyle', '-')
            h2 = contour(ax, x_values, y_values, new_tumor_boundary, [1 1], 'k', 'LineWidth', 2)
            h3 = contour(ax, x_values, y_values, tt, [1 1], 'c', 'LineWidth', 2)
            n = 256
            split_point = round((51 - low_T) / (hight_T - low_T) * n)
            blue_to_light_blue = [linspace(0,0,split_point)', linspace(0,0.8,split_point)', linspace(1,1,split_point)']
            yellow_to_red = [linspace(1,1,n-split_point)', linspace(1,0,n-split_point)', linspace(0,0,n-split_point)']
            custom_cmap = [blue_to_light_blue; yellow_to_red]
            colormap(ax, custom_cmap)
            drawnow
        end
        function plotPower(app, data_abliation)
            ax = app.UIAxes_3
            plot(ax, data_abliation(1,:))
            hold(ax, 'on')
            axis(ax, 'tight')
            ylim(ax, [0 4])
            xlabel(ax, '时间(s)')
            ylabel(ax, '功率(P)')
            title(ax, '功率输出')
            hold(ax, 'off')
        end
        function plotRot(app, data_abliation)
            ax = app.UIAxes_4
            plot(ax, data_abliation(6,:))
            hold(ax, 'on')
            axis(ax, 'tight')
            ylim(ax, [0 40/60])
            xlabel(ax, '时间(s)')
            ylabel(ax, '旋转速度(P)')
            title(ax, '旋转速度输出')
            hold(ax, 'off')
        end
        function updateProgressUI(app, pct)
            if ~isfinite(pct); pct = 0; end
            pct = max(0, min(1, pct))
            persistent lastT lastPct
            if isempty(lastT); lastT = tic; end
            if isempty(lastPct); lastPct = -1; end
            if toc(lastT) > 0.05 || pct - lastPct >= 0.005 || pct == 0 || pct == 1
                app.EditField.Value = sprintf('程序已进行：%.1f%%', pct*100)
                if isprop(app,'PB_Fill') && ~isempty(app.PB_Fill) && isvalid(app.PB_Fill)
                    app.PB_Fill.Position(3) = pct
                    if isprop(app,'PB_Label') && ~isempty(app.PB_Label) && isvalid(app.PB_Label)
                        app.PB_Label.Text = sprintf('%.1f%%', pct*100)
                    end
                end
                if pct >= 1
                    app.EditField.BackgroundColor = [0.7 1.0 0.7]
                else
                    app.EditField.BackgroundColor = [0.9412 0.9412 0.9412]
                end
                drawnow limitrate
                lastT = tic;
                lastPct = pct;
            end
        end
        function ok = checkDataReady(app)
            ok = true
            if isempty(app.tumor_boundary)
                uialert(app.V10UIFigure, '请先导入前列腺形状！', '未导入数据', 'Icon', 'error', 'Modal', true)
                ok = false
                return
            end
            if isempty(app.simulationData)
                uialert(app.V10UIFigure, '请先运行消融！', '未进行消融', 'Icon', 'error', 'Modal', true)
                ok = false
                return
            end
        end
        function T_final = runUltrasoundSimulation(app)
            clc;
            clearvars -except app;
            tumor_dx = 0.00;
            h_dx = 0.00;     % [m]
            app.EditField.Value = sprintf('开始预加热');
            drawnow limitrate
            frequencies = [2, 3, 6, 10];
            Q_data_all = cell(1, length(frequencies));  % 用cell数组按顺序存储Q
            for i = 1:length(frequencies)
                freq = frequencies(i);
                fileName = sprintf('Q_1600_005mm_down_400_02mm_%dmhz.mat', freq);
                filePath = fullfile(app.folderPath, fileName);
                if isfile(filePath)
                    temp = load(filePath, 'Q');  % 只加载变量Q
                    Q_data_all{i} = temp.Q;
                else
                    warning('File not found: %s', filePath);
                    Q_data_all{i} = [];  % 或者使用 NaN, 或者 continue
                end
            end
            kgrid = kWaveGrid(app.Nx, app.dx, app.Ny, app.dy);
            karray = kWaveArray('BLITolerance', 0.05, 'UpsamplingRate', 10);
            line_diameter = 0.004; % [m]
            mask_diameter = 0.006; % [m]
            tomur_diameter = 0.030; % [m] 直径
            arc_diameter = 0.036;  %[m]
            x_start = int32 (app.Nx/2 - (mask_diameter / app.dx)/2);
            x_end = int32 (app.Nx/2 + (mask_diameter / app.dx)/2);
            y_start = int32 (app.Ny/2 - (mask_diameter / app.dy)/2);
            y_end = int32 (app.Ny/2 + (mask_diameter / app.dy)/2);
            distance_min = 0.005;
            distance_max = 0.036;
            max_temp_min = 37;
            max_temp_max = 90;
            output1_min = 0;
            output1_max = 4;
            output2_min = 8/60; % 即 0.1333
            output2_max = 2;
            min_dist = -6;
            max_dist = 4;
            karray.addLineElement([ -h_dx,-line_diameter/2],[ -h_dx,0]);    %m
            karray.addLineElement([ -h_dx,0],[ -h_dx,line_diameter/2]);
            mask = karray.getArrayBinaryMask(kgrid);
            tt_center_x = app.Nx/2 + 1 - (h_dx + tumor_dx) / app.dx;
            tt_center_y = app.Ny / 2;
            tt_center = [tt_center_x, tt_center_y];
            tt = Boundary(makeDisc(app.Nx, app.Ny,tt_center_x,tt_center_y, mask_diameter/app.dx/2), app.Nx, app.Ny, 1);%设置冷却液
            center_to_boundary_2mhz = zeros(app.Nx,app.Ny);
            center_to_boundary_2mhz(app.Nx/2 + 1:app.Nx,floor(app.Ny / 2 - line_diameter/4 / app.dx)) = 1;
            center_to_boundary_2mhz(app.Nx/2,floor(app.Ny / 2 - line_diameter/4 / app.dx)) = 2;
            center_to_boundary_3mhz = zeros(app.Nx,app.Ny);
            center_to_boundary_3mhz(app.Nx/2 + 1:app.Nx,floor(app.Ny / 2 +line_diameter/4 / app.dx)) = 1;
            center_to_boundary_3mhz(app.Nx/2,floor(app.Ny / 2 + line_diameter/4 / app.dx))  = 2;
            center_to_boundary_6mhz = zeros(app.Nx,app.Ny);
            center_to_boundary_6mhz(app.Nx/2 + 1:app.Nx,app.Ny / 2)  = 1;
            center_to_boundary_6mhz(app.Nx/2,app.Ny/2) = 2;
            center_to_boundary_10mhz = zeros(app.Nx,app.Ny);
            center_to_boundary_10mhz(app.Nx/2 + 1:app.Nx,floor(app.Ny / 2 +line_diameter/4 / app.dx))  = 1;
            center_to_boundary_10mhz(app.Nx/2,floor(app.Ny / 2 +line_diameter/4 / app.dx)) = 2;
            source.Q = 0; %热沉积的体积速率
            source.T0 = 37*ones(app.Nx,app.Ny);
            medium.density  = 1000;     % [kg/m^3]C AAAAAA
            medium.thermal_conductivity = 0.5;      % [W/(m.K)]
            medium.specific_heat        = 3.0581e+03;     % [J/(kg.K)]
            convection_coefficient      = 500;      %热对流暂时设置
            medium.blood_density = 1050; % 血液密度，单位：kg/m^3
            medium.blood_specific_heat = 3700; % 血液比热容，单位：J/kg/K
            medium.blood_perfusion_rate = 0.0048; % 血液灌注率，单位：m^3/s
            medium.blood_ambient_temperature = 37; % 血液环境温度，单位：°C
            input_args = {'PlotSim',true, 'Sensor_Mask',tt , 'Convection_Coefficient', ...
                convection_coefficient, 'tt_center_x', tt_center_x};
            kdiff = kWaveDiffusion(kgrid, medium, source, [], input_args{:});
            dt = 0.1;
            time = 1; %s秒
            t_once = 1;%每次旋转加热时间
            kdiff.Q = 0;
            rot_index = 1;
            rot_index_rot = 0;
            T_scale = zeros(2,30);
            center_to_boundary = center_to_boundary_6mhz;
            mask_52 = zeros(app.Nx,app.Ny);
            app.tumor_boundary(app.tumor_boundary == 2) = 0; %全腺
            app.tumor_boundary(app.tumor_boundary == 1) = 2;
            app.tumor_boundary(app.tumor_boundary == 3) = 0;
            dist = 0;
            rot_index = 1;
            center_initial = center_to_boundary;
            [angle_post_all,angle_dist_all,~] = angle_all(center_to_boundary,app.tumor_boundary,app.Nx,app.Ny,app.dx);
            dist(1) = 0;
            dist(2) = app.EditField_angle;  %结束角度
            rot_index_rot = dist(1);
            x_values = (0:kgrid.Nx-1) * kgrid.dx * 1000;  % x轴物理位置（以毫米为单位）
            y_values = (0:kgrid.Ny-1) * kgrid.dy * 1000;  % y轴物理位置（以毫米为单位）
            preheatStatus = 1;
            mainheatStatus = 0;
            [e_all_take,T_scale,mhz,mask_52] = kdiff.takeTimeStep(round(3000 / dt), dt, t_once, dist(end), 22, app.tumor_boundary ...
                ,center_to_boundary,tt_center,4,rot_index_rot,T_scale,preheatStatus,mask_52,0,Q_data_all);
            rootPath = getProjectRoot(app);
            IL_DRL = load(fullfile(rootPath, 'agent', 'Agent1000.mat')).saved_agent;
            rot_p_agent_bc = load(fullfile(rootPath, 'agent', 'Agent325.mat')).saved_agent;
            rot_index = 1;
            dist_new =e_all_take(6);
            e_all_take(6) = floor(e_all_take(6)*1000)/1000;
            e_all_take(6) = min(e_all_take(6),0.025);
            [ed,ed_now,~] = error_end(rot_index_rot,center_to_boundary,app.tumor_boundary,mask_52,app.Nx,app.Ny,app.dx);
            [normalize_angle_dist,normalize_angle_T] = angle_post_start(rot_index_rot,kdiff.T,angle_dist_all,angle_post_all,distance_min,distance_max);
            e_bindary = 55 -  e_all_take(1); % 更新误差
            e_DRL = [normalize_distance(e_all_take(6),distance_min,distance_max),...
                normalize_temp_error(53 - e_all_take(1),4),normalize_max_temp(e_all_take(2),...
                max_temp_min,max_temp_max),normalize_dist_error(ed_now*1e3,min_dist,max_dist)];
            e_IL_DRL = [normalize_angle_dist, normalize_angle_T,normalize_max_temp(e_all_take(2),...
                max_temp_min,max_temp_max),normalize_dist_error(ed,min_dist,max_dist)];
            z = 0;
            selectedValue = app.controller;
            while rot_index_rot <= dist(end)
                flag = 1;
                switch selectedValue
                    case 1
                        if e_all_take(2)  > 90
                            P = 0;
                            agent_rot = 8/60;
                        elseif  e_all_take(2)  <= 90 && e_bindary > 0
                            P = 4;
                            agent_rot = 8/60;
                        elseif  e_all_take(2)  <= 90 && e_bindary <= 0
                            P = 0;
                            agent_rot = 40/60;
                        end
                    case 2
                        e_compensated = e_bindary;
                        if z > -10 && z < 10
                            z = z +  e_compensated ;
                        elseif z <= -10 && e_compensated > 0
                            z = z +  e_compensated;
                        elseif z >= 10 && e_compensated < 0
                            z = z +  e_compensated;
                        end
                        z = max(-10,min(z,10));
                        Kp = 2.5;
                        Ki = 0.07;
                        P_pid = Kp*e_bindary + Ki*z;
                        P = max(0, min(P_pid, 4));
                        if e_all_take(2)  > 90
                            agent_rot = 8/60;
                        elseif  e_all_take(2)  <= 90 && e_bindary > 0
                            agent_rot = 8/60 + 28 * (4 - P);
                            agent_rot = min(2,agent_rot);
                        elseif  e_all_take(2)  <= 90 && e_bindary <= 0
                            agent_rot = 2;
                        end
                    case 3
                        agent = rot_p_agent_bc;
                        Action = getAction(agent, e_DRL);
                        P = Action{1}(1,1);
                        P = max(0, min(P, 1));
                        P = P * (output1_max - output1_min) + output1_min;
                        P = max(0, min(P, 4));
                        agent_rot = Action{1}(2,1);
                        agent_rot = max(0, min(agent_rot, 1));
                        agent_rot = agent_rot * (output2_max - output2_min) + output2_min;
                        agent_rot = max(8/60, min(agent_rot, 2));
                    case 4
                        center_to_boundary = center_to_boundary_6mhz;
                        agent = IL_DRL;
                        Action = getAction(agent, e_IL_DRL);
                        P = Action{1}(1,1);
                        P = max(0, min(P, 1));
                        P = P * (output1_max - output1_min) + output1_min;
                        P = max(0, min(P, 4));
                        agent_rot = Action{1}(2,1);
                        agent_rot = max(0, min(agent_rot, 1));
                        agent_rot = agent_rot * (output2_max - output2_min) + output2_min;
                        agent_rot = max(8/60, min(agent_rot, 2));
                end
                if e_all_take(2) > 90 || e_all_take(6) < 0.005
                    P = 0;
                end
                data_abliation(1,rot_index) = P;
                data_abliation(2,rot_index) = mhz;
                [e_all_take, T_scale, mhz, mask_52] = kdiff.takeTimeStep(round(time / dt), dt, t_once, dist(end), 22, app.tumor_boundary, ...
                    center_to_boundary, tt_center, P, rot_index_rot, T_scale, mainheatStatus, mask_52,agent_rot,Q_data_all);
                plotThermalMap(app, x_values, y_values, mask_52, app.tumor_boundary, tt, data_abliation);
                plotThermalMap1(app, x_values, y_values, mask_52, app.tumor_boundary, tt);
                data_abliation(3,rot_index) = e_all_take(1);
                data_abliation(4,rot_index) = e_all_take(2);
                data_abliation(5,rot_index) = e_all_take(5);
                data_abliation(6,rot_index) = e_all_take(6);
                rot_index_rot = e_all_take(3);
                plotPower(app, data_abliation);
                plotRot(app, data_abliation);
                dist_new = e_all_take(6);
                e_all_take(6) = floor(e_all_take(6)*1000)/1000;
                e_all_take(6) = min(e_all_take(6),0.025);
                [ed,ed_now,~] = error_end(rot_index_rot,center_to_boundary,app.tumor_boundary,mask_52,app.Nx,app.Ny,app.dx);
                [normalize_angle_dist,normalize_angle_T] = angle_post(rot_index_rot,mask_52,kdiff.T,angle_dist_all,angle_post_all,distance_min,distance_max);
                e_bindary = 55 -  e_all_take(1); % 更新误差
                e_DRL = [normalize_distance(e_all_take(6),distance_min,distance_max),...
                    normalize_temp_error(53 - e_all_take(1),4),normalize_max_temp(e_all_take(2),...
                    max_temp_min,max_temp_max),normalize_dist_error(ed_now*1e3,min_dist,max_dist)];
                e_IL_DRL = [normalize_angle_dist, normalize_angle_T,normalize_max_temp(e_all_take(2),...
                    max_temp_min,max_temp_max),normalize_dist_error(ed,min_dist,max_dist)];
                fprintf('现在是第%d\n', rot_index);
                rot_index = rot_index + 1;
                pct = rot_index_rot / dist(end);          % 计算比例
                updateProgressUI(app, pct);               % 统一节流更新
            end
            [~,~,error_all] = error_end(rot_index_rot,center_to_boundary,app.tumor_boundary,mask_52,app.Nx,app.Ny,app.dx);
            app.simulationData.mask_52 = mask_52;
            app.simulationData.e_all_take = e_all_take;
            app.simulationData.data_abliation = data_abliation;
            app.simulationData.kdiff = kdiff;
            app.simulationData.error_all = error_all;
            function [angle_post_all,angle_dist_all,center_initial_all] = angle_all(center_to_boundary,tumor_boundary,Nx,Ny,dx) %1是1，360是0
                angle_post_all = [];
                angle_dist_all = [];
                center_initial_all = {};
                dist_to_max_toumor_boundary = 0;
                temp = [];
                temp(1,1) = 1;
                temp(2,1) = 1;
                for i = 1:ceil(360)
                    center_initial =  imrotate(center_to_boundary, i ,"nearest","crop");
                    center_initial_all{i} = center_initial;
                    [x,y] = find((center_initial == 1)&(tumor_boundary == 2));
                    if isempty(x)
                        disp('没有读取到边界数据');
                    else
                        dist_to_max_toumor_boundary  = norm([x(1,1),y(1,1)] - [Nx/2,Ny/2]) * dx; %肿瘤边界到中点的距离
                        for i1 = 1:numel(x)
                            dist_find_boundary_max = norm([x(i1,1),y(i1,1)] - [Nx/2,Ny/2]) * dx;
                            if(dist_find_boundary_max >= dist_to_max_toumor_boundary)
                                dist_to_max_toumor_boundary = dist_find_boundary_max;
                                temp(1,1) = x(i1,1);
                                temp(2,1) = y(i1,1);
                            end
                        end
                    end
                    angle_dist_all = [angle_dist_all dist_to_max_toumor_boundary];
                    angle_post_all = [angle_post_all temp];
                end
            end
            function [angle_dist,angle_T] = angle_post_start(rot_index_rot,T,angle_dist_all,angle_post_all,distance_min,distance_max)
                angle_dist = [];
                angle_T = [];
                dist_to_max_toumor_boundary = 0;
                temp_x = 1;
                temp_y = 1;
                angle = floor(rot_index_rot);
                for i = angle-15:angle+15
                    n = i;
                    if i <= 0
                        n = i + 360;
                    end
                    if i > 360
                        n = i - 360;
                    end
                    angle_dist = [angle_dist angle_dist_all(n)];
                    angle_T = [angle_T T(angle_post_all(1,n),angle_post_all(2,n))];
                end
                angle_dist = normalize_distance(angle_dist,distance_min,distance_max);
                angle_T = normalize_temp_error(53 - angle_T,4);
            end
            function [angle_dist,angle_T] = angle_post(rot_index_rot,mask,T,angle_dist_all,angle_post_all,distance_min,distance_max)
                angle_dist = [];
                angle_T = [];
                dist_to_max_toumor_boundary = 0;
                temp_x = 1;
                temp_y = 1;
                angle = floor(rot_index_rot);
                if angle > 344
                    flag = 1;
                else
                    flag = 0;
                end
                for i = angle-15:angle+15
                    n = i;
                    if i <= 0
                        n = i + 360;
                    end
                    if i > 360
                        n = i - 360;
                    end
                    if flag == 1 && i >= angle
                        angle_dist = [angle_dist angle_dist_all(n)];
                        angle_T = [angle_T T(angle_post_all(1,n),angle_post_all(2,n))];
                    else
                        angle_dist = [angle_dist angle_dist_all(n)];
                        angle_T = [angle_T mask(angle_post_all(1,n),angle_post_all(2,n))];
                    end
                end
                angle_dist = normalize_distance(angle_dist,distance_min,distance_max);
                angle_T = normalize_temp_error(53 - angle_T,4);
            end
            function [ed,ed_now,error_all] = error_end(rot_index_rot,center_initial,mask_52,angle_dist_all,Nx,Ny,dx)
                rot_index_ed = 0;
                rot_index_temp = rot_index_rot;
                if rot_index_rot > 360
                    rot_index_temp = 360;
                end
                for i = 0:ceil(rot_index_temp)
                    rot_index_ed = rot_index_ed + 1;
                    n = i;
                    if i == 0
                        n = 360;
                    end
                    [x1,y1] = find((center_initial == 1) & (mask_52 >= 55)); %肿瘤到消融边界的交点
                    dist_to_max_toumor_boundary  = angle_dist_all(n);
                    if isempty(x1)
                        dist_di(rot_index_ed) = -dist_to_max_toumor_boundary;
                    else
                        dist_max_to_boundary  = norm([x1(1,1),y1(1,1)] - [Nx/2,Ny/2]) * dx; %消融边界到中点的距离
                        for i1 = 1:numel(x1)
                            dist_find_ablition_max = norm([x1(i1,1),y1(i1,1)] - [Nx/2,Ny/2]) * dx;
                            if(dist_find_ablition_max >= dist_max_to_boundary)
                                dist_max_to_boundary = dist_find_ablition_max;
                            end
                        end
                        dist_di(rot_index_ed) =  dist_max_to_boundary - dist_to_max_toumor_boundary; %消融最远距离和肿瘤边界的差
                    end
                end
                ed_now =  dist_di(rot_index_ed);
                dist_di = dist_di * 1e3;
                ed = sum(abs(dist_di)) / rot_index_ed ;
                error_all = dist_di;
            end
            function boundary = Boundary(tt, Nx, Ny, flag)
                %1是换能器，2是肿瘤
                if(flag == 1)
                    for i = 2:1:Nx - 1  %去除多出来的点
                        for j = 2:1:Ny - 1
                            num = 0;
                            num = ~tt(i-1,j) + ~tt(i+1,j) + ~tt(i,j-1) + ~tt(i,j+1);
                            if(num == 3)
                                tt(i,j) = 0;
                            end
                        end
                    end
                    %设置换能器边界
                    for i = 2:1:Nx - 1
                        for j = 2:1:Ny - 1
                            if((tt(i - 1,j) == 1 || tt(i + 1,j) == 1 || tt(i, j + 1) ...
                                    == 1 || tt(i, j - 1) == 1 ) && ~tt(i,j) )
                                tt(i,j) = 2;
                            end
                        end
                    end
                    %设置标记换能器边界类型
                    for i = 2:1:Nx - 1
                        for j = 2:1:Ny - 1
                            if(tt(i,j) == 2)
                                num = ~tt(i-1,j) + ~tt(i+1,j) + ~tt(i,j-1) + ~tt(i,j+1);
                                if(num == 1)
                                    if(~tt(i-1,j)) %上 w
                                        tt(i,j) = 11;
                                    elseif( ~tt(i+1,j))%下 s
                                        tt(i,j) = 12;
                                    elseif( ~tt(i,j-1))%左 a
                                        tt(i,j) = 13;
                                    elseif( ~tt(i,j+1))%右 d
                                        tt(i,j) = 14;
                                    end
                                elseif(num == 2)
                                    if(~tt(i,j - 1) && ~tt(i-1,j)) %左上w
                                        tt(i,j) = 21;
                                    elseif(~tt(i,j + 1) && ~tt(i-1,j)) %右上 a
                                        tt(i,j) = 23;
                                    elseif(~tt(i,j - 1) && ~tt(i+1,j)) %左下s
                                        tt(i,j) = 22;
                                    else
                                        tt(i,j) = 24; %右下 d
                                    end
                                end
                            end
                        end
                    end
                    boundary = tt;
                end
                if(flag == 2)
                    for i = 2:1:Nx - 1  %去除多出来的点
                        for j = 2:1:Ny - 1
                            num = 0;
                            num = ~tt(i-1,j) + ~tt(i+1,j) + ~tt(i,j-1) + ~tt(i,j+1);
                            if(num == 3)
                                tt(i,j) = 0;
                            end
                        end
                    end
                    %设置肿瘤边界
                    for i = 2:1:Nx - 1
                        for j = 2:1:Ny - 1
                            if((tt(i - 1,j) == 1 || tt(i + 1,j) == 1 || tt(i, j + 1) ...
                                    == 1 || tt(i, j - 1) == 1 ) && ~tt(i,j) )
                                tt(i,j) = 2;
                            end
                        end
                    end
                    boundary = tt;
                end
            end
            function distance_norm = normalize_distance(distance, distance_min, distance_max)
                % 距离归一化 (Min-Max归一化)
                distance_norm = (distance - distance_min) / (distance_max - distance_min);
            end
            function temp_error_norm = normalize_temp_error(temp_error, max_range)
                % 温度误差归一化
                temp_error_norm = temp_error / max_range;
                temp_error_norm(temp_error_norm > 1) = 1;
                temp_error_norm(temp_error_norm < -1) = -1;
            end
            function max_temp_norm = normalize_max_temp(max_temp, max_temp_min, max_temp_max)
                % 最高温度归一化（平方增强对高温的敏感性）
                max_temp_norm = ((max_temp - max_temp_min) / (max_temp_max - max_temp_min)).^2;
            end
            function dist_error_norm = normalize_dist_error(temp_error, min_dist, max_dist)
                % 温度误差归一化
                dist_error_norm = (temp_error - min_dist) / (max_dist - min_dist) * 2 - 1;
                dist_error_norm(dist_error_norm < -1) = -1;
                dist_error_norm(dist_error_norm > 1) = 1;
            end
        end
        
    end    
    % Callbacks that handle component events
    methods (Access = private)  
        % Button pushed function: Button
        function ButtonPushed(app, event)
            addProjectPaths(app);
            % 检查是否已导入前列腺形状
            if isempty(app.tumor_boundary)
                % 弹出错误提示框
                uialert(app.V10UIFigure, '请先导入前列腺形状！', '未导入数据', ...
                    'Icon', 'error', ...
                    'Modal', true);
                return;  % 终止函数执行
            end
            runUltrasoundSimulation(app);
        end
        % Button pushed function: Button_2
        function Button_2Pushed2(app, event)
            % 弹出文件选择对话框
            [file, path] = uigetfile('*.mat', '选择前列腺形状文件');
            if isequal(file,0)
                % 用户点击取消
                disp('用户取消了文件选择');
                return;
            end
            % 拼接完整路径
            fullFilePath = fullfile(path, file);
            % 加载文件中的变量 M_resized
            data = load(fullFilePath, 'M_resized');
            if isfield(data, 'M_resized')
                app.tumor_boundary = data.M_resized;  % 保存到app的属性中
                uialert(app.V10UIFigure, '导入成功！', '导入成功', ...
                    'Icon', 'success', ...
                    'Modal', true);
            else
                uialert(app.V10UIFigure, '所选文件中没有 M_resized 变量！', '错误');
            end
            plot_tumor_boundary(app)
        end
        % Value changed function: DropDown
        function DropDownValueChanged(app, event)
            selectedValue = app.DropDown.Value;
            switch selectedValue
                case '二进制控制器'
                    disp('已选择二进制控制器');
                    app.controller = 1;
                case 'PID控制器'
                    disp('已选择PID控制器');
                    app.controller = 2;
                case 'DRL控制器'
                    disp('已选择PID控制器');
                    app.controller = 3;
                case 'IL-DRL控制器'
                    disp('已选择IL-DRL控制器');
                    app.controller = 4;
            end
        end
        % Button pushed function: Button_3
        function SaveButton_P_Rot(app, event)
            if ~checkDataReady(app)
                return; % 数据没准备好，直接退出
            end
            % 弹出文件保存对话框，让用户选择保存路径
            [file, path] = uiputfile('*.mat', '保存控制参数仿真数据为...');
            if isequal(file, 0)
                % 用户点击取消
                disp('用户取消了保存');
                return;
            end
            % 拼接完整路径
            fullFilePath = fullfile(path, file);
            % 获取仿真数据
            simulationData = app.simulationData.data_abliation;
            % 保存仿真数据到.mat文件
            try
                save(fullFilePath, 'simulationData');
                disp(['控制参数仿真数据已保存到 ' fullFilePath]);
                app.EditField_result.Value = sprintf('控制参数保存完成');
                % 保存成功，弹出成功提示框
                uialert(app.V10UIFigure, '控制参数仿真数据已成功保存！', '保存成功', 'Icon', 'success');
            catch
                % 如果保存失败，弹出错误提示框
                uialert(app.V10UIFigure, '保存数据时发生错误！', '保存失败', 'Icon', 'error');
            end
        end
        % Button pushed function: Button_4
        function SaveButton_T(app, event)
            if ~checkDataReady(app)
                return; % 数据没准备好，直接退出
            end
            % 弹出文件保存对话框，让用户选择保存路径
            [file, path] = uiputfile('*.mat', '保存温度场仿真数据为...');
            if isequal(file, 0)
                % 用户点击取消
                disp('用户取消了保存');
                return;
            end
            % 拼接完整路径
            fullFilePath = fullfile(path, file);
            % 获取仿真数据
            simulationData = app.simulationData.mask_52;
            % 保存仿真数据到.mat文件
            try
                save(fullFilePath, 'simulationData');
                disp(['温度场仿真数据已保存到 ' fullFilePath]);
                app.EditField_result.Value = sprintf('温度场数据保存完成');
                % 保存成功，弹出成功提示框
                uialert(app.V10UIFigure, '温度场仿真数据已成功保存！', '保存成功', 'Icon', 'success');
            catch
                % 如果保存失败，弹出错误提示框
                uialert(app.V10UIFigure, '保存数据时发生错误！', '保存失败', 'Icon', 'error');
            end
        end
        % Button pushed function: Button_5
        function SaveButton_error(app, event)
            if ~checkDataReady(app)
                return; % 数据没准备好，直接退出
            end
            % 弹出文件保存对话框，让用户选择保存路径
            [file, path] = uiputfile('*.mat', '保存消融误差仿真数据为...');
            if isequal(file, 0)
                % 用户点击取消
                disp('用户取消了保存');
                return;
            end
            % 拼接完整路径
            fullFilePath = fullfile(path, file);
            % 获取仿真数据
            simulationData = app.simulationData.error_all;
            % 保存仿真数据到.mat文件
            try
                save(fullFilePath, 'simulationData');
                disp(['消融误差仿真数据已保存到 ' fullFilePath]);
                app.EditField_result.Value = sprintf('消融误差数据保存完成');
                % 保存成功，弹出成功提示框
                uialert(app.V10UIFigure, '消融误差仿真数据已成功保存！', '保存成功', 'Icon', 'success');
            catch
                % 如果保存失败，弹出错误提示框
                uialert(app.V10UIFigure, '保存数据时发生错误！', '保存失败', 'Icon', 'error');
            end
        end
        % Button pushed function: cleanPlot
        function clean_plot(app, event)
            cla(app.UIAxes,"reset");
            cla(app.UIAxes_2,"reset");
            cla(app.UIAxes_3,"reset");
            cla(app.UIAxes_4,"reset");
            uialert(app.V10UIFigure, '清除绘图成功', '清除绘图成功', ...
                'Icon', 'success', ...
                'Modal', true);
        end
        % Button pushed function: cleanData
        function clear_data(app, event)
            app.tumor_boundary = [];   % 初始化为空数组
            app.controller = 4;
            app.simulationData = [];
            app.EditField.BackgroundColor = [0.9412 0.9412 0.9412]; % 你原来的灰色
            drawnow limitrate
            uialert(app.V10UIFigure, '清除缓存数据成功', '清除缓存数据成功', ...
                'Icon', 'success', ...
                'Modal', true);
        end
        % Button pushed function: Button_8
        function load_tra(app, event)
            [~, filePath] = uigetfile('*.mat', '选择频率路径');
            if isequal(filePath,0)
                uialert(app.V10UIFigure, '用户未选择路径！', '用户未选择路径', 'Icon', 'error');
                return;
            end
            uialert(app.V10UIFigure, '换能器频率导入成功', '换能器频率导入成功', ...
                'Icon', 'success', ...
                'Modal', true);
            app.folderPath = filePath;
        end
    end    
    % Component initialization
    methods (Access = private)       
        % Create UIFigure and components
        function createComponents(app)           
            % Get the file path for locating images
            pathToMLAPP = getProjectRoot(app);            
            % Create V10UIFigure and hide until all components are created
            app.V10UIFigure = uifigure('Visible', 'off');
            app.V10UIFigure.Color = [0.9412 0.9412 0.9412];
            app.V10UIFigure.Position = [100 100 768 744];
            app.V10UIFigure.Name = '基于强化学习的前列腺超声消融仿真平台V1.0';
            app.V10UIFigure.Icon = fullfile(pathToMLAPP, 'data', 'icon.png');            
            % Create UIAxes
            app.UIAxes = uiaxes(app.V10UIFigure);
            title(app.UIAxes, '消融温度分布')
            xlabel(app.UIAxes, '距离(mm)')
            ylabel(app.UIAxes, '距离(mm)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontWeight = 'bold';
            app.UIAxes.XTick = [0 0.2 0.4 0.6 0.8 1];
            app.UIAxes.TitleFontWeight = 'bold';
            app.UIAxes.Position = [69 237 251 183];           
            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.V10UIFigure);
            title(app.UIAxes_2, '消融区域(T>=55℃)')
            xlabel(app.UIAxes_2, '距离(mm)')
            ylabel(app.UIAxes_2, '距离(mm)')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.FontWeight = 'bold';
            app.UIAxes_2.XTick = [0 0.2 0.4 0.6 0.8 1];
            app.UIAxes_2.TitleFontWeight = 'bold';
            app.UIAxes_2.Position = [441 237 251 183];           
            % Create UIAxes_3
            app.UIAxes_3 = uiaxes(app.V10UIFigure);
            title(app.UIAxes_3, '功率输出')
            xlabel(app.UIAxes_3, '时间(s)')
            ylabel(app.UIAxes_3, '功率(P)')
            zlabel(app.UIAxes_3, 'Z')
            app.UIAxes_3.FontWeight = 'bold';
            app.UIAxes_3.TitleFontWeight = 'bold';
            app.UIAxes_3.Position = [69 34 251 183];            
            % Create UIAxes_4
            app.UIAxes_4 = uiaxes(app.V10UIFigure);
            title(app.UIAxes_4, '旋转速度输出')
            xlabel(app.UIAxes_4, '时间(s)')
            ylabel(app.UIAxes_4, '旋转速度(°)')
            zlabel(app.UIAxes_4, 'Z')
            app.UIAxes_4.FontWeight = 'bold';
            app.UIAxes_4.TitleFontWeight = 'bold';
            app.UIAxes_4.SubtitleFontWeight = 'bold';
            app.UIAxes_4.Position = [441 34 251 183];           
            % Create UIAxes_5
            app.UIAxes_5 = uiaxes(app.V10UIFigure);
            title(app.UIAxes_5, '前列腺形状')
            xlabel(app.UIAxes_5, '距离(mm)')
            ylabel(app.UIAxes_5, '距离(mm)')
            zlabel(app.UIAxes_5, 'Z')
            app.UIAxes_5.FontWeight = 'bold';
            app.UIAxes_5.TitleFontWeight = 'bold';
            app.UIAxes_5.Position = [449 534 251 183];           
            % Create Panel
            app.Panel = uipanel(app.V10UIFigure);
            app.Panel.TitlePosition = 'centertop';
            app.Panel.Title = '下载数据区';
            app.Panel.BackgroundColor = [0.7294 0.8824 0.9843];
            app.Panel.FontWeight = 'bold';
            app.Panel.Position = [404 434 345 91];           
            % Create Button_3
            app.Button_3 = uibutton(app.Panel, 'push');
            app.Button_3.ButtonPushedFcn = createCallbackFcn(app, @SaveButton_P_Rot, true);
            app.Button_3.FontWeight = 'bold';
            app.Button_3.Position = [13 38 100 23];
            app.Button_3.Text = '保存控制参数';        
            % Create Button_4
            app.Button_4 = uibutton(app.Panel, 'push');
            app.Button_4.ButtonPushedFcn = createCallbackFcn(app, @SaveButton_T, true);
            app.Button_4.FontWeight = 'bold';
            app.Button_4.Position = [123 38 100 23];
            app.Button_4.Text = '保存温度场';    
            % Create Button_5
            app.Button_5 = uibutton(app.Panel, 'push');
            app.Button_5.ButtonPushedFcn = createCallbackFcn(app, @SaveButton_error, true);
            app.Button_5.FontWeight = 'bold';
            app.Button_5.Position = [233 38 100 23];
            app.Button_5.Text = '保存消融误差';
            % Create Label_3
            app.Label_3 = uilabel(app.Panel);
            app.Label_3.BackgroundColor = [0.7294 0.8824 0.9843];
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.FontWeight = 'bold';
            app.Label_3.Position = [33 8 53 22];
            app.Label_3.Text = '保存结果';
            % Create EditField_result
            app.EditField_result = uieditfield(app.Panel, 'text');
            app.EditField_result.FontWeight = 'bold';
            app.EditField_result.Position = [101 8 211 22];     
            % Create Panel_2
            app.Panel_2 = uipanel(app.V10UIFigure);
            app.Panel_2.TitlePosition = 'centertop';
            app.Panel_2.Title = '数据处理区';
            app.Panel_2.BackgroundColor = [0.7294 0.8824 0.9843];
            app.Panel_2.FontWeight = 'bold';
            app.Panel_2.Position = [38 434 356 135];
            % Create Label
            app.Label = uilabel(app.Panel_2);
            app.Label.BackgroundColor = [0.7294 0.8824 0.9843];
            app.Label.HorizontalAlignment = 'right';
            app.Label.FontWeight = 'bold';
            app.Label.Position = [12 82 65 22];
            app.Label.Text = '控制器设置';
            % Create DropDown
            app.DropDown = uidropdown(app.Panel_2);
            app.DropDown.Items = {'二进制控制器', 'PID控制器', 'DRL控制器', 'IL-DRL控制器'};
            app.DropDown.ValueChangedFcn = createCallbackFcn(app, @DropDownValueChanged, true);
            app.DropDown.FontWeight = 'bold';
            app.DropDown.BackgroundColor = [0.9412 0.9412 0.9412];
            app.DropDown.Position = [92 82 114 22];
            app.DropDown.Value = 'IL-DRL控制器';
            % Create Button
            app.Button = uibutton(app.Panel_2, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.FontWeight = 'bold';
            app.Button.Position = [228 82 100 23];
            app.Button.Text = '运行消融';
            % Create Label_2
            app.Label_2 = uilabel(app.Panel_2);
            app.Label_2.BackgroundColor = [0.7294 0.8824 0.9843];
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.FontWeight = 'bold';
            app.Label_2.Position = [38 12 53 22];
            app.Label_2.Text = '消融进度';
            % Create EditField
            app.EditField = uieditfield(app.Panel_2, 'text');
            app.EditField.Position = [106 12 211 22];
            % Create cleanPlot
            app.cleanPlot = uibutton(app.Panel_2, 'push');
            app.cleanPlot.ButtonPushedFcn = createCallbackFcn(app, @clean_plot, true);
            app.cleanPlot.FontWeight = 'bold';
            app.cleanPlot.Position = [106 52 100 23];
            app.cleanPlot.Text = '清空绘图';
            % Create cleanData
            app.cleanData = uibutton(app.Panel_2, 'push');
            app.cleanData.ButtonPushedFcn = createCallbackFcn(app, @clear_data, true);
            app.cleanData.FontWeight = 'bold';
            app.cleanData.Position = [228 52 100 23];
            app.cleanData.Text = '清空缓存数据';
            % Create Label_5
            app.Label_5 = uilabel(app.Panel_2);
            app.Label_5.HorizontalAlignment = 'right';
            app.Label_5.FontWeight = 'bold';
            app.Label_5.Position = [10 52 53 22];
            app.Label_5.Text = '消融角度';
            % Create EditField_angle
            app.EditField_angle = uieditfield(app.Panel_2, 'numeric');
            app.EditField_angle.HorizontalAlignment = 'center';
            app.EditField_angle.FontWeight = 'bold';
            app.EditField_angle.Position = [66 52 30 22];
            app.EditField_angle.Value = 360;
            % Create Panel_3
            app.Panel_3 = uipanel(app.V10UIFigure);
            app.Panel_3.TitlePosition = 'centertop';
            app.Panel_3.Title = '上传数据区';
            app.Panel_3.BackgroundColor = [0.7294 0.8824 0.9843];
            app.Panel_3.FontWeight = 'bold';
            app.Panel_3.Position = [39 601 355 94];
            % Create Button_2
            app.Button_2 = uibutton(app.Panel_3, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @Button_2Pushed2, true);
            app.Button_2.FontWeight = 'bold';
            app.Button_2.Position = [37 18 124 39];
            app.Button_2.Text = '导入前列腺形状';
            % Create Button_8
            app.Button_8 = uibutton(app.Panel_3, 'push');
            app.Button_8.ButtonPushedFcn = createCallbackFcn(app, @load_tra, true);
            app.Button_8.FontWeight = 'bold';
            app.Button_8.Position = [191 18 124 39];
            app.Button_8.Text = '导入换能器频率';
            % Create EditField_2
            app.EditField_2 = uieditfield(app.V10UIFigure, 'text');
            app.EditField_2.HorizontalAlignment = 'center';
            app.EditField_2.FontWeight = 'bold';
            app.EditField_2.Position = [146 720 477 22];
            app.EditField_2.Value = '基于强化学习的前列腺超声消融仿真平台V1.0';
            % Show the figure after all components are created
            app.V10UIFigure.Visible = 'on';
        end
    end
    % App creation and deletion
    methods (Access = public)
        % Construct app
        function app = MainApp
            runningApp = getRunningApp(app);
            % Check for running singleton app
            if isempty(runningApp)
                % Create UIFigure and components
                createComponents(app)
                addProjectPaths(app);
                app.folderPath = fullfile(getProjectRoot(app), 'data');
                % Register the app with App Designer
                registerApp(app, app.V10UIFigure)
            else
                % Focus the running singleton app
                figure(runningApp.V10UIFigure)
                app = runningApp;
            end
            if nargout == 0
                clear app
            end
        end
        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.V10UIFigure)
        end
    end
end
