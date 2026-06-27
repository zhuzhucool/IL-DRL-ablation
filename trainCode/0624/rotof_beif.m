%ROTOF_BEIF Train the IL-DRL ablation controller.
%
% This script reproduces the archived behavior-cloning + PPO workflow used
% for the manuscript experiments. Run it from the repository root with:
%
%   addpath(genpath(pwd));
%   run(fullfile('trainCode', '0624', 'rotof_beif.m'));
%
% Set MATLAB_GPU_DEVICE before launching MATLAB to select a GPU, for example:
%   MATLAB_GPU_DEVICE=2

clear;
clc;

%% Configuration
scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(scriptDir));

config = struct();
config.randomSeed = 24;
config.expertDataPath = fullfile(repoRoot, 'trainCode', 'expertData_dist.mat');
config.checkpointDir = fullfile(scriptDir, 'agent_checkpoints');

config.hiddenUnits = 256;
config.actionPowerRangeW = [0, 4];
config.actionRotationRangeDegPerSec = [8/60, 2];

config.behaviorCloningEpochs = 2000;
config.behaviorCloningBatchSize = 1024;
config.behaviorCloningLearnRate = 1e-4;
config.behaviorCloningActionNoiseStd = 0.1;

config.actorLearnRate = 1e-4;
config.criticLearnRate = 3e-4;
config.gradientThreshold = 1;

config.ppoExperienceHorizon = 10000;
config.ppoClipFactor = 0.2;
config.ppoEntropyLossWeight = 0.01;
config.ppoMiniBatchSize = 512;
config.ppoNumEpoch = 10;
config.ppoGAEFactor = 0.95;
config.ppoDiscountFactor = 0.9992;

config.maxEpisodes = 1000;
config.maxStepsPerEpisode = 2000;
config.scoreAveragingWindow = 30;
config.saveAgentRewardThreshold = -200;

%% Environment setup
setupTrainingPaths(repoRoot, scriptDir);
deviceName = selectExecutionDevice();
rng(config.randomSeed);

env = rot_guiyiout_test_error_abliation;
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
numObs = prod(obsInfo.Dimension);
numAct = prod(actInfo.Dimension);

%% Actor and critic
actorNet = buildGaussianActorNetwork(numObs, numAct, actInfo, config.hiddenUnits);
criticNet = buildCriticNetwork(numObs, config.hiddenUnits);
critic = rlValueFunction(criticNet, obsInfo, UseDevice=deviceName);

%% Expert demonstrations
expertData = load(config.expertDataPath);
expertStates = expertData.expertStates;
expertActions = expertData.expertActions;

%% Behavior-cloning pretraining
actorNet = initialize(actorNet);
[adamMoment1, adamMoment2] = initializeAdamMoments(actorNet);

fprintf('Starting behavior-cloning pretraining for %d epochs...\n', ...
    config.behaviorCloningEpochs);

