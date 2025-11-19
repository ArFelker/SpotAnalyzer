# SpotAnalyzer User Guide

Quick reference for the 7-step workflow.

## Installation

### Option 1: Standalone (No MATLAB Required)
1. Download installer from GitHub Releases
2. Run installer (includes MATLAB Runtime)
3. Launch from Start Menu

### Option 2: MATLAB Source
1. Clone repository and add to MATLAB path:
   ```matlab
   addpath('path/to/SpotAnalyzer')
   SpotAnalyzer
   ```

2. Requirements: MATLAB R2020b+ (tested with R2023b), Image Processing Toolbox

## Workflow

### 1. Load Images
- Select bait TIFF file
- Set pixel size (nm/px) and offset (camera ADU)
- Add prey channels (0-5)
- Use "Align Channels" for drift correction

### 2. Define ROI
- Draw polygon around analysis region
- Double-click to finish
- Adjust contrast method if needed

### 3. Detect Dots
- Adjust Sigma 
- Set Threshold 
- Tune filter parameters 
- Use zoom to inspect detection quality

### 4. Define Ring
- Set Gap distance 
- Background width fixed at 1 px
- Blue = buffer, Green = background region

### 5. Analyze
- Automated pipeline runs:
  1. Background calculation
  2. Bait quantification
  3. Prey analysis (with drift correction)
- Wait for completion message

### 6. Visualize
- **Histograms**: K-value and intensity distributions
- **ECDF**: Cumulative distribution functions
- **Bait-Prey**: Scatter plots and correlations
- **Statistics**: Summary table

### 7. Export
- Select output directory
- Creates timestamped folder with:
  - Excel file (all metrics)
  - MATLAB .mat file (complete data)
  - Parameters .txt file

## Key Parameters

| Parameter | Typical Range | Effect |
|-----------|---------------|--------|
| Sigma | 1.5 - 2.5 px | Spot size detection |
| Threshold | 0.8 - 1.5 | Higher = fewer spots |
| Gap | 1.0 - 2.5 px | Background buffer |

## Output Files

**Excel (`SpotAnalyzer_Results.xlsx`):**
- Summary: Whole-image statistics
- Bait: Per-dot bait metrics
- Prey1, Prey2, ...: Per-dot prey metrics
- Bait_Specific_Contrast: C_bait_norm, C_prey_spec
- Bait_Prey_Stats: Recruitment ratios
- Bait_Prey_DotResults: Per-dot recruitment

**Key Columns:**
- `I_dot` - intensity in spot
- `I_bg` - background intensity
- `K` - contrast ratio
- `RR_K` - recruitment ratio (K-based)
- `C_bait_norm` - bait-normalized contrast
- `C_prey_spec` - prey-specific contrast

## Formulas

```
K = (I_dot - offset) / (I_bg - offset)
C_bait_norm = (I_bait_in - I_bait_out) / (I_bait_in - I_bg)
C_prey_spec = C_prey / C_bait_norm
RR_K = K_prey / K_bait
```

## Troubleshooting

**No spots detected:**
- Decrease threshold or increase sigma
- Check image contrast (adjust in Step 2)

**Too many false positives:**
- Increase threshold
- Adjust roundness filters
- Increase Min Area

**Ring masks invalid:**
- Spots too close to ROI edge
- Increase gap parameter
- Redraw ROI with more margin

**Drift correction fails:**
- Use manual drift input in Step 1
- Check image alignment quality
- Verify sufficient overlap between channels

## Pooled Analysis

Batch process multiple experiments:

```matlab
SpotAnalyzer('pooled')
```

**Options:**
- Merge All Excel Files: Combine sheets across folders
- Group by Filename: Organize by file patterns

## Tips

1. **Image Quality**: Use flat-field corrected images
2. **ROI Selection**: Keep margins from image edges
3. **Parameter Tuning**: Start with defaults, adjust incrementally
4. **Validation**: Check detection visually before exporting
5. **Drift Correction**: Run alignment in Step 1 before analysis

## Contact

Issues or questions: arfelker@uni-osnabrueck.de
