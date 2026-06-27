# Reproducibility Guide

This repository supports two reproduction paths:

1. App-based simulation using archived pretrained agents.
2. Training reproduction using the behavior-cloning plus PPO workflow in
   `trainCode/0624/`.

## App-Based Simulation

Open MATLAB R2024a from the repository root:

```matlab
addpath(genpath(pwd));
LoginApp
```

Default demonstration login:

```text
Username: admin
Password: 123456
```

Use the included prostate mask:

```text
data/prostate800_001mm_down_400_02_6479250.mat
```

Use the included frequency data in `data/` unless testing custom inputs.

## Figure-Level Mapping

Use the following mapping when regenerating manuscript figures. Replace the
figure labels if the manuscript numbering changes.

| Manuscript output | Repository workflow |
| --- | --- |
| Simulation interface screenshots | `LoginApp` then open the main interface; source files are `main/LoginApp.m` and `main/MainApp.m`. |
| Binary-control ablation result | Load the included prostate mask, select binary control in the app, run simulation, export results. |
| PID-control ablation result | Load the included prostate mask, select PID control in the app, run simulation, export results. |
| DRL-control ablation result | Load the included prostate mask, select DRL mode, use `agent/Agent325.mat` or the manuscript-specified agent, run simulation, export results. |
| IL-DRL-control ablation result | Load the included prostate mask, select IL-DRL mode, use the archived pretrained agent, run simulation, export results. |
| Training curve or agent-learning result | Run `trainCode/0624/rotof_beif.m`; training statistics are returned as `trainingStats`, and checkpoints are saved to `trainCode/0624/agent_checkpoints/`. |

## Expected Inputs

- Prostate mask variable: `M_resized` for app simulation, or `All_M_resized`
  / `M_resized` for the training environment.
- Heat deposition variables: each `data/Q_*.mat` file must contain `Q`.
- Expert demonstration variables: `trainCode/expertData_dist.mat` must contain
  `expertStates` and `expertActions`.

## Determinism

The training script fixes the MATLAB random seed with `rng(24)`. Numerical
results can still differ slightly across GPU models, MATLAB patch releases, and
operating systems because the workflow uses GPU deep-learning operations and
iterative thermal simulation.
