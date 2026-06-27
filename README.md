# IL-DRL Ablation Simulation Platform

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20133085.svg)](https://doi.org/10.5281/zenodo.20133085)

This repository contains a MATLAB application for prostate ultrasound ablation simulation and control using binary, PID, DRL, and IL-DRL controllers.

## Associated Manuscript

This repository is the code release associated with the manuscript:

> Imitation learning-embedded deep reinforcement learning controller for MRI guided multi-frequency interstitial ultrasound ablation

The code provides the simulation environment, controller implementation, example data, training code, expert demonstration data, and pre-trained agent files used to support reproducibility of the main computational results.

## Citation

If you use this code, please cite the archived software release:

Lin, S., Zhu, Y., Cui, C., Chen, L., Tong, M., Xu, H., Li, Y., Wen, J., & Chen, K. IL-DRL Ablation Simulation Platform. Zenodo. https://doi.org/10.5281/zenodo.20133085

## Directory Structure

- `main/`: MATLAB App Designer source exported as `.m` files.
- `agent/`: Pre-trained controller agent files used by the DRL and IL-DRL modes.
- `data/`: Example input data, transducer frequency data, and UI image assets.
- `drl_pid/`: Simulation and controller support code, including the bundled k-Wave toolbox.
- `trainCode/0624/`: Archived manuscript training workflow for behavior cloning plus PPO.
- `trainCode/expertData_dist.mat`: Expert demonstrations used for behavior cloning.
- `TRAINING.md`: Training configuration and reproduction instructions.
- `REPRODUCIBILITY.md`: App and figure-level reproduction guide.
- `DATA_AVAILABILITY.md`: Data, archive, and release information.

## Requirements

- MATLAB R2024a with App Designer support.
- MATLAB toolboxes required by the code, including Reinforcement Learning Toolbox, Deep Learning Toolbox, Image Processing Toolbox, Signal Processing Toolbox, and Statistics and Machine Learning Toolbox.
- k-Wave is included under `drl_pid/k-Wave`.
- See `requirements.txt` for the archived dependency list.

## Quick Start

1. Open MATLAB and switch to the repository root directory.
2. Add the project paths:

   ```matlab
   addpath(genpath(pwd));
   ```

3. Start the login interface:

   ```matlab
   LoginApp
   ```

4. Use the default demonstration credentials:

   ```text
   Username: admin
   Password: 123456
   ```

5. In the main interface:
   - Import a prostate shape `.mat` file containing the variable `M_resized`.
   - Import a transducer frequency path if using custom frequency data. If not selected, the app defaults to the repository `data/` directory.
   - Select the controller mode and run the ablation simulation.

## Training Reproduction

The archived training workflow is in `trainCode/0624/`:

```matlab
addpath(genpath(pwd));
run(fullfile('trainCode', '0624', 'rotof_beif.m'));
```

The script uses `trainCode/expertData_dist.mat` for behavior cloning,
`trainCode/0624/210.mat` for training prostate-shape input, and the shared
frequency data in `data/`. Checkpoints generated during a new training run are
written to `trainCode/0624/agent_checkpoints/` and are ignored by Git.

See `TRAINING.md` for hyperparameters and environment details.

## Reproducibility

See `REPRODUCIBILITY.md` for the app workflow and figure-level mapping. The
current reproducibility-package commit is:

```text
04f7a5288385bd48fd0a19f1892bed54043081b2
```

Publish a `v1.0.0` GitHub release from this commit before finalizing the Zenodo archive.

## Included Data

The repository includes small example `.mat` and image files used by the app:

- `data/prostate800_001mm_down_400_02_6479250.mat`
- `data/Q_1600_005mm_down_400_02mm_2mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_3mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_6mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_10mhz.mat`
- `agent/Agent1000.mat`
- `agent/Agent325.mat`
- `trainCode/expertData_dist.mat`
- `trainCode/0624/210.mat`

Before making the repository public, confirm that these files do not contain private clinical data, unpublished third-party data, or other restricted information.

## Notes for Public Release

- The `admin / 123456` login is intended only as a demonstration credential. Do not reuse it for any deployed or security-sensitive system.
- The project uses k-Wave, distributed under the GNU LGPL. The original k-Wave license files are retained in `drl_pid/k-Wave/license/`.

## k-Wave Citation

If this code is used in academic work, cite the k-Wave toolbox as appropriate. A primary reference is:

Treeby, B. E., and Cox, B. T. "k-Wave: MATLAB toolbox for the simulation and reconstruction of photoacoustic wave-fields." Journal of Biomedical Optics, 15(2), 021314, 2010.

Additional k-Wave citation guidance is included in `drl_pid/k-Wave/helpfiles/k-wave_license.html`.

## License

This project is released under the MIT License. See `LICENSE`. The bundled
k-Wave toolbox remains under its own license terms; the original k-Wave license
files are retained in `drl_pid/k-Wave/license/` and `trainCode/drl_pid/k-Wave/license/`
where present.
