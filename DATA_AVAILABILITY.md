# Data Availability

This repository contains the code, example input data, expert demonstration data,
and pretrained agents needed to reproduce the archived simulation workflows.

## Public Archive

- GitHub repository: https://github.com/zhuzhucool/IL-DRL-ablation
- Zenodo DOI: https://doi.org/10.5281/zenodo.20133085
- Archived release tag: `v1.0.1`

Record the exact release commit hash in the GitHub release and Zenodo archive
metadata when the release is finalized.

## Included Data

- `data/prostate800_001mm_down_400_02_6479250.mat`: example prostate mask for app-based simulation.
- `data/Q_1600_005mm_down_400_02mm_2mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_3mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_6mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_10mhz.mat`
- `agent/Agent325.mat` and `agent/Agent1000.mat`: pretrained agents used for DRL/IL-DRL simulation.
- `trainCode/expertData_dist.mat`: expert state-action demonstrations used for behavior cloning.
- `trainCode/0624/210.mat`: prostate-shape training input used by the archived training script.

## Privacy And Restrictions

Before public release, confirm that all `.mat` files listed above contain only
derived masks, simulation inputs, pretrained model parameters, or synthetic/example
data, and do not contain private clinical identifiers or restricted third-party data.

Large intermediate training checkpoints are not required for reproduction and are
excluded from the recommended Git commit. The pretrained agents used by the app
are retained in `agent/`.
