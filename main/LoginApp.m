classdef LoginApp < matlab.apps.AppBase
    % LOGINAPP  登录界面
    % - 平台：基于强化学习的前列腺超声消融仿真平台
    % - 功能：用户名/密码登录 -> 进入主界面 MainApp
    % - 特点：密码框为 password 类型；支持回车登录；资源路径安全；基础校验与提示
    %% ========= App 组件 =========
    properties (Access = public)
        V10UIFigure        matlab.ui.Figure
        EditField          matlab.ui.control.EditField   % 顶部标题栏只读显示
        Image              matlab.ui.control.Image       % 左侧图片
        PasswordEditField  matlab.ui.control.EditField   % 密码（password类型）
        Label_2            matlab.ui.control.Label       % “密码”标签
        UsernameEditField  matlab.ui.control.EditField   % 用户名
        Label              matlab.ui.control.Label       % “账号”标签
        LoginButton        matlab.ui.control.Button      % 登录按钮
    end
    %% ========= 内部状态 =========
    properties (Access = private, Constant)
        APP_TITLE   = '基于强化学习的前列腺超声消融仿真平台V1.0';
        HEADER_TEXT = '基于强化学习的前列腺超声消融仿真平台V1.0';
    end
    properties (Access = private)
        % 简单演示用的账号信息（实际项目不建议硬编码）
        correctUsername = 'admin';
        correctPassword = '123456';
    end
    %% ========= 回调 =========
    methods (Access = private)
        % ---- 登录按钮 ----
        function LoginButtonPushed(app, ~)
            % 防重复点击
            app.LoginButton.Enable = 'off';
            c = onCleanup(@() set(app.LoginButton,'Enable','on'));
            username = strtrim(app.UsernameEditField.Value);
            password = string(app.PasswordEditField.Value);
            % 基础校验
            if username == "" || password == ""
                uialert(app.V10UIFigure, '请输入账号和密码。', '提示', 'Icon','warning');
                return;
            end
            if app.isValidCredentials(username, password)
                % 登录成功
                disp('登录成功');
                try
                    MainApp;  % 假设主界面类名为 MainApp
                catch ME
                    uialert(app.V10UIFigure, ...
                        sprintf('无法打开主界面：\n%s', ME.message), ...
                        '错误', 'Icon','error');
                    return;
                end
                % 关闭登录界面
                delete(app);
            else
                uialert(app.V10UIFigure, '账号或密码错误！', '登录失败', 'Icon','error');
            end
        end
        % ---- 支持回车键触发登录 ----
        function onKeyPress(app, evt)
            if strcmpi(evt.Key, 'return') || strcmpi(evt.Key, 'enter')
                app.LoginButtonPushed();
            end
        end
    end
    %% ========= 组件创建 =========
    methods (Access = private)
        function rootPath = getProjectRoot(app)
            rootPath = fileparts(fileparts(mfilename('fullpath')));
        end
        function createComponents(app)
            % 资源根目录（仓库根目录）
            rootPath = getProjectRoot(app);
            iconPath = fullfile(rootPath, 'data', 'icon.png');
            imgPath  = fullfile(rootPath, 'data', '1.png');
            % ---- 主窗体 ----
            app.V10UIFigure = uifigure('Visible','off');
            app.V10UIFigure.Position  = [100 100 429 251];
            app.V10UIFigure.Name      = app.APP_TITLE;
            if exist(iconPath, 'file'); app.V10UIFigure.Icon = iconPath; end
            app.V10UIFigure.WindowKeyPressFcn = @(~,e) onKeyPress(app,e);
            % ---- 登录按钮 ----
            app.LoginButton = uibutton(app.V10UIFigure,'push');
            app.LoginButton.ButtonPushedFcn = @app.LoginButtonPushed;
            app.LoginButton.BackgroundColor = [0.5686 0.8 0.9020];
            app.LoginButton.FontWeight = 'bold';
            app.LoginButton.Position = [232 59 136 23];
            app.LoginButton.Text = '登录';
            % ---- “账号”标签 ----
            app.Label = uilabel(app.V10UIFigure);
            app.Label.HorizontalAlignment = 'right';
            app.Label.FontWeight = 'bold';
            app.Label.Position = [223 149 29 22];
            app.Label.Text = '账号';
            % ---- 账号输入框 ----
            app.UsernameEditField = uieditfield(app.V10UIFigure,'text');
            app.UsernameEditField.FontWeight = 'bold';
            app.UsernameEditField.Position = [267 148 101 23];
            % ---- “密码”标签 ----
            app.Label_2 = uilabel(app.V10UIFigure);
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.FontWeight = 'bold';
            app.Label_2.Position = [223 107 29 22];
            app.Label_2.Text = '密码';
            % ---- 密码输入框（password 类型）----
            app.PasswordEditField = uieditfield(app.V10UIFigure,'password');
            app.PasswordEditField.FontWeight = 'bold';
            app.PasswordEditField.Position = [267 106 101 23];
            % ---- 左侧图片 ----
            app.Image = uiimage(app.V10UIFigure);
            app.Image.Position = [-55 1 279 251];
            if exist(imgPath, 'file')
                app.Image.ImageSource = imgPath;
            else
                app.Image.ImageSource = []; % 没图也不报错
            end
            % ---- 顶部标题只读显示 ----
            app.EditField = uieditfield(app.V10UIFigure,'text');
            app.EditField.HorizontalAlignment = 'center';
            app.EditField.FontWeight = 'bold';
            app.EditField.Editable = 'off';
            app.EditField.Position = [167 230 263 22];
            app.EditField.Value = app.HEADER_TEXT;
            % 最后显示窗口
            app.V10UIFigure.Visible = 'on';
        end
    end
    %% ========= 内部工具 =========
    methods (Access = private)
        function tf = isValidCredentials(app, user, pass)
            tf = strcmp(user, app.correctUsername) && strcmp(pass, app.correctPassword);
        end
    end
    %% ========= 构造与析构 =========
    methods (Access = public)
        function app = LoginApp
            % 创建 UI
            createComponents(app);
            % 注册到 App Designer
            registerApp(app, app.V10UIFigure);
            if nargout == 0
                clear app
            end
        end
        function delete(app)
            % 关闭窗口
            if isvalid(app.V10UIFigure)
                delete(app.V10UIFigure);
            end
        end
    end
end
