classdef rot_guiyiout_test_error_abliation < rl.env.MATLABEnvironment
    %ROT_GUIYIOUT_TEST_ERROR_ABLIATION RL environment for ultrasound ablation training.
    %
    % Observation vector:
    %   [31 angular boundary distances, 31 angular boundary temperatures,
    %    normalized maximum temperature, normalized ablation error]
    %
    % Action vector in [0, 1]:
    %   action(1) maps to acoustic power in W.
    %   action(2) maps to rotation speed in degrees/s.

    properties
        Nx = 400;                  % Grid points in x
        Ny = 400;                  % Grid points in y
        dx = 0.2e-3;               % Grid spacing in x [m]
        dy = 0.2e-3;               % Grid spacing in y [m]
        h_dx = 0.00;               % Transducer offset [m]
        tumor_dx = 0.00;
        kgrid;
        karray;
        line_diameter;
        mask_diameter;
        tt_center_x;
        tt_center_y;
        tt_center;
        tt;
        tumor_boundary;
        center_to_boundary;
        source;
        medium;
        rot;                       % Episode terminal rotation angle [deg]
        dt;
        time;                      % Heating step duration [s]
        t_once;                    % Heating duration per rotation step [s]
        input_args;
        kdiff;
        e;
        rot_index;
        P;
        rot_index_rot;             % Current rotation angle [deg]
        e_all_take;
        T_scale;                   % Temperature history
        mhz;
        mask_52;
        agent_rot;
        set_T;

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
        agent_index = [];
        agent_step = [];
        angle_post_all;
        angle_dist_all;
        center_initial_all;
        num_All_m_resized;
        repoRoot;
        trainingShapes;
    end
    
    properties(Access = protected)
        % Initialize internal flag to indicate episode termination
        IsDone = false        
    end

    methods
        % Constructor method creates an instance of the environment.
        function this = rot_guiyiout_test_error_abliation()
            ObservationInfo = rlNumericSpec([64,1]);
            ObservationInfo.Name = 'observation';
            ObservationInfo.Description = 'angular boundary state, maximum temperature, and ablation error';

            ActionInfo = rlNumericSpec([2,1], ...
                'LowerLimit',[0,0]', ...
                'UpperLimit',[1,1]');
            ActionInfo.Name = 'AblationControl';

            this = this@rl.env.MATLABEnvironment(ObservationInfo,ActionInfo);
        end

        % Apply system dynamics for one agent step.
        function [Observation,Reward,IsDone,Info] = step(this,Action)
            Info = [];

            action = min(max(Action, 0), 1);
            this.P = action(1) * (this.output1_max - this.output1_min) + this.output1_min;
            this.agent_rot = action(2) * (this.output2_max - this.output2_min) + this.output2_min;
            this.P = max(this.output1_min, min(this.P, this.output1_max));
            this.agent_rot = max(this.output2_min, min(this.agent_rot, this.output2_max));

            Reward = reward1(this);
            this.rot_index_rot = this.e_all_take(3);
            this.rot_index = this.rot_index + 1;

            [this.e_all_take,this.T_scale,this.mhz,this.mask_52] = this.kdiff.takeTimeStep(round(this.time / this.dt), this.dt, this.t_once, this.rot, 22, this.tumor_boundary ...
                ,this.center_to_boundary,this.tt_center,this.P,this.rot_index_rot,this.T_scale,0,this.mask_52,this.agent_rot,this.set_T);
            [ed,~] = error_end(this);
            [normalize_angle_dist,normalize_angle_T] = angle_post(this);
            this.e = [normalize_angle_dist, normalize_angle_T,normalize_max_temp(this.e_all_take(2),...
                this.max_temp_min,this.max_temp_max),normalize_dist_error(ed,this.min_dist,this.max_dist)];

            Observation = this.e;
            if this.rot_index_rot >= this.rot || this.P < 0 || this.rot_index >= 2000
                Reward = reward1(this);
                IsDone = 1;
                [ed,~] = error_end(this);
                this.agent_index = [this.agent_index, ed];
                this.agent_step = [this.agent_step, this.rot_index];
                fprintf('Episode finished: mean boundary error = %.4f mm, steps = %d\n', ed, this.rot_index);
            else
                IsDone = 0;
            end
            function re = reward1(this)
                max_error = 5;
                [error_dist,error_now] = error_end(this);
                if error_dist <= 0.5
                    rewrd_dist = 2 + 0.5 - error_dist;
                else
                    rewrd_dist = max(0, (1 - (error_dist - 0.5) / (max_error - 0.5))) / 2;
                end
                if this.e_all_take(1) < 51
                    if this.e_all_take(4) * 1000 <= 25
                        rewrd = -1;
                    else
                        rewrd = -0.1;
                    end
                elseif 51 <= this.e_all_take(1) && this.e_all_take(1) <= 54
                    rewrd = min(3, (this.agent_rot - 0.3) * 10) + rewrd_dist * 2;
                else
                    rewrd = this.agent_rot - 2;
                end
                if this.e(3) == 1
                    rewrd = rewrd - 1;
                end
                re = rewrd;
                fprintf('reward=%.4f boundaryT=%.4f power=%.4f rotSpeed=%.4f meanErr=%.4f currentErr=%.4f\n', ...
                    re, this.e_all_take(1), this.P, this.agent_rot, error_dist, error_now);
            end

            function [angle_dist,angle_T] = angle_post(this)
                angle_dist = [];
                angle_T = [];
                angle = floor(this.rot_index_rot);
                for i = angle-15:angle+15
                    n = i;
                    if i <= 0
                        n = i + 360;
                    end
                    if i > 360
                        n = i - 360;
                    end
                    angle_dist = [angle_dist this.angle_dist_all(n)];
                    angle_T = [angle_T this.mask_52(this.angle_post_all(1,n),this.angle_post_all(2,n))];
                end
                angle_dist = normalize_distance(angle_dist,this.distance_min,this.distance_max);
                angle_T = normalize_temp_error(53 - angle_T,4);
           end
           function distance_norm = normalize_distance(distance, distance_min, distance_max)
                distance_norm = (distance - distance_min) / (distance_max - distance_min);
            end
            function temp_error_norm = normalize_temp_error(temp_error, max_range)
                temp_error_norm = temp_error / max_range;
                temp_error_norm(temp_error_norm > 1) = 1;
                temp_error_norm(temp_error_norm < -1) = -1;
            end
            function max_temp_norm = normalize_max_temp(max_temp, max_temp_min, max_temp_max)
                max_temp_norm = ((max_temp - max_temp_min) / (max_temp_max - max_temp_min)).^2;
            end
            function dist_error_norm = normalize_dist_error(temp_error, min_dist, max_dist)
                dist_error_norm = (temp_error - min_dist) / (max_dist - min_dist) * 2 - 1;
                dist_error_norm(dist_error_norm < -1) = -1;
                dist_error_norm(dist_error_norm > 1) = 1;
             end
        end
        
        function [ed,ed_now] = error_end(this)
            rot_index_ed = 0;
            rot_index_temp = min(this.rot_index_rot, 360);
            dist_di = zeros(1, ceil(rot_index_temp) + 1);

            for i = 0:ceil(rot_index_temp)
                rot_index_ed = rot_index_ed + 1;
                n = i;
                if i == 0
                    n = 360;
                end
                center_initial = this.center_initial_all{n};
                [x1,y1] = find((center_initial == 1) & (this.mask_52 >= 55));
                dist_to_max_toumor_boundary = this.angle_dist_all(n);

                if isempty(x1)
                    dist_di(rot_index_ed) = -dist_to_max_toumor_boundary;
                else
                    dist_max_to_boundary = norm([x1(1,1),y1(1,1)] - [this.Nx/2,this.Ny/2]) * this.dx;
                    for i1 = 1:numel(x1)
                        dist_find_ablation_max = norm([x1(i1,1),y1(i1,1)] - [this.Nx/2,this.Ny/2]) * this.dx;
                        if dist_find_ablation_max >= dist_max_to_boundary
                            dist_max_to_boundary = dist_find_ablation_max;
                        end
                    end
                    dist_di(rot_index_ed) = dist_max_to_boundary - dist_to_max_toumor_boundary;
                end
            end

            ed_now = dist_di(rot_index_ed);
            dist_di = dist_di * 1e3;
            ed = sum(abs(dist_di)) / rot_index_ed;
        end

        % Reset environment to initial state and output initial observation.
        function InitialObservation = reset(this)
            if isempty(this.repoRoot)
                this.repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            end
            this.set_T = 54;

            if isempty(this.trainingShapes)
                this.trainingShapes = loadTrainingShapes(this);
            end
            All_m_resized = this.trainingShapes;
            if isempty(this.num_All_m_resized)
                this.num_All_m_resized = 1;
            end

            this.tumor_boundary = All_m_resized{this.num_All_m_resized};
            this.tumor_boundary(this.tumor_boundary == 2) = 0;
            this.tumor_boundary(this.tumor_boundary == 1) = 2;
            this.tumor_boundary(this.tumor_boundary == 3) = 0;

            this.kgrid = kWaveGrid(this.Nx, this.dx, this.Ny, this.dy);
            this.karray = kWaveArray('BLITolerance', 0.05, 'UpsamplingRate', 10);
            this.line_diameter = 0.004;
            this.mask_diameter = 0.006;
            this.karray.addLineElement([ -this.h_dx,0],[ -this.h_dx,0.002]);

            mask = this.karray.getArrayBinaryMask(this.kgrid);
            [~,y] = find(mask == 1);
            this.tt_center_y = (y(1) + y(end)) / 2;
            this.tt_center_x = this.Nx/2 + 1 - (this.h_dx + this.tumor_dx) / this.dx;
            this.tt_center_y = this.Ny / 2; 
            this.tt_center = [this.tt_center_x, this.tt_center_y];
            this.tt = makeBoundaryMask( ...
                makeDisc(this.Nx, this.Ny, this.tt_center_x, this.tt_center_y, this.mask_diameter / this.dx / 2), ...
                this.Nx, this.Ny, 1);

            this.center_to_boundary = zeros(this.Nx,this.Ny);
            this.center_to_boundary(this.Nx/2 + 1:this.Nx,this.Ny / 2)  = 1;
            this.center_to_boundary(this.Nx/2,this.Ny/2) = 2;

            this.source.Q = 0;
            this.source.T0 = 37*ones(this.Nx,this.Ny);

            this.medium.density              = 1090;     % [kg/m^3]
            this.medium.thermal_conductivity = 0.5;      % [W/(m.K)]
            this.medium.specific_heat        = 3.0581e+03;     % [J/(kg.K)]
            convection_coefficient      = 500;
            this.medium.diffusion_coeff = 0.15e-6;        % [m^2/s]
            this.medium.perfusion_coeff = 0.05;
            this.medium.blood_density = 1050;
            this.medium.blood_specific_heat = 3700;
            this.medium.blood_perfusion_rate = 0.0024;
            this.medium.blood_ambient_temperature = 37;

            this.input_args = {'PlotSim',true, 'Sensor_Mask',this.tt , 'Convection_Coefficient', ...
                convection_coefficient, 'tt_center_x', this.tt_center_x};
            this.kdiff = kWaveDiffusion(this.kgrid, this.medium, this.source, [], this.input_args{:});

            this.rot = 360;
            this.dt = 0.1;
            this.time = 1;
            this.t_once = 1;
            this.kdiff.Q = 0;
            this.T_scale = zeros(2,30);
            this.rot_index_rot = 0;
            this.e_all_take = [];
            this.agent_rot = 0;
            this.rot_index = 1;
            this.mask_52 = zeros(this.Nx,this.Ny);

            [this.e_all_take,this.T_scale,this.mhz,this.mask_52] = this.kdiff.takeTimeStep(round(5000 / this.dt), this.dt, this.t_once, this.rot, 22, this.tumor_boundary ...
                ,this.center_to_boundary,this.tt_center,4,this.rot_index_rot,this.T_scale,1,this.mask_52,this.agent_rot,this.set_T);
            [this.angle_post_all,this.angle_dist_all,this.center_initial_all] = angle_all(this);
            [ed,~] = error_end(this);

            [normalize_angle_dist,normalize_angle_T] = angle_post(this);
            this.e = [normalize_angle_dist, normalize_angle_T,normalize_max_temp(this.e_all_take(2),...
                this.max_temp_min,this.max_temp_max),normalize_dist_error(ed,this.min_dist,this.max_dist)];

            InitialObservation = this.e;

            function All_m_resized = loadTrainingShapes(this)
                candidatePaths = {
                    fullfile(this.repoRoot, 'trainCode', '0624', '210.mat')
                    fullfile(this.repoRoot, 'data', 'prostate800_001mm_down_400_02_6479250.mat')
                };
                for pathIndex = 1:numel(candidatePaths)
                    shapePath = candidatePaths{pathIndex};
                    if ~isfile(shapePath)
                        continue
                    end
                    shapeData = load(shapePath);
                    if isfield(shapeData, 'All_M_resized')
                        All_m_resized = shapeData.All_M_resized;
                    elseif isfield(shapeData, 'M_resized')
                        All_m_resized = {shapeData.M_resized};
                    else
                        names = fieldnames(shapeData);
                        value = shapeData.(names{1});
                        if iscell(value)
                            All_m_resized = value;
                        else
                            All_m_resized = {value};
                        end
                    end
                    return
                end
                error('No training prostate shape file found. Expected trainCode/0624/210.mat or data/prostate800_001mm_down_400_02_6479250.mat.');
            end

            function [angle_post_all,angle_dist_all,center_initial_all] = angle_all(this)
                angle_post_all = [];
                angle_dist_all = [];
                center_initial_all = {};
                maxBoundaryPoint = [1; 1];

                for i = 1:ceil(360)
                    center_initial = imrotate(this.center_to_boundary, i, "nearest", "crop");
                    center_initial_all{i} = center_initial;
                    [x,y] = find((center_initial == 1) & (this.tumor_boundary == 2));
                    if isempty(x)
                        dist_to_max_toumor_boundary = 0;
                    else
                        dist_to_max_toumor_boundary = norm([x(1,1),y(1,1)] - [this.Nx/2,this.Ny/2]) * this.dx;
                        maxBoundaryPoint = [x(1,1); y(1,1)];
                        for i1 = 1:numel(x)
                            dist_find_boundary_max = norm([x(i1,1),y(i1,1)] - [this.Nx/2,this.Ny/2]) * this.dx;
                            if dist_find_boundary_max >= dist_to_max_toumor_boundary
                                dist_to_max_toumor_boundary = dist_find_boundary_max;
                                maxBoundaryPoint = [x(i1,1); y(i1,1)];
                            end
                        end
                    end
                    angle_dist_all = [angle_dist_all dist_to_max_toumor_boundary];
                    angle_post_all = [angle_post_all maxBoundaryPoint];
                end
            end

            function [angle_dist,angle_T] = angle_post(this)
                angle_dist = [];
                angle_T = [];
                angle = floor(this.rot_index_rot);
                for i = angle-15:angle+15
                    n = i;
                    if i <= 0
                        n = i + 360;
                    end
                    angle_dist = [angle_dist this.angle_dist_all(n)];
                    angle_T = [angle_T this.kdiff.T(this.angle_post_all(1,n),this.angle_post_all(2,n))];
                end
                angle_dist = normalize_distance(angle_dist,this.distance_min,this.distance_max);
                angle_T = normalize_temp_error(53 - angle_T,4);
            end

            function distance_norm = normalize_distance(distance, distance_min, distance_max)
                distance_norm = (distance - distance_min) / (distance_max - distance_min);
            end

            function temp_error_norm = normalize_temp_error(temp_error, max_range)
                temp_error_norm = temp_error / max_range;
                temp_error_norm(temp_error_norm > 1) = 1;
                temp_error_norm(temp_error_norm < -1) = -1;
            end

            function max_temp_norm = normalize_max_temp(max_temp, max_temp_min, max_temp_max)
                max_temp_norm = ((max_temp - max_temp_min) / (max_temp_max - max_temp_min)).^2;
            end

            function dist_error_norm = normalize_dist_error(temp_error, min_dist, max_dist)
                dist_error_norm = (temp_error - min_dist) / (max_dist - min_dist) * 2 - 1;
                dist_error_norm(dist_error_norm < -1) = -1;
                dist_error_norm(dist_error_norm > 1) = 1;
            end

            function boundary = makeBoundaryMask(mask, Nx, Ny, flag)
                boundary = mask;

                for ix = 2:Nx - 1
                    for iy = 2:Ny - 1
                        emptyNeighborCount = ~boundary(ix-1,iy) + ~boundary(ix+1,iy) ...
                            + ~boundary(ix,iy-1) + ~boundary(ix,iy+1);
                        if emptyNeighborCount == 3
                            boundary(ix,iy) = 0;
                        end
                    end
                end

                for ix = 2:Nx - 1
                    for iy = 2:Ny - 1
                        hasBoundaryNeighbor = boundary(ix-1,iy) == 1 ...
                            || boundary(ix+1,iy) == 1 ...
                            || boundary(ix,iy+1) == 1 ...
                            || boundary(ix,iy-1) == 1;
                        if hasBoundaryNeighbor && ~boundary(ix,iy)
                            boundary(ix,iy) = 2;
                        end
                    end
                end

                if flag ~= 1
                    return
                end

                for ix = 2:Nx - 1
                    for iy = 2:Ny - 1
                        if boundary(ix,iy) ~= 2
                            continue
                        end

                        emptyNeighborCount = ~boundary(ix-1,iy) + ~boundary(ix+1,iy) ...
                            + ~boundary(ix,iy-1) + ~boundary(ix,iy+1);
                        if emptyNeighborCount == 1
                            if ~boundary(ix-1,iy)
                                boundary(ix,iy) = 11;
                            elseif ~boundary(ix+1,iy)
                                boundary(ix,iy) = 12;
                            elseif ~boundary(ix,iy-1)
                                boundary(ix,iy) = 13;
                            elseif ~boundary(ix,iy+1)
                                boundary(ix,iy) = 14;
                            end
                        elseif emptyNeighborCount == 2
                            if ~boundary(ix,iy-1) && ~boundary(ix-1,iy)
                                boundary(ix,iy) = 21;
                            elseif ~boundary(ix,iy+1) && ~boundary(ix-1,iy)
                                boundary(ix,iy) = 23;
                            elseif ~boundary(ix,iy-1) && ~boundary(ix+1,iy)
                                boundary(ix,iy) = 22;
                            else
                                boundary(ix,iy) = 24;
                            end
                        end
                    end
                end
            end
        end
    end
end


