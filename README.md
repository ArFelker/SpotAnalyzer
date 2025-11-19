# SpotAnalyzer

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2020b+-blue.svg)](https://www.mathworks.com/products/matlab.html)

MATLAB GUI tool for automated detection and quantification of nanodots in TIRF microscopy images.

## Features

- Interactive 7-step workflow for spot detection and quantification
- Multi-channel support (bait + multiple prey channels)
- Automated/manual channel drift correction
- Local background estimation with ring masks
- Bait-specific contrast calculations
- Batch processing via Pooled Analysis GUI
- Excel export with comprehensive metrics

## System Requirements

### For MATLAB Version
- **OS:** Windows 10/11, macOS 10.15+, Linux
- **RAM:** 8 GB minimum, 16 GB recommended
- **MATLAB:** R2020b or later (tested with R2023b)
- **Toolboxes:** Image Processing Toolbox (required)

### For Standalone Version
- **OS:** Windows 10/11
- **RAM:** 8 GB minimum, 16 GB recommended
- **Runtime:** MATLAB Runtime R2022b (included in installer, ~2-3 GB)

## Installation

### Option 1: Standalone Version

1. Download the installer from [Releases](https://github.com/ArFelker/SpotAnalyzer/releases)
2. Run the installer (installs MATLAB Runtime automatically if needed)


### Option 2: MATLAB Source Code

1. Clone repository:
   ```bash
   git clone https://github.com/ArFelker/SpotAnalyzer.git
   ```

2. Add to MATLAB path and launch:
   ```matlab
   addpath('path/to/SpotAnalyzer')
   SpotAnalyzer
   ```


## Quick Start

### Main GUI Workflow

```matlab
SpotAnalyzer
```

**7-Step Process:**
1. **Load Images** - Select bait/prey TIFF files, set pixel size and offset
2. **Define ROI** - Draw polygon around analysis region
3. **Detect Dots** - Adjust LoG parameters (σ, threshold) for spot detection
4. **Define Ring** - Set gap distance for background calculation
5. **Analyze** - Automated pipeline: background → bait → prey quantification
6. **Visualize** - View histograms, ECDF, bait-prey correlations
7. **Export** - Save to Excel with all metrics

### Pooled Analysis

Combine multiple experiments:

```matlab
SpotAnalyzer('pooled')
```

Options:
- Merge all Excel files from multiple folders
- Group files by filename across folders

## Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| Pixel Size | nm per pixel | 130 |
| Offset | Camera offset (ADU) | 400 |
| Sigma (σ) | LoG filter size (px) | 1.75 |
| Threshold | Detection threshold (σ units) | 1.0 |
| Gap | Buffer zone width (px) | 1.25 |
| Background | Ring width for I_bg (px) | 1.0 (fixed) |

## Quantification Metrics

### Basic Contrast (K)
```
K = (I_dot - offset) / (I_bg - offset)
```

### Bait-Specific Contrast
```
C_bait_norm = (I_bait_in - I_bait_out) / (I_bait_in - I_bg)
C_prey_spec = C_prey / C_bait_norm
```

Where:
- `I_bait_in` = bait intensity inside dot
- `I_bait_out` = bait intensity outside dot (ROI-averaged)
- `I_bg` = background intensity (ring mask)
- `C_prey` = prey K-value
- `C_bait_norm` = normalized bait specificity
- `C_prey_spec` = prey-specific contrast

### Recruitment Ratio
```
RR_K = K_prey / K_bait
RR_I = I_prey / I_bait
```

## Output Structure

Excel file (`SpotAnalyzer_Results.xlsx`) contains:

| Sheet | Content |
|-------|---------|
| Summary | Whole-image statistics |
| Bait | Per-dot bait quantifications |
| Prey1, Prey2, ... | Per-dot prey quantifications |
| Bait_Specific_Contrast | C_bait_norm and C_prey_spec per dot |
| Bait_Prey_Stats | Recruitment ratios and correlations |
| Bait_Prey_DotResults | Per-dot recruitment metrics |

**Column Definitions:**
- `I_dot` - mean intensity inside dot
- `I_bg` - mean background intensity (ring)
- `K` - contrast ratio
- `SNR` - signal-to-noise ratio
- `driftX/Y` - drift correction applied (px)
- `RR_K` - recruitment ratio (K-based)

## Troubleshooting

**No spots detected?**
- Increase σ (larger spots) or decrease threshold
- Check image contrast

**Invalid ring masks?**
- Spots too close to ROI boundary
- Increase gap parameter

**Drift correction fails?**
- Use manual drift input
- Verify sufficient image overlap


### Related Publication

This software was developed for the following study:

> Felker, A. et al. (2025). Ultrastructural organization and dynamics of TIRAP filaments. (in preparation)


## License

This project is licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0) - see the [LICENSE](LICENSE) file for details.

## Author

**Arthur Felker**  
Center for Cellular Nanoanalytics  
Division of Biophysics  
Osnabrück University  
Barbarastraße 11, 49076 Osnabrück, Germany  
arfelker@uni-osnabrueck.de

## Acknowledgments

Developed for research in protein recruitment analysis using TIRF microscopy at the Center for Cellular Nanoanalytics, Osnabrück University.
