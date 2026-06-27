# Training Reproduction

The archived training workflow is in `trainCode/0624/`.

## Main Files

- `trainCode/0624/rotof_beif.m`: behavior-cloning plus PPO training entry point.
- `trainCode/0624/rot_guiyiout_test_error_abliation.m`: custom MATLAB reinforcement-learning environment.
- `trainCode/expertData_dist.mat`: expert demonstrations for behavior cloning.
- `trainCode/0624/210.mat`: training prostate-shape input.
- `trainCode/drl_pid/k-Wave/`: training-time thermal simulation support code.
- `data/Q_1600_005mm_down_400_02mm_*.mat`: acoustic heat deposition inputs shared by training and app simulation.

## Environment

Use MATLAB R2024a with the toolboxes listed in `requirements.txt`.

From the repository root:

```matlab
addpath(genpath(pwd));
run(fullfile('trainCode', '0624', 'rotof_beif.m'));
```

By default, the script uses GPU device 1 when a GPU is available. To select a
different GPU, set the environment variable before starting MATLAB:

```text
MATLAB_GPU_DEVICE=2
```

If no GPU is available, the script falls back to CPU execution. Full training is
computationally expensive and can take a long time on CPU.

## Training Configuration

- Random seed: `rng(24)`
- Observation dimension: 64
- Action dimension: 2
- Action bounds after normalization: `[0, 1]`
- Physical action ranges:
  - power: 0 to 4 W
  - rotation speed: 8/60 to 2 degrees/s
- Actor shared hidden units: 256
- Actor mean-path hidden units: 256
- Actor standard-deviation hidden units: 256
- Critic hidden units: 256 and 256
- Behavior-cloning epochs: 2000
- Behavior-cloning batch size: 1024
- Behavior-cloning learning rate: 1e-4
- PPO maximum episodes: 1000
- PPO maximum steps per episode: 2000
- PPO experience horizon: 10000
- PPO mini-batch size: 512
- PPO epochs per update: 10
- PPO clip factor: 0.2
- PPO entropy loss weight: 0.01
- PPO GAE factor: 0.95
- PPO discount factor: 0.9992

Generated training checkpoints are written to
`trainCode/0624/agent_checkpoints/`. This output directory is intentionally
ignored by Git.

## Notes

The older files directly under `trainCode/*.m` are exploratory variants and are
not the archived manuscript training workflow. Use the `trainCode/0624/` files
for reproduction.
