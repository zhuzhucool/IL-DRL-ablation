%KWAVEDIFFUSION Time-domain simulation of heat diffusion and perfusion.
%
% DESCRIPTION:
%     kWaveDiffusion is a class definition for the time-domain solution of
%     the diffusion equation or Pennes' bioheat equation in 1D, 2D, and 3D.
%     In addition to heat diffusion, Pennes' bioheat equation accounts for
%     advective heat loss due to tissue perfusion (the flow of blood
%     through tissue), and heat deposition (e.g., due to ultrasound
%     absorption) [1]. The computation is based on a k-space pseudospectral
%     scheme in which spatial gradients are calculated using the Fourier
%     collocation spectral method, and temporal gradients are calculated
%     using a k-space corrected finite difference scheme. For a homogeneous
%     medium, the formulation is exact and unconditionally stable. For a
%     heterogeneous medium, the time scheme allows larger time-steps to be
%     taken for the same level of accuracy compared to conventional
%     pseudospectral time-domain methods. 
%
%     The most general partial differential equation solved by the
%     kWaveDiffusion class is given by 
%
%         A * dT/dt = div(Kt * grad(T)) - B * (T - Ta) + Q
%
%         where
%
%         A  = density [kg/m^3] * specific heat capacity [J/(kg.K)]
%         Kt = thermal conductivity [W/(m.K)]
%         B  = blood density [kg/m^3] * blood specific heat [J/(kg.K)] 
%              * blood perfusion rate [1/s]    
%         Ta = arterial temperature (blood ambient temperature) [degC]
%         Q  = volume rate of heat deposition [W/m^3]
%
%     In a homogeneous medium, the thermal coefficients are related to the
%     diffusion coefficient (or thermal diffusivity) by 
%
%         diffusion coefficient [m^2/s] = Kt / A
%
%     Note, when the diffusion coefficient is specified instead of the
%     individual thermal coefficients, the equation that is solved is 
%
%         dT/dt = div(D * grad(T))
%
%     For non-constant coefficients, this differs from the conventional
%     heat equation (where the diffusion coefficient is taken outside the
%     divergence operator). For convenience, the thermal coefficients
%     related to perfusion can also be combined to give a single
%     "perfusion coefficient" given by
%
%         perfusion coefficient [1/s] = B / A
%
%     The input parameters are assigned as fields to four input structures
%     (kgrid, medium, source, and sensor) in the same way as the other
%     models in the k-Wave toolbox. These structures define the properties
%     of the computational grid, the distribution of medium properties,
%     source terms, and the locations of the sensor points used to record
%     the evolution of the temperature field over time. 
%   
%     The medium parameters can each be specified as a single scalar values
%     in SI units (for homogeneous coefficients), or as  matrices the same
%     size as the computational grid (for heterogeneous coefficients). 
%
%     The initial temperature distribution is specified by assigning a
%     single scalar value or a matrix (the same size as the computational
%     grid) to source.T0. A heat source can also be specified in the same
%     way by defining source.Q (the volume rate of heat deposition).
%
%     The time history of the temperature field can be recorded
%     automatically by specifying a series of sensor locations using
%     sensor.mask. This is defined as a binary matrix (i.e., a matrix of
%     1's and 0's with the same dimensions as the computational grid)
%     representing the grid points within the computational grid that will
%     record the temperature field at each time step. The current sensor
%     data can be queried at any point using the property kdiff.sensor_data
%     (where kdiff is the name of the kWaveDiffusion object). The
%     sensor_data is returned using MATLAB's standard column-wise linear
%     matrix index ordering, indexed as sensor_data(sensor_point_index,
%     time_index). If no time dependent output is required, the sensor
%     input can be replaced with an empty array [].  
%
%     After an object of the kWaveDiffusion class is created, the
%     simulation is run by calling the method kdiff.takeTimeStep(Nt, dt),
%     where kdiff is the object name, Nt is the number of time steps to
%     take, and dt is the size of the time step. During the simulation, a
%     visualisation of the temperature field is displayed. The current
%     temperature can be queried (or modified) at any point using the
%     property kdiff.T.
%       
%     [1] Pennes, H. H. (1948). Analysis of tissue and arterial blood
%     temperatures in the resting human forearm. Journal of Applied
%     Physiology, 1(2), 93-122.  
%       
% USAGE:
%     kdiff = kWaveDiffusion(kgrid, medium, source)
%     kdiff = kWaveDiffusion(kgrid, medium, source, sensor)
%     kdiff = kWaveDiffusion(kgrid, medium, source, sensor, ...)
%     kdiff = kWaveDiffusion(kgrid, medium, source, [], ...)
%
% INPUTS:
%     kgrid                       - grid object returned by kWaveGrid
%
%     medium.diffusion_coeff      - diffusion coefficient [m^2/s]
%             OR
%     medium.density              - tissue mass density [kg/m^3] 
%     medium.specific_heat        - tissue specific heat capacity [J/(kg.K)]
%     medium.thermal_conductivity - tissue thermal conductivity [W/(m.K)]
%
%     medium.perfusion_coeff      - perfusion coefficient [1/s]
%             OR
%     medium.blood_density        - blood mass density [kg/m^3] 
%     medium.blood_specific_heat  - blood specific heat capacity [J/(kg.K)]
%     medium.blood_perfusion_rate - blood perfusion rate [1/s]
%                                   (volumetric flow rate per unit volume)
%
%     medium.blood_ambient_temperature
%                                 - ambient blood temperature within
%                                   perfused tissue regions [degC]
%
%     medium.diffusion_coeff_ref  - reference diffusion coefficient used
%                                   within the k-space operator 
%                                   (default = 'max')
%     medium.perfusion_coeff_ref  - reference perfusion coefficient used
%                                   within the k-space operator 
%                                   (default = 'max')
%                             
%     source.T0                   - initial temperature distribution [degC]
%     source.Q                    - volume rate of heat deposition [W/m^3]
%                                   (note, medium.density and
%                                   medium.specific_heat must be defined)
%
%     sensor.mask                 - binary grid specifying where the
%                                   temperature is recorded at each time
%                                   step
%
% OPTIONAL INPUTS:
%     Optional 'string', value pairs that may be used to modify the
%     default computational settings.
%
%     'DisplayUpdates' - Boolean controlling whether details of the
%                        simulation are printed to the MATLAB command line
%                        (default = true).
%     'MovieArgs'      - Settings for VideoWriter. Parameters must be given
%                        as {'param', value, ...} pairs within a cell array
%                        (default = {}), where 'param' corresponds to a
%                        writable property of a VideoWriter object.
%     'MovieName'      - Name of movie produced when 'RecordMovie' is set
%                        to true (default = 'date-time-kWaveDiffusion').
%     'MovieProfile'   - Profile input passed to VideoWriter.
%     'PlotFreq'       - Number of iterations which must pass before the
%                        simulation plot is updated (default = 10). 
%     'PlotScale'      - [min, max] values used to control the plot
%                        scaling (default = 'auto').  
%     'PlotSim'        - Boolean controlling whether the simulation
%                        iterations are progressively plotted (default =
%                        true).
%     'RecordMovie'    - Boolean controlling whether the displayed image
%                        frames are captured and stored as a movie using
%                        VideoWriter (default = false).
%
% OUTPUTS:
%     kdiff            - kWaveDiffusion object which can be used to run
%                        thermal simulations using the diffusion equation
%                        or Pennes bioheat equation
% 
% DYNAMIC PROPERTIES:
%     Properties which can be queried or modified after the object is
%     created. 
%
%     .cem43           - thermal dose given in cumulative equivalent
%                        minutes (cem) relative to T = 43 degC [mins]
%     .T               - current temperature field [degC]
%     .Q               - volume rate of heat deposition [W/m^3]
%
% STATIC PROPERTIES:
%     Properties which can be queried, but not modified, after the object
%     is created.  
%
%     .dt_limit        - maximum time step for which the simulation
%                        remains stable [s]
%     .lesion_map      - binary matrix of cem43 >= 240 mins
%     .lesion_size     - total size of lesion_map (distance in 1D [m],
%                        area in 2D [m^2], volume in 3D [m^3])
%     .sensor_data     - time varying temperature recorded at the sensor
%                        positions given by sensor.mask [degC]
%
% METHODS:
%     .plotTemp        - plot current temperature field in current figure
%                       window
%     .setOptionalInputs('string', value, ...)
%                      - modify the optional inputs after the object is
%                        created
%     .takeTimeStep(Nt, dt, time, rot, T_color) 
%                        Nt 总步长
%                        dt 步长
%                        time 多久旋转一次
%                        rot 旋转角度
%                        T_color 冷却温度
%                      - calculate the given number of time steps of the
%                        temperature field
%
% ABOUT:
%     author           - Bradley Treeby and Teedah Saratoon
%     date             - 10th September 2014
%     last update      - 10th July 2019
%       
% This function is part of the k-Wave Toolbox (http://www.k-wave.org)
% Copyright (C) 2014-2019 Bradley Treeby and Teedah Saratoon
%
% See also bioheatExact

% This file is part of k-Wave. k-Wave is free software: you can
% redistribute it and/or modify it under the terms of the GNU Lesser
% General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
% 
% k-Wave is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
% more details. 
% 
% You should have received a copy of the GNU Lesser General Public License
% along with k-Wave. If not, see <http://www.gnu.org/licenses/>.

% Define as a handle class - A handle class constructor returns a handle
% object that is a reference to the object created. You can assign the
% handle object to multiple variables or pass it to functions without
% causing MATLAB to make a copy of the original object. A function that
% modifies a handle object passed as an input argument does not need to
% return the object.
classdef kWaveDiffusion < handle
    
    % define the private properties (these parameters are stored and cannot
    % be altered by the user after the object is created, but they can be
    % accessed) 
    properties (GetAccess = public, SetAccess = private)
              
        % number of spatial dimensions
        dim = 0;        
        
        % grid size in x-direction [grid points]
        Nx = 1;
        
        % grid size in y-direction [grid points]
        Ny = 1;
        
        % grid size in z-direction [grid points]
        Nz = 1;        
        
        % grid point spacing in x-direction [m]
      	dx = 0;
        
        % grid point spacing in y-direction [m]
        dy = 0;
        
        % grid point spacing in z-direction [m]
        dz = 0;    
        
        % grid coordinates in the x-direction [m] 
        %z_vec这个变量代表的是在z方向上的网格坐标，用于定义三维空间中每个点在z轴方向上的位置。
        %z_vec = [0, 1, 2, 3, 4]
        %这个向量表示，在z方向上，第一个网格点位于起点，第二个网格点位于距离起点1米的位置，
        %第三个网格点位于距离起点2米的位置，依此类推，直到第五个网格点位于距离起点4米的位置。
      	x_vec;
        
        % grid coordinates in the y-direction [m] 
        y_vec;
        
        % grid coordinates in the z-direction [m] 
        z_vec;         
                
        % total number of time steps taken
        time_steps_taken = 0;
                
        % boundary condition
        boundary_condition = 'periodic';      
        
        % reference diffusion coefficient used in k-space operator
        diffusion_coeff_ref = 0;
        
        % reference perfusion coefficient used in k-space operator
        perfusion_coeff_ref = 0;
        
        % sensor mask
        sensor_data;
        
        % maximum time step for a stable simulation
        dt_limit;        
        
    end
    
    % define the public properties (these parameters are stored and can be
    % both accessed and altered by the user after the object is created)
    properties (GetAccess = public, SetAccess = public)
        
        % temperature of the tissue [degC]
        T = 0;        
        
        % volume rate of heat deposition [W/m^3]
        Q = 0;
        
        % thermal damage integral [mins]
        cem43 = 0;  
                
    end    
    
    % define the dependent properties (these parameters are computed when
    % queried)
    properties(Dependent = true)
       
        % lesion map
        lesion_map;
        
        % lesion volume
        lesion_size;
        
        ablation_depth;
                
    end
    
    % define the hidden properties - these cannot be seen or accessed
    % directly by the user, and are used to store internal properties
    properties (Hidden = true, GetAccess = private, SetAccess = private)
        
        % material properties
        blood_specific_heat = 3700; % 血液比热容，单位：J/kg/°C
        density                     = 1020;  % [kg/m^3]
        thermal_conductivity = 0.5; %k  [W/(m.K)]
        convection_coefficient;  
        
        diffusion_p1                = 0;
        diffusion_p2                = 0;
        perfusion_coeff             = 0;
        blood_ambient_temperature   = 0;
        q_scale_factor              = 0;
        
        % wavenumber vectors
        k;
        kx_vec;
        ky_vec;
        kz_vec;
        
        % implied period of input function for DTT boundary conditions
        M;
                
        % flags
        flag_homogeneous = true;
        
        % sensor details
        num_sensor_points = 0;
        sensor_mask_index;
        
        % plotting parameters
        plot_axes_scale;
        plot_axes_prefix;
        
        % optional input parameters
        movie_args      = {};
        movie_name      = [getDateString '-kWaveDiffusion'];
        movie_profile   = 'Uncompressed AVI';
        plot_freq       = 10;
        plot_scale      = 'auto';
        plot_sim        = true;
        record_movie    = false;
        use_kspace      = true;
        color_map       = jet(256);
        display_updates = true;
        Sensor_Mask;  %设置换能器掩码
        Convection_Coefficient;  %热对流
        tt_center_x;
        
        % literals used in the code
        num_time_steps_before_simulation_time_estimate = 10;
        highest_prime_factor_warning = 7;
        
    end
    
    % constructor function
    methods
        function kdiff = kWaveDiffusion(kgrid, medium, source, sensor, varargin)
            
            % -------------------------------------------------------------
            
            % assign the grid size and spacing from kgrid
            kdiff.dim = kgrid.dim;
            switch kgrid.dim
                case 1
                    kdiff.Nx    = kgrid.Nx;
                    kdiff.dx    = kgrid.dx;
                    kdiff.x_vec = kgrid.x_vec;
                case 2
                    kdiff.Nx    = kgrid.Nx;
                    kdiff.Ny    = kgrid.Ny;
                    kdiff.dx    = kgrid.dx;
                    kdiff.dy    = kgrid.dy;
                    kdiff.x_vec = kgrid.x_vec;
                    kdiff.y_vec = kgrid.y_vec;
                case 3
                    kdiff.Nx    = kgrid.Nx;
                    kdiff.Ny    = kgrid.Ny;
                    kdiff.Nz    = kgrid.Nz;
                    kdiff.dx    = kgrid.dx;
                    kdiff.dy    = kgrid.dy;
                    kdiff.dz    = kgrid.dz;
                    kdiff.x_vec = kgrid.x_vec;
                    kdiff.y_vec = kgrid.y_vec;
                    kdiff.z_vec = kgrid.z_vec;
            end
                        
            % pre-compute suitable axes scaling factor
            [~, kdiff.plot_axes_scale, kdiff.plot_axes_prefix] = scaleSI(max([kdiff.dx .* kdiff.Nx, kdiff.dy .* kdiff.Ny, kdiff.dz .* kdiff.Nz]));
            
            % -------------------------------------------------------------
            
            % replace defaults with user defined values if provided
            if nargin > 4 
                kdiff.setOptionalInputs(varargin);
            end
            
            % -------------------------------------------------------------
            
            % assign tissue parameters to computational variables
            if isfield(medium, 'diffusion_coeff')
                
                % assign diffusion terms from user inputs
                kdiff.diffusion_p1 = 1;
                kdiff.diffusion_p2 = medium.diffusion_coeff;
                
            else
                
                % if medium.diffusion_coeff is not specified, require all
                % tissue properties to be specified
                enforceFields(medium, {'density', 'thermal_conductivity', 'specific_heat'});
                kdiff.thermal_conductivity = medium.thermal_conductivity;
                kdiff.density = medium.density;
                % assign diffusion terms from user inputs
                kdiff.diffusion_p1 = 1 ./ (medium.density .* medium.specific_heat);
                kdiff.diffusion_p2 = medium.thermal_conductivity;
                
            end
            %产生区别的地方
            % check if perfusion parameters have been specified
            if isfield(medium,'blood_density') || isfield(medium,'blood_specific_heat') || isfield(medium,'blood_perfusion_rate') 
                
                % require all perfusion parameters to be specified
                enforceFields(medium, {'blood_density', 'blood_specific_heat', 'blood_perfusion_rate', 'blood_ambient_temperature', 'density', 'specific_heat'});
                kdiff.blood_specific_heat = medium.blood_specific_heat;
                % assign perfusion parameters
                kdiff.perfusion_coeff = medium.blood_density .* medium.blood_perfusion_rate .* medium.blood_specific_heat ./ (medium.density .* medium.specific_heat);
                kdiff.blood_ambient_temperature = medium.blood_ambient_temperature;
                
            elseif isfield(medium, 'perfusion_coeff')
                                
                % require all perfusion parameters to be specified
                enforceFields(medium, {'perfusion_coeff', 'blood_ambient_temperature'});
                
                % assign perfusion parameters
                kdiff.perfusion_coeff = medium.perfusion_coeff;
                kdiff.blood_ambient_temperature = medium.blood_ambient_temperature;

            elseif isfield(medium, 'blood_ambient_temperature')
                
                % require perfusion parameters to be specified in some form
                error('Perfusion parameters must be specified when medium.blood_ambient_temperature is defined.');
                
            end
            
            % check if a source term (volume rate of heat deposition) is
            % defined 
            if isfield(source, 'Q')
                
                % require density and specific heat to be specified
                % (required for scaling the source term)
                if ~isfield(medium, 'density') || ~isfield(medium, 'specific_heat')
                    error('medium.density and medium.specific_heat must be specified when source.Q is defined.');
                end
                
                % assign scale factor if medium properties are specified
                % using medium.diffusion_coeff (otherwise diffusion_p1 is
                % used for the scaling to save memory)
                if (numel(kdiff.diffusion_p1) == 1) && (kdiff.diffusion_p1 == 1)
                    kdiff.q_scale_factor = 1 ./ (medium.density .* medium.specific_heat);
                end 
                
                % assign source term
                kdiff.Q = source.Q;
                
            end
            
            % check if the simulation is heterogeneous
            if (numel(kdiff.diffusion_p1) ~= 1) || ...
                    (numel(kdiff.diffusion_p2) ~= 1) || ...
                    (numel(kdiff.perfusion_coeff) ~= 1) || ...
                    (numel(kdiff.blood_ambient_temperature) ~= 1)
                kdiff.flag_homogeneous = false;
            end
                
            % check if a user defined reference diffusion coefficient is
            % defined, if not, use the maximum
            if ~isfield(medium,'diffusion_coeff_ref')
                medium.diffusion_coeff_ref = 'max';
            end
            
            % set the reference diffusion coefficient
            if isnumeric(medium.diffusion_coeff_ref)

                % use value directly
                kdiff.diffusion_coeff_ref = medium.diffusion_coeff_ref;

            elseif strcmp(medium.diffusion_coeff_ref, 'min')

                % set to minium value
                kdiff.diffusion_coeff_ref = min( kdiff.diffusion_p1(:) .* kdiff.diffusion_p2(:) );

            elseif strcmp(medium.diffusion_coeff_ref, 'mean')

                % set to mean value
                kdiff.diffusion_coeff_ref = mean( kdiff.diffusion_p1(:) .* kdiff.diffusion_p2(:) );

            elseif strcmp(medium.diffusion_coeff_ref, 'max')

                % set the maximum value
                kdiff.diffusion_coeff_ref = max( kdiff.diffusion_p1(:) .* kdiff.diffusion_p2(:) );

            end
            
            if kdiff.perfusion_coeff ~= 0
            
                % check if a user defined reference perfusion coefficient is
                % defined, if not, use the maximum
                if ~isfield(medium,'perfusion_coeff_ref')
                    medium.perfusion_coeff_ref = 'max';
                end
            
                % set the reference perfusion coefficient
                if isnumeric(medium.perfusion_coeff_ref)
                    
                    % use value directly
                    kdiff.perfusion_coeff_ref = medium.perfusion_coeff_ref;
                    
                elseif strcmp(medium.perfusion_coeff_ref, 'min')
                    
                    % set to minimum value
                    kdiff.perfusion_coeff_ref = min(kdiff.perfusion_coeff(:));
                        
                elseif strcmp(medium.perfusion_coeff_ref, 'mean')
                    
                    % set to mean value
                    kdiff.perfusion_coeff_ref = mean(kdiff.perfusion_coeff(:));
                    
                elseif strcmp(medium.perfusion_coeff_ref, 'max')
                    
                    % set to maximum value
                    kdiff.perfusion_coeff_ref = max(kdiff.perfusion_coeff(:));        
                    
                end
                
            end
            
            % -------------------------------------------------------------
            
            % assign the boundary conditions if specified
            if isfield(medium,'boundary_condition')    %周期条件，绝缘条件，导电条件
                
                % check the boundary condition is allowed and assign
                if strcmp(medium.boundary_condition, 'periodic') || ...
                   strcmp(medium.boundary_condition, 'insulating') || ... 
                   strcmp(medium.boundary_condition, 'conducting')
               
                    kdiff.boundary_condition = medium.boundary_condition;
                else
                    error('Unknown boundary condition');
                end

                % don't allow non-periodic boundary conditions for
                % heterogeneous media
                if ~kdiff.flag_homogeneous && ~strcmp(medium.boundary_condition, 'periodic')
                    error('Insulating and conducting boundary conditions are currently only supported for homogeneous media');
                end
                
            end
           
            % define appropriate wavenumbers based on the specified
            % boundary condition
            switch kdiff.boundary_condition
                case 'periodic'
                    
                    % assign Fourier wavenumbers in shifted order
                    kdiff.k      = ifftshift(kgrid.k);
                    kdiff.kx_vec = ifftshift(kgrid.kx_vec);
                    kdiff.ky_vec = ifftshift(kgrid.ky_vec);
                    kdiff.kz_vec = ifftshift(kgrid.kz_vec);
                    
                case 'insulating'
                    
                    % perfectly insulating boundary condition corresponds
                    % to WSWS symmetry or DCT-I (derivative is zero at the
                    % boundary)
                    kdiff.kx_vec = kgrid.kx_vec_dtt(1);
                    kdiff.ky_vec = kgrid.ky_vec_dtt(1);
                    kdiff.kz_vec = kgrid.kz_vec_dtt(1);
                    [kdiff.k, kdiff.M] = kgrid.k_dtt(1);
                    
                case 'conducting'
                            
                    % perfectly conducting boundary condition corresponds
                    % to WAWA symmetry or DST-I (function is zero at the
                    % boundary) 
                    
                    % implied period of function with WAWA symmetry
                    kdiff.kx_vec = kgrid.kx_vec_dtt(5);
                    kdiff.ky_vec = kgrid.ky_vec_dtt(5);
                    kdiff.kz_vec = kgrid.kz_vec_dtt(5);
                    [kdiff.k, kdiff.M] = kgrid.k_dtt(5);
                    
            end            
  
            % -------------------------------------------------------------
            
            % get maximum prime factors
            switch kdiff.boundary_condition
                case 'periodic'
                    
                    % periodic
                    prime_facs = kgrid.highest_prime_factors;
                    
                case 'insulating'
                    
                    % WSWS symmetry - implied period of the symmetric
                    % periodic sequence is 2*N - 2, where N is the length
                    % of the representative sample
                    prime_facs = [max(factor(2 * kdiff.Nx - 2)), max(factor(2 * kdiff.Ny - 2)), max(factor(2 * kdiff.Nz - 2))];
                    
                case 'conducting'
                    
                    % WAWA symmetry - implied period of the symmetric
                    % periodic sequence is 2*N + 2, where N is the length
                    % of the representative sample
                    prime_facs = [max(factor(2 * kdiff.Nx + 2)), max(factor(2 * kdiff.Ny + 2)), max(factor(2 * kdiff.Nz + 2))];
                    
            end
            
            % select appropriate ones for grid dimension
            prime_facs = prime_facs(1:kdiff.dim);
               
            % give warning for bad dimension sizes
            if max(prime_facs) > kdiff.highest_prime_factor_warning
                prime_facs(prime_facs == 0) = [];
                disp(['WARNING: Highest prime factors in each dimension are ' num2str(prime_facs)]);
                disp('         Use dimension sizes with lower prime factors to improve speed');
            end
            clear prime_facs;
            
            % -------------------------------------------------------------
            
            % assign initial temperature distribution
            enforceFields(source, {'T0'});
            if numel(source.T0) == 1
                switch kdiff.dim
                    case 1
                        kdiff.T = source.T0 .* ones(kdiff.Nx, 1);
                    case 2
                        kdiff.T = source.T0 .* ones(kdiff.Nx, kdiff.Ny);
                    case 3
                        kdiff.T = source.T0 .* ones(kdiff.Nx, kdiff.Ny, kdiff.Nz);
                end
            else
                kdiff.T = source.T0;
            end
            
            % -------------------------------------------------------------
            
            if (nargin >= 4) && ~isempty(sensor) && isfield(sensor, 'mask')
                
                % check the sensor mask is binary
                if sum(sensor.mask(:)) ~= numel(sensor.mask) - sum(sensor.mask(:) == 0)
                    error('sensor.mask must be a binary grid (numeric values must be 0 or 1).');
                end
                
                % pre-calculate the data type needed to store the matrix
                % indices given the total number of grid points: indexing
                % variables will be created using this data type to save
                % memory 
                if kgrid.total_grid_points < intmax('uint8')
                    index_data_type = 'uint8';
                elseif kgrid.total_grid_points < intmax('uint16')
                    index_data_type = 'uint16';
                elseif kgrid.total_grid_points < intmax('uint32')
                    index_data_type = 'uint32';                
                else
                    index_data_type = 'double';
                end   
                
                % create mask indices (this works for both normal sensor
                % and transducer inputs)
                kdiff.sensor_mask_index = find(sensor.mask ~= 0);

                % set the number of sensor points
                kdiff.num_sensor_points = numel(kdiff.sensor_mask_index);
                
                % convert the data type depending on the number of indices
                eval(['kdiff.sensor_mask_index = ' index_data_type '(kdiff.sensor_mask_index);']); 
                
            end
                        
        end 
    end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % general class methods
    methods
        
        % take Nt time steps of size dt
        function [e_drl,T_scale,mhz,mask_52] = takeTimeStep(obj, Nt, dt, t_once, end_rot, T_color, tumor_boundary,center_to_boundary,tt_center,W, rot_index,e_T,heatStatus,mask_52,agent_rot, Q_data_all)
           
            % define k-space correction term
            if obj.use_kspace
                
                % define k-space term 用于模拟波在介质中传播受到的扩散和灌注影响
                kappa = dt .* ( obj.diffusion_coeff_ref .* obj.k.^2 + obj.perfusion_coeff_ref );
                %用指数函数 exp(-kappa) 来计算 kappa 的修正项。指数函数部分模拟了随时间发生的衰减效应
                kappa = (1 - exp(-kappa) ) ./ kappa;
                
                % remove infinite values
                if obj.perfusion_coeff_ref == 0
                    kappa(obj.k == 0) = 1; %防止后面当除数时出现无限项
                end
                
            else
                
                % set correction term to 1 (equivalent to PSTD scheme)
                kappa = 1;
                
            end
            
            % define Cartesian spatial different operators
 
            [deriv_x, deriv_y, deriv_z] = obj.getDerivMatrix(kappa);

            if all(obj.perfusion_coeff == 0)
                use_perfusion = false;
                p_term = 0;
            else
                use_perfusion = true;
            end
            
            % pre-allocate sensor_data matrix if sensor.mask is defined
            if obj.num_sensor_points > 0
                obj.sensor_data = [obj.sensor_data, zeros(obj.num_sensor_points, Nt)];
            end
            
            
            % initialise movie parameters
            if obj.record_movie
                
                % force getframe compatability with dual monitors
                movegui(img);

                % create new VideoWriter object (this is supported from
                % MATLAB 2010b)
                video_obj = VideoWriter(obj.movie_name, obj.movie_profile);

                % adjust settings if specified by the user
                if ~isempty(obj.movie_args)
                    for input_index = 1:2:length(obj.movie_args)
                        eval(['video_obj.' obj.movie_args{input_index} ' = obj.movie_args{input_index + 1};']);
                    end
                end
                
                % open the object
                open(video_obj)

            end
            Q_all{1} = Q_data_all{1} / 2;
            Q_all{2} = Q_data_all{2} / 2;
            Q_all{3} = Q_data_all{3} / 2;
            Q_all{4} = Q_data_all{4} / 2;
            %循环前准备
            e_T  = circshift(e_T,[0,1]);
            center_initial =  imrotate(center_to_boundary, rot_index ,"nearest","crop");
            [x,y] = find((center_initial == 1)&(tumor_boundary == 2));
            if isempty(x)
                 e_T(1,1) = e_T(1,2);
                 e_T(2,1) = e_T(2,2);
            else
                dist_to_max_toumor_boundary  = norm([x(1,1),y(1,1)] - [obj.Nx/2,obj.Ny/2]) * obj.dx; %肿瘤边界到中点的距离
                for i1 = 1:numel(x)
                    dist_find_boundary_max = norm([x(i1,1),y(i1,1)] - [obj.Nx/2,obj.Ny/2]) * obj.dx;
                    if(dist_find_boundary_max >= dist_to_max_toumor_boundary)
                        dist_to_max_toumor_boundary = dist_find_boundary_max;
                            e_T(1,1) = x(i1);
                            e_T(2,1) = y(i1);
                    end
                end   
            end
            
            dist = norm( tt_center - [e_T(1,1),e_T(2,1)]) * obj.dx;
            e_drl(1,6) = dist;
            time_dt = t_once / dt; %设置一次旋转的步长
             if heatStatus == 1
                if dist <= 0.016
                    rotated_Q =  imrotate(Q_all{4} * sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离小于16mm,使用10mhz\n',dist*1000);
                    mhz = 10;
                 elseif dist <= 0.021
                    rotated_Q =  imrotate(Q_all{3}* sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离小于21mm,使用6mhz\n',dist*1000);
                    mhz = 6;
                 elseif dist <= 0.029
                    rotated_Q =  imrotate(Q_all{2}* sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离小于29mm,使用3mhz\n',dist*1000);
                    mhz = 3;
                 else
                    rotated_Q =  imrotate(Q_all{1}* sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离较远使用2mhz\n',dist*1000);
                    mhz = 2;
                end
                % fprintf('预加热 频率2mhz\n');
            else
                 if dist <= 0.016
                    rotated_Q =  imrotate(Q_all{4} * sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离小于16mm,使用10mhz\n',dist*1000);
                    mhz = 10;
                 elseif dist <= 0.021
                    rotated_Q =  imrotate(Q_all{3}* sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离小于21mm,使用6mhz\n',dist*1000);
                    mhz = 6;
                 elseif dist <= 0.029
                    rotated_Q =  imrotate(Q_all{2}* sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离小于26mm,使用3mhz\n',dist*1000);
                    mhz = 3;
                 else
                    rotated_Q =  imrotate(Q_all{1}* sqrt(W), rot_index ,"nearest","crop");
                    fprintf('dist = %.2fmm 换能器离肿瘤边界距离较远使用2mhz\n',dist*1000);
                    mhz = 2;
                 end  
             end
            %  if heatStatus == 1
            %     rotated_Q =  imrotate(Q_all{5}* sqrt(W), rot_index ,"nearest","crop");
            % else
            %     rotated_Q =  imrotate(Q_all{6} * sqrt(W), rot_index ,"nearest","crop");
            %  end
            %  if dist >= 0.018
            %     rotated_Q =  imrotate(Q_all{5} * sqrt(W), rot_index ,"nearest","crop");
            %     fprintf('dist = %.2fmm 换能器离肿瘤边界距离大于18mm,使用4.5mhz\n',dist*1000);
            %     mhz = 4.5;
            %  else
            %     rotated_Q =  imrotate(Q_all{6}* sqrt(W), rot_index ,"nearest","crop");
            %     fprintf('dist = %.2fmm 换能器离肿瘤边界距离小于18mm远，使用14.5mhz\n',dist*1000);
            %     mhz = 14.5;
            %  end  
             fprintf('功率为%.2fW\n',W);
             if W == 0
                  q_term = 0;   
             elseif all(rotated_Q == 0)
                  q_term = 0;
             else
                     %当输入多个参数时  q_term : Q热沉积 外部热源项
                 if (numel(obj.q_scale_factor) == 1) && (obj.q_scale_factor == 0)
                       q_term = obj.diffusion_p1 .* obj.IT( kappa .* obj.FT( rotated_Q ) ); 
                 else  %当只输入diffusion_coeff
                       q_term = obj.q_scale_factor .* obj.IT( kappa .* obj.FT( rotated_Q ) );
                 end
             end
%             Q_initial = obj.Q; %初始声压矩阵

            thermal_diffusivity = obj.thermal_conductivity /(obj.density * obj.blood_specific_heat);
            alpha_coeff = 0.6;  % [dB/(MHz^y cm)] 5.3
            %设置相应索引 上 w 下 s 左 a 右 d
            boundary.w1 = obj.Sensor_Mask == 11;
            boundary.s1 = obj.Sensor_Mask == 12;
            boundary.a1 = obj.Sensor_Mask == 13;
            boundary.d1 = obj.Sensor_Mask == 14;
            %左上w 右上 a 左下s  右下 d
            boundary.w2 = obj.Sensor_Mask == 21;
            boundary.s2 = obj.Sensor_Mask == 22;
            boundary.a2 = obj.Sensor_Mask == 23;
            boundary.d2 = obj.Sensor_Mask == 24;
            % 创建一个逻辑索引，直接从Sensor_Mask中找出所有等于1的位置
            mask = obj.Sensor_Mask == 1;
                        
            % if  max(max(obj.T(tumor_boundary == 2))) > 52 && max(max(obj.T(tumor_boundary == 2))) > obj.T(e_T(1,1), e_T(2,1))
            % if  obj.T(e_T(1,1), e_T(2,1)) >= 55
            %      flag_stop = 1;
            %      q_term = 0;
            % else
            %      flag_stop = 0;
            % end
            q_term_90 = q_term;
            flag_stop = 0;
            flag_stop_30 = 30;
            flag_30 = 0;
            for t_index = 1:Nt 
                
                if use_perfusion  %当输入灌注系数才会被使用 -B * (T - Ta) 血液灌注项
                    p_term = -obj.perfusion_coeff .* obj.IT( kappa .* obj.FT(obj.T - obj.blood_ambient_temperature) );
                    %kdiff.perfusion_coeff = medium.blood_density .* medium.blood_perfusion_rate .* medium.blood_specific_heat ./ (medium.density .* medium.specific_heat);
                    Dynamics_perfusion_coeff = obj.cem43 >  300;
                    p_term(Dynamics_perfusion_coeff) = 0;
                end
                
                % compute diffusion update term
                if obj.flag_homogeneous
                    
                    % if the medium is homogeneous, the thermal
                    % conductivity can be factorised, which allows the
                    % material coefficients to be combined into a single
                    % diffusion coefficient given by diffusion_p1 .*
                    % diffusion_p2, and the divergence and gradient terms
                    % to be combined into the Laplacian 热扩散项
                    d_term = obj.diffusion_p1 .* obj.diffusion_p2 .* obj.IT( -obj.k.^2 .* kappa .* obj.FT(obj.T) );
                    
                else
                    

                    
                end
                if max(max(obj.T)) >= 90
                    q_term = 0;
                else
                    q_term = q_term_90;
                end
                if flag_30 == 1 
                    flag_stop_30 = flag_stop_30 - 1;
                    q_term = 0;
                end

                if flag_stop_30 == 0 
                   break;
                end
                obj.T = obj.T + dt .* ( d_term + p_term + q_term );
                % 使用逻辑索引直接向量化赋值
                obj.T(mask) = T_color;

                % T_old = obj.T;
                % wsad_w = circshift(obj.T, [1, 0]);  % 下移一位，获取上方元素
                % wsad_s = circshift(obj.T, [-1, 0]); % 上移一位，获取下方元素
                % wsad_a = circshift(obj.T, [0, 1]);  % 右移一位，获取左方元素
                % wsad_d = circshift(obj.T, [0, -1]); % 左移一位，获取右方元素
                % % 预先计算常数以减少循环内的开销
                % %计算边界
                % inverseDenominator11 = obj.dx^2 / (2 * thermal_diffusivity * dt);
                % halfDxSq = (obj.dx^2 / 2);
                % inverseDenominator22 = obj.dx / (2 * thermal_diffusivity * dt);
                % heatConvection11 = obj.Convection_Coefficient / obj.thermal_conductivity * obj.dx * (T_color - T_old);
                % heatDiffusionw1 = 0.5 .* wsad_a + 0.5 .* wsad_d + 0 .* wsad_s + 1 .* wsad_w - 2 .* T_old;
                % heatDiffusions1 = 0.5 .* wsad_a + 0.5 .* wsad_d + 1 .* wsad_s + 0 .* wsad_w - 2 .* T_old;
                % heatDiffusiona1 = 1 .* wsad_a + 0 .* wsad_d + 0.5 .* wsad_s + 0.5 .* wsad_w - 2 .* T_old;
                % heatDiffusiond1 = 0 .* wsad_a + 1 .* wsad_d + 0.5 .* wsad_s + 0.5 .* wsad_w - 2 .* T_old;
                % heatSource11 = rotated_Q / obj.thermal_conductivity * halfDxSq;
                % obj.T(boundary.w1) = (heatConvection11(boundary.w1) + heatDiffusionw1(boundary.w1) + heatSource11(boundary.w1)) / inverseDenominator11 + T_old(boundary.w1);
                % obj.T(boundary.s1) = (heatConvection11(boundary.s1) + heatDiffusions1(boundary.s1) + heatSource11(boundary.s1)) / inverseDenominator11 + T_old(boundary.s1);
                % obj.T(boundary.a1) = (heatConvection11(boundary.a1) + heatDiffusiona1(boundary.a1) + heatSource11(boundary.a1)) / inverseDenominator11 + T_old(boundary.a1);
                % obj.T(boundary.d1) = (heatConvection11(boundary.d1) + heatDiffusiond1(boundary.d1) + heatSource11(boundary.d1)) / inverseDenominator11 + T_old(boundary.d1);
                % 
                %  % 计算周围非传感器位置的 T_old 值
                % maskDiffusionw2 = (1 .* wsad_a) + (0 .* wsad_d) + (0 .* wsad_s) + (1 .* wsad_w) - 2 * T_old;
                % maskDiffusions2 = (1 .* wsad_a) + (0 .* wsad_d) + (1 .* wsad_s) + (0 .* wsad_w) - 2 * T_old;
                % maskDiffusiona2 = (0 .* wsad_a) + (1 .* wsad_d) + (0 .* wsad_s) + (1 .* wsad_w) - 2 * T_old;
                % maskDiffusiond2 = (1 .* wsad_a) + (1 .* wsad_d) + (0 .* wsad_s) + (0 .* wsad_w) - 2 * T_old;
                % enhancedConvection22 = 2 * obj.Convection_Coefficient / obj.thermal_conductivity * (T_color - T_old);
                % heatSource22 = rotated_Q / obj.thermal_conductivity * (obj.dx / 2);
                % 
                % % 更新 T 矩阵
                % obj.T(boundary.w2) = (enhancedConvection22(boundary.w2) + maskDiffusionw2(boundary.w2) + heatSource22(boundary.w2)) / inverseDenominator22 + T_old(boundary.w2);
                % obj.T(boundary.s2) = (enhancedConvection22(boundary.s2) + maskDiffusions2(boundary.s2) + heatSource22(boundary.s2)) / inverseDenominator22 + T_old(boundary.s2);
                % obj.T(boundary.a2) = (enhancedConvection22(boundary.a2) + maskDiffusiona2(boundary.a2) + heatSource22(boundary.a2)) / inverseDenominator22 + T_old(boundary.a2);
                % obj.T(boundary.d2) = (enhancedConvection22(boundary.d2) + maskDiffusiond2(boundary.d2) + heatSource22(boundary.d2)) / inverseDenominator22 + T_old(boundary.d2);

                % update the damage integral
                obj.cem43 = obj.cem43 + dt ./ 60 .* ( 0.5 .* (obj.T >= 43) + 0.25 .* (obj.T >= 37 & obj.T < 43 ) ).^(43 - obj.T);
                
                % save the sensor data
                if obj.num_sensor_points > 0
                    obj.sensor_data(:, obj.time_steps_taken + t_index) = obj.T(obj.sensor_mask_index);
                end
                
                % plot temperature if required
                % if (obj.plot_sim || obj.record_movie) && ( rem(t_index, obj.plot_freq) == 0 || t_index == Nt )  
                % 
                %     % update progress bar
                %     waitbar(t_index ./ Nt, pbar);
                %     drawnow;
                % 
                %     % plot
                %     obj.plotTemp;
                % 
                %     % save movie frame if required
                %     if obj.record_movie
                % 
                %         % set background color to white
                %         set(gcf, 'Color', [1 1 1]);
                % 
                %         % save the movie frame
                %         writeVideo(video_obj, getframe(gcf));
                % 
                %     end
                % 
                % end
                
                % estimate the time to run the simulation
                % if (obj.display_updates) && (t_index == obj.num_time_steps_before_simulation_time_estimate)
                % 
                %     % display estimated simulation time
                %     disp(['  estimated simulation time ' scaleTime(etime(clock, loop_start_time) .* Nt ./ t_index) '...']);
                % 
                % end   
                
                if rem(t_index,time_dt) == 0
                    
                     e = 55 -  obj.T(e_T(1,1),e_T(2,1));
                     % 打开文件以追加方式写入
                    % fid = fopen('output.txt', 'a');
                    if flag_stop == 0
                        rot = agent_rot;
                        fprintf('e > 0，旋转速度为%d度每分钟,最高温度%.2f，边界最高温度%.2f,换能器当前方向换能器温度%.2f\n',rot * 60,max(max(obj.T)), max(max(obj.T(tumor_boundary == 2))),obj.T(e_T(1,1),e_T(2,1)));
                            % fprintf(fid, 'e > 0，旋转速度为%d度每分钟,最高温度%.2f，边界最高温度%.2f,换能器当前方向换能器温度%.2f\n', rot * 60, max(max(obj.T)), max(max(obj.T(tumor_boundary == 2))), obj.T(e_T(1,1), e_T(2,1)));
                         
                    else
                        fprintf('边界温度高,最高温度%.2f，边界最高温度%.2f,换能器当前方向换能器温度%.2f\n',max(max(obj.T)), max(max(obj.T(tumor_boundary == 2))),obj.T(e_T(1,1),e_T(2,1)));
                        % fprintf(fid, '边界温度高,最高温度%.2f，边界最高温度%.2f,换能器当前方向换能器温度%.2f\n',  max(max(obj.T)), max(max(obj.T(tumor_boundary == 2))), obj.T(e_T(1,1), e_T(2,1)));
                    end

                    % 关闭文件
                    % fclose(fid);
                    if heatStatus == 0
                         if flag_stop == 0
                             rot_index = rot_index + rot;
                             fprintf("rot:%.2f\n",rot_index);
                         else
                             rot_index = rot_index + 40 / 60;
                             fprintf("rot:%.2f\n",rot_index);
                         end
                    elseif heatStatus == 2
                        rot_index = rot_index + 40 / 60;
                        fprintf("rot:%.2f\n",rot_index);
                        center_initial =  imrotate(center_to_boundary, rot_index ,"nearest","crop");
                        [x,y] = find((center_initial == 1)&(tumor_boundary == 2));
                        e_T  = circshift(e_T,[0,1]);
                        if isempty(x)
                             e_T(1,1) = e_T(1,2);
                             e_T(2,1) = e_T(2,2);
                        else
                             e_T(1,1) = x(1,1);
                             e_T(2,1) = y(1,1);     
                        end
                        dist = norm( tt_center - [e_T(1,1),e_T(2,1)]) * obj.dx;
                        time_dt = t_once / dt; %设置一次旋转的步长
                         if dist <= 0.008
                            rotated_Q =  imrotate(Q_all{3} * sqrt(W), rot_index ,"nearest","crop");
                            fprintf('换能器离肿瘤边界距离小于8mm,使用10mhz\n');
                            mhz = 10;
                         elseif dist <= 0.012
                            rotated_Q =  imrotate(Q_all{4}* sqrt(W), rot_index ,"nearest","crop");
                            fprintf('换能器离肿瘤边界距离小于12mm,使用6mhz\n');
                            mhz = 10;
                         elseif dist <= 0.018
                            rotated_Q =  imrotate(Q_all{2}* sqrt(W), rot_index ,"nearest","crop");
                            fprintf('换能器离肿瘤边界距离小于18mm,使用3mhz\n');
                            mhz = 10;
                         else
                            rotated_Q =  imrotate(Q_all{1}* sqrt(W), rot_index ,"nearest","crop");
                            fprintf('换能器离肿瘤边界距离较远使用2mhz\n');
                            mhz = 10;
                         end
                    else
                        rot_index = 0;
                    end
              
                    % 先确定条件符合的索引
                    indices = obj.T > mask_52;
                    
                    % 然后更新符合条件的 mask_52 元素
                    mask_52(indices) = obj.T(indices);
                    
                    e_drl(1,1) = obj.T(e_T(1,1),e_T(2,1));
                    e_T(3,1) = e_drl(1,1);
                    e_drl(1,2) = max(max(obj.T));
                    e_drl(1,3) = rot_index;
                    e_drl(1,4) = max(max(obj.T(tumor_boundary == 2)));
                    e_drl(1,5) = rot;
                    e_drl(1,6) = dist; 
                    T_scale = e_T;
                    if heatStatus == 0
                        if rot_index > end_rot
                             e_drl(1,4) = 1;
                             break;
                        end
                    end
                    
                end
                if (heatStatus == 1 || heatStatus == 2) && obj.T(e_T(1,1),e_T(2,1)) >= 51
                    q_term = 0;
                    break;
                    % flag_30 = 1;
                end
          

            end

            % % update command line status
            % if obj.display_updates
            %     disp(['  simulation completed in ' scaleTime(toc)]);
            % end            
            
            % update the number of time steps taken
            obj.time_steps_taken = obj.time_steps_taken + Nt;
            
            % %clean up used figures
            % if obj.plot_sim
            %     close(img);
            %     close(pbar);
            %     drawnow;
            % end    
            
            % save movie
            if obj.record_movie
                close(video_obj);
            end
            
            % update command line status
            % if obj.display_updates
            %     disp(['  total computation time ' scaleTime(etime(clock, start_time))]);
            % end
            % 
          end

        
        % plot the current temperature distribution
        function plotTemp(obj)
            
            switch obj.dim
                case 1

                    % plot temperature distribution
                    plot(obj.x_vec .* obj.plot_axes_scale, obj.T);

                    % add plot labels
                    xlabel(['x-position [' obj.plot_axes_prefix 'm]']);

                    % adjust plot scale
                    set(gca, 'XLim', obj.x_vec([1, end]) .* obj.plot_axes_scale);
                    if isnumeric(obj.plot_scale)
                        set(gca, 'YLim', obj.plot_scale);
                    end

                case 2

                    % plot temperature distribution
                    if isnumeric(obj.plot_scale)
                        imagesc(obj.y_vec .* obj.plot_axes_scale, obj.x_vec .* obj.plot_axes_scale, obj.T, obj.plot_scale);
                    else
                        imagesc(obj.y_vec .* obj.plot_axes_scale, obj.x_vec .* obj.plot_axes_scale, obj.T);
                    end
                    colormap(obj.color_map);
                    axis image;

                    % add plot labels
                    ylabel(['x-position [' obj.plot_axes_prefix 'm]']);
                    xlabel(['y-position [' obj.plot_axes_prefix 'm]']);
                case 3

                    % plot temperature distribution in x-y plane
                    subplot(2, 2, 1), 
                    if isnumeric(obj.plot_scale)
                        imagesc(obj.y_vec .* obj.plot_axes_scale, obj.x_vec .* obj.plot_axes_scale, squeeze(obj.T(:, :, ceil(obj.Nz/2))), obj.plot_scale);
                    else
                        imagesc(obj.y_vec .* obj.plot_axes_scale, obj.x_vec .* obj.plot_axes_scale, squeeze(obj.T(:, :, ceil(obj.Nz/2))));
                    end
                    axis image;
                    
                    % add plot labels
                    title('x-y plane');
                    
                    % plot temperature distribution in x-z plane
                    subplot(2, 2, 2)
                    if isnumeric(obj.plot_scale)
                        imagesc(obj.z_vec .* obj.plot_axes_scale, obj.x_vec .* obj.plot_axes_scale, squeeze(obj.T(:, ceil(obj.Ny/2), :)), obj.plot_scale);
                    else
                        imagesc(obj.z_vec .* obj.plot_axes_scale, obj.x_vec .* obj.plot_axes_scale, squeeze(obj.T(:, ceil(obj.Ny/2), :)));
                    end
                    axis image;
                    
                    % add plot labels
                    title('x-z plane');
                    xlabel(['(All axes in ' obj.plot_axes_prefix 'm)']);
                    
                    % plot temperature distribution in y-z plane
                    subplot(2, 2, 3)
                    if isnumeric(obj.plot_scale)
                        imagesc(obj.z_vec .* obj.plot_axes_scale, obj.y_vec .* obj.plot_axes_scale, squeeze(obj.T(ceil(obj.Nx/2), :, :)), obj.plot_scale);
                    else
                        imagesc(obj.z_vec .* obj.plot_axes_scale, obj.y_vec .* obj.plot_axes_scale, squeeze(obj.T(ceil(obj.Nx/2), :, :)));
                    end
                    axis image;
                    
                    % add plot labels
                    title('y-z plane');
                    
                    % set colormap
                    colormap(obj.color_map);
                    
            end
            
            % force plot update
            drawnow;
                    
        end        
        
        % set the optional input parameters
        function setOptionalInputs(obj, input_params)
    
            % check inputs are given as pairs
            if rem(length(input_params), 2)
                error('Optional input parameters must be given as param, value pairs.');
            end            
            
            % loop through the optional inputs
            for input_index = 1:2:length(input_params)
                switch input_params{input_index}           
                    case 'DisplayUpdates'
                        obj.display_updates = input_params{input_index + 1};
                        if ~islogical(obj.display_updates)
                            error('Optional input ''DisplayUpdates'' must be Boolean.');
                        end 
                    case 'MovieArgs'
                        obj.movie_args = input_params{input_index + 1};
                        if rem(length(obj.movie_args), 2)
                            error('Optional input ''MovieArgs'' must be given as param, value pairs.');
                        end
                    case 'MovieName'
                        obj.movie_name = input_params{input_index + 1};
                        if ~ischar(obj.movie_name)
                            error('Optional input ''MovieName'' must be a string.');
                        end
                    case 'MovieProfile'
                        obj.movie_profile = input_params{input_index + 1};                        
                    case 'PlotFreq'
                        obj.plot_freq = input_params{input_index + 1}; 
                        if ~(numel(obj.plot_freq) == 1 && isnumeric(obj.plot_freq) && (round(obj.plot_freq) == obj.plot_freq) && (obj.plot_freq > 0))
                            error('Optional input ''PlotFreq'' must be a single positive integer value.');
                        end               
                    case 'PlotScale'
                        obj.plot_scale = input_params{input_index + 1};
                        if ~strcmp(obj.plot_scale, 'auto') && (~(numel(obj.plot_scale) == 2 && isnumeric(obj.plot_scale)))
                            error('Optional input ''PlotScale'' must be a 2 element numerical array or set to ''auto''.');    
                        end
                    case 'PlotSim'
                        obj.plot_sim = input_params{input_index + 1};
                        if ~islogical(obj.plot_sim)
                            error('Optional input ''PlotSim'' must be Boolean.');
                        end      
                    case 'RecordMovie'
                        obj.record_movie = input_params{input_index + 1};    
                        if ~islogical(obj.record_movie)
                            error('Optional input ''RecordMovie'' must be Boolean.');
                        end
                    case 'UsekSpace'
                        obj.use_kspace = input_params{input_index + 1}; 
                        if ~islogical(obj.use_kspace)
                            error('Optional input ''UsekSpace'' must be Boolean.');
                        end
                     case 'Sensor_Mask'
                        obj.Sensor_Mask = input_params{input_index + 1}; 
                        if ~ismatrix(obj.Sensor_Mask)
                            error('Optional input ''Sensor_Mask'' must be Matrix.');
                        end  
                     case 'Convection_Coefficient'
                        obj.Convection_Coefficient = input_params{input_index + 1}; 
                        if ~isnumeric(obj.Convection_Coefficient)
                            error('Optional input ''Sensor_Mask'' must be num.');
                        end 
                     case 'tt_center_x'
                        obj.tt_center_x = input_params{input_index + 1}; 
                        if ~isnumeric(obj.tt_center_x)
                            error('Optional input ''Sensor_Mask'' must be num.');
                     end
                    otherwise
                        error(['Unknown optional input ' input_params{input_index} '.']);
                end
            end
        end        
                   
    end
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    % set and get functions for dependent variables
    methods
            function wsad = i_wsad(obj, i, j)
                if(~obj.Sensor_Mask(i-1,j))
                    wsad.w = 0.5;
                    wsad.s = 0.5;
                    wsad.a = 1;
                    wsad.d = 0;
                elseif( ~obj.Sensor_Mask(i+1,j))
                    wsad.w = 0.5;
                    wsad.s = 0.5;
                    wsad.a = 0;
                    wsad.d = 1;
                elseif( ~obj.Sensor_Mask(i,j-1))
                    wsad.w = 0;
                    wsad.s = 1;
                    wsad.a = 0.5;
                    wsad.d = 0.5;
                elseif( ~obj.Sensor_Mask(i,j+1))
                    wsad.w = 1;
                    wsad.s = 0;
                    wsad.a = 0.5;
                    wsad.d = 0.5;
                end

            end

        function ablation_depth = get.ablation_depth(obj) 
                mask = obj.cem43 >= 240; % 这个是设置从换能器到最远消融深度
                flag = 1;
                T_x = 0;
                for x = obj.Nx:-1:1
                    for y = 1:obj.Ny
                        if(mask(x,y) == 1)
                            T_x = x;
                            flag = 0;
                            break;
                        end
                    end
                    if(flag == 0)
                        break;
                    end
                end
                if(max(max(obj.cem43)) >= 240)
    
                    ablation_depth = (T_x + 1 - obj.tt_center_x) * obj.dx *1e3 + obj.dx; %[mm]
    
                else
                    ablation_depth = 0;
                end
%             mask = obj.cem43 >= 240;
%             dy_in = 0;
%             dy_out = 0;
%             flag = 1;
%             flag_out = 1;
%              T_here = [0,0];
%             for x = obj.Nx:-1:1
%                 for y = 1:obj.Ny
%                     if(mask(x,y) == 1 && flag == 1)
%                         dy_in = y;
%                         flag = 0;
%                     end
%                     if(mask(x,y) == 0 && flag == 0)
%                          dy_out = y - 1;
%                          T_here = [x, fix((dy_out + dy_in) / 2)];
%                          flag_out = 0;
%                          break;
%                     end
%                 end
%                 if(flag_out == 0)
%                     break;
%                 end
%             end
%             x =  T_here(1,1) - 1;
%             y =  T_here(1,2);
%             for i = x:-1:1
%                 if(mask(i,y) < 1)
%                     T_here1 = [i y];
%                     break;
%                 end
%             end   
%             ablation_depth = (T_here(1,1) + 1 - T_here1(1,1)) * obj.dx *1e3; %[mm]
        end
        % return lesion according to cem43 > 240mins
        function lesion_map = get.lesion_map(obj)
            lesion_map = obj.cem43 >= 240;
        end
        
        % return lesion volume or area according to cem43 > 240mins
        function lesion_size = get.lesion_size(obj)
            
            % get grid dimensions
            switch obj.dim
                case 1
                    grid_dim = obj.dx;
                case 2
                    grid_dim = obj.dx .* obj.dy;
                case 3
                    grid_dim = obj.dx .* obj.dy .* obj.dz;
            end
            
            % compute lesion size
            lesion_size = sum(obj.lesion_map(:)) .* grid_dim;
            
        end
        
        % compute stability criteria
        function dt_limit = get.dt_limit(obj)
    
            % extract maximum value of the diffusion coefficient
            diffusion_coeff = obj.diffusion_p1(:) .* obj.diffusion_p2(:);
            D_max = max(diffusion_coeff);
            
            % extract maximum and minimum spatial frequencies
            k_max = max(obj.k(:));
            k_min = min(obj.k(:));
            
            % calculate maximum time step based on stability conditions:
            if (numel(obj.perfusion_coeff) == 1) && (obj.perfusion_coeff == 0)
                               
                % no perfusion
                
                if obj.diffusion_coeff_ref >= D_max/2
                    
                    % unconditionally stable
                    dt_limit = Inf;
                    
                else
                    
                    % conditionally stable
                    dt_limit = - log(1 - 2 .* obj.diffusion_coeff_ref ./ D_max) ...
                        ./ (obj.diffusion_coeff_ref .* k_max.^2);
                    
                end

            else
                
                % perfusion
                
                reference = obj.diffusion_coeff_ref .* k_max.^2 + obj.perfusion_coeff_ref;
                condition = 0.5*(obj.diffusion_p1 .* obj.diffusion_p2 .* k_max.^2 + obj.perfusion_coeff);
                
                if reference >= max(condition)
                    
                    % unconditionally stable
                    dt_limit = Inf;
                    
                else
                    
                    % conditionally stable
                    kmax_val = - log(1 - 2*(obj.diffusion_coeff_ref * k_max.^2 + obj.perfusion_coeff_ref) ./ max(diffusion_coeff .* k_max.^2 + obj.perfusion_coeff))...
                        ./ (obj.diffusion_coeff_ref*k_max.^2 + obj.perfusion_coeff_ref);
                    kmin_val = - log(1 - 2*(obj.diffusion_coeff_ref * k_min.^2 + obj.perfusion_coeff_ref) ./ max(diffusion_coeff .* k_min.^2 + obj.perfusion_coeff))...
                        ./ (obj.diffusion_coeff_ref*k_min.^2 + obj.perfusion_coeff_ref);
                    dt_limit = min(kmax_val, kmin_val);
                    
                end

            end
            
        end

    end   
    
    % internal class methods only accessible by other functions 
    methods (Hidden = true, Access = 'protected') 
        
        %该方法的目的是根据给定的参数kappa生成三个空间维度上的导数矩阵（deriv_x, deriv_y, deriv_z）
        %这些矩阵在处理波动方程、热传导问题或其他偏微分方程（PDE）的数值解时非常有用。        
        % get derivative matrices
%         %bsxfun是MATLAB中的二元单元函数（Binary Singleton Expansion Function），
%         用于实现两个数组的逐元素操作， 当它们的维度不完全匹配时，
%         bsxfun会自动扩展较小数组的维度以匹配较大数组的维度
%         @times表示乘法操作。
%         bsxfun(@times, reshape(obj.kx_vec, [obj.Nx, 1, 1]), sqrt(kappa))
%         将经过重塑的obj.kx_vec数组与sqrt(kappa)逐元素相乘。
%         由于reshape(obj.kx_vec, [obj.Nx, 1, 1])是一个三维数组而
%         sqrt(kappa)是一个标量或与obj.kx_vec维度匹配的数组，
%         bsxfun会将sqrt(kappa)扩展到与reshape(obj.kx_vec, [obj.Nx, 1, 1])
%         相同的维度，然后进行逐元素乘法。   
        function [deriv_x, deriv_y, deriv_z] = getDerivMatrix(obj, kappa)
            
            % x-dimension
            deriv_x = bsxfun(@times, reshape(obj.kx_vec, [obj.Nx, 1, 1]), sqrt(kappa));

            % y-dimension
            if obj.dim > 1
                deriv_y = bsxfun(@times, reshape(obj.ky_vec, [1, obj.Ny]), sqrt(kappa));
            else
                deriv_y = 0;
            end

            % z-dimension
            if obj.dim > 2
                deriv_z = bsxfun(@times, reshape(obj.kz_vec, [1, 1, obj.Nz]), sqrt(kappa));
            else
                deriv_z = 0;
            end
            
            switch obj.boundary_condition
                %在傅立叶变换中，导数通常通过乘以1i * k（其中k是空间频率，i是虚数单位）来表示
                case 'periodic'
                    deriv_x = 1i * deriv_x;
                    deriv_y = 1i * deriv_y;
                    deriv_z = 1i * deriv_z;
                %通过取反导数矩阵，实际上模拟了边界上物理量变化率的反转或停止，与“绝缘”或“反射”边界条件相符。
                %这种处理方式确保了在边界处没有外流或进流，与物理现象保持一致。    
                case 'insulating'
                    deriv_x = -deriv_x;
                    deriv_y = -deriv_y;
                    deriv_z = -deriv_z;
            end

        end
        %fft快速傅里叶变换
        % forward trigonometric transform
        function out = FT(obj, x)

            switch obj.boundary_condition
                case 'periodic'
                    
                    % define forward Fourier transform operators
                    switch obj.dim
                        case 1
                            out = fft(x);
                        case 2
                            out = fft2(x);
                        case 3
                            out = fftn(x);
                    end
                    
                case 'insulating'
                    
                    % define forward transform for WSWS symmetry (DCT-I)
                    dtt_type = 1;
                    switch obj.dim
                        case 1                           
                            out = dtt1D(x, dtt_type);
                        case 2
                            out = dtt2D(x, dtt_type);
                        case 3
                            out = dtt3D(x, dtt_type);
                    end                         
                    
                case 'conducting'
                    
                    % define forward transform for WAWA symmetry (DST-I)
                    dtt_type = 5;
                    switch obj.dim
                        case 1                           
                            out = dtt1D(x, dtt_type);
                        case 2
                            out = dtt2D(x, dtt_type);
                        case 3
                            out = dtt3D(x, dtt_type);
                    end                     
                    
            end
            
        end
        
        % inverse trigonometric transform
        function out = IT(obj, x)
            
            switch obj.boundary_condition
                case 'periodic'
                    
                    % define inverse Fourier transform operators
                    switch obj.dim
                        case 1
                            out = real(ifft(x));
                        case 2
                            out = real(ifft2(x));
                        case 3
                            out = real(ifftn(x));
                    end
                    
                case 'insulating'
                    
                    % define inverse transform for WSWS symmetry (DCT-I)
                    dtt_type = 1;
                    switch obj.dim
                        case 1                           
                            out = dtt1D(x, dtt_type) ./ obj.M;
                        case 2
                            out = dtt2D(x, dtt_type) ./ obj.M;
                        case 3
                            out = dtt3D(x, dtt_type) ./ obj.M;
                    end   
                    
                case 'conducting'
                    
                    % define inverse transform for WAWA symmetry (DST-I)
                    dtt_type = 5;
                    switch obj.dim
                        case 1                           
                            out = dtt1D(x, dtt_type) ./ obj.M;
                        case 2
                            out = dtt2D(x, dtt_type) ./ obj.M;
                        case 3
                            out = dtt3D(x, dtt_type) ./ obj.M;
                    end   
                    
            end
            
        end        
        
        % display command line update
        function displayUpdate(obj, Nt, dt, start_time)
           
            % display start time and time steps
            disp('Running k-Wave thermal simulation...');
            disp(['  start time: ' datestr(start_time)]);
            disp(['  dt: ' scaleSI(dt) 's, t_end: ' scaleSI(dt*Nt) 's, time steps: ' num2str(Nt)]);
            
            % get suitable scaling factor
            grid_size = [obj.Nx .* obj.dx, obj.Ny .* obj.dy, obj.Nz .* obj.dz];
            [~, scale, prefix] = scaleSI( min(grid_size(grid_size ~= 0)) ); %#ok<*ASGLU>

            % display the grid size
            switch obj.dim
                case 1
                    disp(['  input grid size: ' num2str(obj.Nx) ' grid points (' num2str(obj.Nx .* obj.dx .* scale) prefix 'm)']);
                case 2
                    disp(['  input grid size: ' num2str(obj.Nx) ' by ' num2str(obj.Ny) ' grid points (' num2str(obj.Nx .* obj.dx .* scale) ' by ' num2str(obj.Ny .* obj.dy .* scale) prefix 'm)']);
                case 3
                    disp(['  input grid size: ' num2str(obj.Nx) ' by ' num2str(obj.Ny) ' by ' num2str(obj.Nz) ' grid points (' num2str(obj.Nx .* obj.dx .* scale) ' by ' num2str(obj.Ny .* obj.dy .* scale) ' by ' num2str(obj.Nz .* obj.dz .* scale) prefix 'm)']); 
            end

        end
        
    end
    
end 