adamIteration = 1;
for epoch = 1:config.behaviorCloningEpochs
    batchIndex = randperm(size(expertStates, 1), config.behaviorCloningBatchSize);
    batchStates = expertStates(batchIndex, :);
    batchActions = normalizePhysicalActions( ...
        expertActions(batchIndex, :), ...
        config.actionPowerRangeW, ...
        config.actionRotationRangeDegPerSec);
    batchActions = addActionNoise(batchActions, config.behaviorCloningActionNoiseStd);

    dlStates = dlarray(batchStates', 'CB');
    dlActions = dlarray(batchActions', 'CB');
    [lossBC, gradients] = dlfeval(@gaussianNllGradients, actorNet, dlStates, dlActions);

    for learnableIndex = 1:size(actorNet.Learnables, 1)
        [actorNet.Learnables.Value{learnableIndex}, ...
            adamMoment1{learnableIndex}, ...
            adamMoment2{learnableIndex}] = adamupdate( ...
                actorNet.Learnables.Value{learnableIndex}, ...
                gradients.Value{learnableIndex}, ...
                adamMoment1{learnableIndex}, ...
                adamMoment2{learnableIndex}, ...
                adamIteration, ...
                config.behaviorCloningLearnRate);
    end
    adamIteration = adamIteration + 1;

    fprintf('BC epoch %d/%d, loss %.4f\n', ...
        epoch, config.behaviorCloningEpochs, lossBC);
end

fprintf('Behavior-cloning pretraining complete.\n');

actor = rlContinuousGaussianActor(actorNet, obsInfo, actInfo, ...
    ActionMeanOutputNames="netMout", ...
    ActionStandardDeviationOutputNames="netSDout", ...
    ObservationInputNames="netObsIn", ...
    UseDevice=deviceName);

%% PPO fine-tuning
actorOpts = rlOptimizerOptions( ...
    LearnRate=config.actorLearnRate, ...
    GradientThreshold=config.gradientThreshold);
criticOpts = rlOptimizerOptions( ...
    LearnRate=config.criticLearnRate, ...
    GradientThreshold=config.gradientThreshold);

agentOpts = rlPPOAgentOptions( ...
    ExperienceHorizon=config.ppoExperienceHorizon, ...
    ClipFactor=config.ppoClipFactor, ...
    EntropyLossWeight=config.ppoEntropyLossWeight, ...
    MiniBatchSize=config.ppoMiniBatchSize, ...
    NumEpoch=config.ppoNumEpoch, ...
    AdvantageEstimateMethod='gae', ...
    GAEFactor=config.ppoGAEFactor, ...
    ActorOptimizerOptions=actorOpts, ...
    CriticOptimizerOptions=criticOpts, ...
    DiscountFactor=config.ppoDiscountFactor, ...
    SampleTime=1);

agent = rlPPOAgent(actor, critic, agentOpts);

trainOpts = rlTrainingOptions( ...
    MaxEpisodes=config.maxEpisodes, ...
    MaxStepsPerEpisode=config.maxStepsPerEpisode, ...
    ScoreAveragingWindowLength=config.scoreAveragingWindow, ...
    Verbose=true, ...
    Plots='training-progress', ...
    SaveAgentDirectory=config.checkpointDir, ...
    StopTrainingCriteria='None', ...
    SaveAgentCriteria='EpisodeReward', ...
    SaveAgentValue=config.saveAgentRewardThreshold);

fprintf('Starting PPO training. Checkpoints will be written to:\n%s\n', ...
    config.checkpointDir);
trainingStats = train(agent, env, trainOpts);

%% Local functions
function setupTrainingPaths(repoRoot, scriptDir)
    addpath(genpath(fullfile(repoRoot, 'trainCode', 'drl_pid')), '-begin');
    addpath(genpath(fullfile(repoRoot, 'drl_pid')));
    addpath(fullfile(repoRoot, 'trainCode'));
    addpath(scriptDir);
end

function deviceName = selectExecutionDevice()
    gpuIndex = getenv('MATLAB_GPU_DEVICE');
    if ~isempty(gpuIndex)
        gpuDevice(str2double(gpuIndex));
    elseif gpuDeviceCount > 0
        gpuDevice(1);
    end

    if gpuDeviceCount > 0
        deviceName = "gpu";
    else
        deviceName = "cpu";
    end
end

function actorNet = buildGaussianActorNetwork(numObs, numAct, actInfo, hiddenUnits)
    sharedPath = [
        featureInputLayer(numObs, Name="netObsIn")
        fullyConnectedLayer(hiddenUnits)
        reluLayer(Name="sharedFC")
    ];

    meanPath = [
        fullyConnectedLayer(hiddenUnits, Name="meanFC")
        reluLayer
        fullyConnectedLayer(numAct, Name="actionMean")
        tanhLayer
        scalingLayer(Name="netMout", Scale=actInfo.UpperLimit)
    ];

    sdevPath = [
        fullyConnectedLayer(hiddenUnits, Name="stdFC")
        reluLayer
        fullyConnectedLayer(numAct, Name="actionStd")
        softplusLayer(Name="netSDout")
    ];

    actorNet = dlnetwork;
    actorNet = addLayers(actorNet, sharedPath);
    actorNet = addLayers(actorNet, meanPath);
    actorNet = addLayers(actorNet, sdevPath);
    actorNet = connectLayers(actorNet, "sharedFC", "meanFC/in");
    actorNet = connectLayers(actorNet, "sharedFC", "stdFC/in");
end

function criticNet = buildCriticNetwork(numObs, hiddenUnits)
    criticNet = dlnetwork([
        featureInputLayer(numObs)
        fullyConnectedLayer(hiddenUnits)
        reluLayer
        fullyConnectedLayer(hiddenUnits)
        reluLayer
        fullyConnectedLayer(1)
    ]);
end

function normalizedActions = normalizePhysicalActions(actions, powerRangeW, rotationRangeDegPerSec)
    normalizedActions = actions;
    normalizedActions(:, 1) = normalizeMinMax(actions(:, 1), powerRangeW);
    normalizedActions(:, 2) = normalizeMinMax(actions(:, 2), rotationRangeDegPerSec);
end

function normalizedValue = normalizeMinMax(value, range)
    normalizedValue = (value - range(1)) ./ (range(2) - range(1));
end

function noisyActions = addActionNoise(actions, noiseStd)
    noisyActions = actions + noiseStd * randn(size(actions));
    noisyActions = min(max(noisyActions, 0), 1);
end

function [moment1, moment2] = initializeAdamMoments(actorNet)
    numLearnables = size(actorNet.Learnables, 1);
    moment1 = cell(numLearnables, 1);
    moment2 = cell(numLearnables, 1);
    for learnableIndex = 1:numLearnables
        moment1{learnableIndex} = zeros(size(actorNet.Learnables.Value{learnableIndex}));
        moment2{learnableIndex} = zeros(size(actorNet.Learnables.Value{learnableIndex}));
    end
end

function [loss, gradients] = gaussianNllGradients(actorNet, batchStates, batchActions)
    [meanActions, stdActions] = forward(actorNet, batchStates);
    stdActions = stdActions + 0.001;

    negativeLogLikelihood = ((batchActions - meanActions).^2) ./ (2 * stdActions.^2) ...
        + 0.5 * log(2 * pi * stdActions.^2);
    loss = mean(negativeLogLikelihood, "all");
    gradients = dlgradient(loss, actorNet.Learnables);
end
