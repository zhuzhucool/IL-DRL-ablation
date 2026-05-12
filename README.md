# IL-DRL Ablation Simulation Platform

This repository contains a MATLAB application for prostate ultrasound ablation simulation and control using binary, PID, DRL, and IL-DRL controllers.

## Directory Structure

- `main/`: MATLAB App Designer source exported as `.m` files.
- `agent/`: Pre-trained controller agent files used by the DRL and IL-DRL modes.
- `data/`: Example input data, transducer frequency data, and UI image assets.
- `drl_pid/`: Simulation and controller support code, including the bundled k-Wave toolbox.

## Requirements

- MATLAB with App Designer support.
- MATLAB toolboxes required by the code, including image processing and reinforcement learning functionality where applicable.
- k-Wave is included under `drl_pid/k-Wave`.

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

## Included Data

The repository includes small example `.mat` and image files used by the app:

- `data/prostate800_001mm_down_400_02_6479250.mat`
- `data/Q_1600_005mm_down_400_02mm_2mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_3mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_6mhz.mat`
- `data/Q_1600_005mm_down_400_02mm_10mhz.mat`
- `agent/Agent1000.mat`
- `agent/Agent325.mat`

Before making the repository public, confirm that these files do not contain private clinical data, unpublished third-party data, or other restricted information.

## Notes for Public Release

- The `admin / 123456` login is intended only as a demonstration credential. Do not reuse it for any deployed or security-sensitive system.
- The project uses k-Wave, distributed under the GNU LGPL. The original k-Wave license files are retained in `drl_pid/k-Wave/license/`.
- If large datasets or full model checkpoints are needed, host them on Zenodo or another archival service and link the DOI here.
- Replace any placeholder GitHub or Zenodo links in manuscripts with the final repository URL and DOI before submission.

## k-Wave Citation

If this code is used in academic work, cite the k-Wave toolbox as appropriate. A primary reference is:

Treeby, B. E., and Cox, B. T. "k-Wave: MATLAB toolbox for the simulation and reconstruction of photoacoustic wave-fields." Journal of Biomedical Optics, 15(2), 021314, 2010.

Additional k-Wave citation guidance is included in `drl_pid/k-Wave/helpfiles/k-wave_license.html`.

## License

Add the license for this project before public release. The bundled k-Wave toolbox remains under its own LGPL license terms.
