# Changelog

All notable changes to SpotAnalyzer will be documented in this file.

## [1.0.0] - 2025-11-19

### Initial Release

Complete MATLAB GUI tool for automated nanodot detection and quantification in TIRF microscopy.

#### Features
- **Interactive 7-step workflow**
  - Step 1: Load Images - Multi-channel TIFF import with parameter setup
  - Step 2: Define ROI - Polygon selection for analysis region
  - Step 3: Detect Dots - LoG-based spot detection with live preview
  - Step 4: Define Ring - Gap and background ring configuration
  - Step 5: Analyze - Automated quantification pipeline
  - Step 6: Visualize - Histograms, ECDF, correlation plots
  - Step 7: Export - Excel output with comprehensive metrics

- **Detection & Quantification**
  - Laplacian of Gaussian (LoG) filtering for spot detection
  - Adjustable σ (spot size) and threshold parameters
  - Local background estimation using ring masks
  - Multi-channel support (1 bait + multiple prey channels)

- **Drift Correction**
  - Automatic cross-correlation-based alignment
  - Manual drift input option
  - Live preview of channel overlay

- **Analysis Metrics**
  - Basic contrast (K-value): (I_dot - offset) / (I_bg - offset)
  - Bait-specific contrast normalization
  - Prey-specific contrast calculations
  - Recruitment ratios (K-based and intensity-based)
  - Signal-to-noise ratio (SNR)

- **Batch Processing**
  - Pooled Analysis GUI for combining multiple experiments
  - Merge Excel files from multiple folders
  - Group by filename across folders
  - Aggregate statistics

- **Export & Visualization**
  - Comprehensive Excel output (multiple sheets)
  - Per-dot quantifications for all channels
  - Summary statistics (mean, std, median)
  - Bait-prey correlation analysis
  - Histogram and ECDF plots
  - Scatter plots with linear regression

#### System Requirements
- **MATLAB Source Version**
  - OS: Windows 10/11, macOS 10.15+, Linux
  - RAM: 8 GB minimum, 16 GB recommended
  - MATLAB: R2020b or later (tested with R2023b)
  - Required Toolboxes: Image Processing Toolbox

- **Standalone Version** (Windows)
  - No MATLAB license required
  - MATLAB Runtime R2022b (included in installer)

#### Documentation
- Comprehensive README with quick start guide
- Detailed parameter descriptions
- Troubleshooting section
- File organization reference

#### License
- CC-BY-4.0 (Creative Commons Attribution 4.0 International)
- Ensures proper attribution in academic use
- Supports institutional copyright enforcement
