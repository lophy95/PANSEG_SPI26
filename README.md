# Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation

Submission to **MICCAI FLARE 2026, Task 1 (whole-body pan-cancer segmentation in CT)**.

We start from the nnU-Net configuration of the FLARE24 Task 1 winning solution ([Huang et al.](https://github.com/Ziyan-Huang/FLARE24)) and make two changes:

1. **Patch depth reduced from 96 to 64.** FLARE26 scans are much shorter than FLARE24 scans (median 149 slices, as few as 62 after resampling to 3 mm). With rotation augmentation, the original 96-slice patch inflates to ~173 voxels of sampling depth, which exceeds most training volumes and prevented training.
2. **An added Tversky loss term (α = 0.7, β = 0.3)** that penalizes false positives more than false negatives, because lesion-free validation scans score zero if any foreground is predicted.

The model is trained from scratch on FLARE 2026 data only. No external pretrained weights are used.

---

## Results (50-case public validation set)

All numbers on a single NVIDIA L40S, test-time augmentation disabled.

| Model | DSC | Zero-Dice cases | Cases > 0.5 | GPU memory | Time / case |
|---|---|---|---|---|---|
| **Dice + CE + Tversky (submitted)** | **0.492 ± 0.337** | 6 | 29 | 1403 MiB | 4.1 s |
| Dice + CE (our baseline) | 0.477 ± 0.333 | 6 | 26 | 1403 MiB | 4.1 s |
| FLARE25 baseline container | 0.467 ± 0.372 | – | – | 1779 MiB | 2.6 s |

The Tversky term improved 29 cases, degraded 15 and left 6 unchanged (paired Wilcoxon p = 0.158, not significant). On the 100 hidden validation cases, inference averaged **2.8 s per case**.

Ablations (see the paper for details):

| Variant | DSC | Notes |
|---|---|---|
| Spacing 2.0 × 0.75 × 0.75 mm (nnU-Net planner default) | 0.432 | 3671 MiB, 33 s/case, ~2× training time |
| + Tversky, 250-epoch fine-tune | 0.482 | from converged Dice+CE checkpoint, lr 1e-4 |
| + Boundary loss, 250-epoch fine-tune | 0.473 | ~130 s/epoch vs 17.4 s/epoch |

---

## Repository contents

| File | Purpose |
|---|---|
| `nnUNetTrainer_Tversky.py` | Custom trainer: Dice + CE + 0.3 · Tversky(α=0.7, β=0.3), 2000 epochs, lr 1e-3. Also contains `nnUNetTrainer_TverskyFN` (α=0.3, β=0.7), which was **not** used for the submission. |
| `run_inference.py` | I/O adapter for the evaluation harness: converts input `.npz` → `.nii.gz`, runs `nnUNetv2_predict`, converts output back to `.npz`. Also accepts `.nii.gz` input directly. |
| `predict.sh` | Container entry point; sets `nnUNet_results` and calls `run_inference.py`. |
| `Dockerfile` | Builds the inference container. |


---

## Environment

- Python 3.10
- nnU-Net v2.2 (`nnunetv2==2.2`)
- PyTorch 2.5.1 (CUDA 12.1)
- SimpleITK, NumPy 2.0.2

```bash
pip install nnunetv2==2.2
pip install torch==2.5.1 --index-url https://download.pytorch.org/whl/cu121
pip install SimpleITK numpy==2.0.2
```

Install the custom trainer by copying it into the nnU-Net trainer directory:

```bash
cp nnUNetTrainer_Tversky.py \
   $(python -c "import nnunetv2, os; print(os.path.dirname(nnunetv2.__file__))")/training/nnUNetTrainer/
```

---

## Data

- 17,575 labelled CT volumes from the FLARE 2026 training release (~495 GB).
- 13 cases fail to load in SimpleITK/ITK with a non-orthonormal direction-cosine error and were excluded, leaving **17,562** training cases.
- Labels are binary (lesion / background). Only the primary lesion per case is annotated; other visible disease may be unlabelled.

Convert the data to nnU-Net format as `Dataset701_<name>` with a single CT channel (`_0000`) and set the usual environment variables:

```bash
export nnUNet_raw=/path/to/nnUNet_raw
export nnUNet_preprocessed=/path/to/nnUNet_preprocessed
export nnUNet_results=/path/to/nnUNet_results
```

---

## Training

### 1. Plan and add the `3d_fullres_2mm` configuration

```bash
nnUNetv2_plan_and_preprocess -d 701 --verify_dataset_integrity
```

Then add a `3d_fullres_2mm` configuration to `nnUNet_preprocessed/Dataset701_*/nnUNetPlans.json` with the settings below (inherited from the FLARE24 configuration, with patch depth reduced to 64):

| Setting | Value |
|---|---|
| Network | PlainConvUNet, 4 encoder stages |
| Features per stage | 32 / 64 / 128 / 256 |
| Convolutions per stage | 2 |
| Pooling kernels (strides) | [1,1,1], [2,2,2], [2,2,2], [2,2,2] |
| Target spacing (z × y × x) | 3.0 × 2.0 × 2.0 mm |
| Patch size (z × y × x) | **64** × 128 × 128 |
| Batch size | 2 |

Preprocess that configuration:

```bash
nnUNetv2_preprocess -d 701 -c 3d_fullres_2mm
```

### 2. Train

```bash
nnUNetv2_train 701 3d_fullres_2mm all -tr nnUNetTrainer_Tversky
```

Training runs 2000 epochs at an initial learning rate of 1e-3 (~10 h for the Dice+CE baseline on one L40S; ~17.4 s/epoch).

To reproduce the Dice+CE baseline, use the stock trainer with the same epoch count and learning rate.

---

## Inference

### Without Docker

```bash
export nnUNet_results=/path/to/nnUNet_results
nnUNetv2_predict -d 701 -c 3d_fullres_2mm -f all \
    -tr nnUNetTrainer_Tversky --disable_tta \
    -i /path/to/images -o /path/to/predictions
```

Input images must follow nnU-Net naming (`<case_id>_0000.nii.gz`).

### With Docker

Build the image (the `nnUNet_results/` folder with the trained model must sit next to the `Dockerfile`):

```bash
docker build -t flare26_msk .
```

Run it:

```bash
docker container run --gpus "device=0" --rm \
    -v $PWD/inputs/:/workspace/inputs/ \
    -v $PWD/outputs/:/workspace/outputs/ \
    flare26_msk:latest /bin/bash -c "sh predict.sh"
```

Save for submission:

```bash
docker save flare26_msk:latest | gzip -c > flare26_msk.tar.gz
```

### Input / output format

`run_inference.py` detects the input format automatically. The input folder must contain **either** `.npz` **or** `.nii.gz` files, not both.

| Input | Output |
|---|---|
| `<case>.npz` with image key `imgs` (also accepts `image`, `img`, `data`) and optional `spacing` in (z, y, x) | `<case>.npz` with key `segs` (uint8), same shape as `imgs` |
| `<case>_0000.nii.gz` | `<case>.nii.gz` |

If an `.npz` file has no `spacing` key, the script falls back to 1.0 × 1.0 × 1.0 mm, which will degrade results because the model expects correctly scaled resampling to 3 × 2 × 2 mm.

### Docker notes

- The Dockerfile patches `nnunetv2/inference/data_iterators.py` so that `pin_memory()` is only called when CUDA is available, allowing the container to start on CPU-only machines.
- `MKL_THREADING_LAYER=GNU` is set to avoid an MKL/libgomp conflict at startup.

---

## Known limitations

- The Tversky gain over Dice+CE is not statistically significant at n = 50 (p = 0.158).
- Six validation cases score exactly 0 DSC. In most, the model predicts a substantial volume that does not overlap the annotated lesion. Because only the primary lesion is labelled, some of these may be real but unannotated disease; this cannot be resolved by the model alone.

---

## Citation

```bibtex
@inproceedings{nayak2026flare,
  title     = {Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation},
  author    = {Nayak, L. and Ebrahimpour, S. L. and Jiang, J.},
  booktitle = {MICCAI FLARE 2026 Challenge},
  year      = {2026}
}
```

## Acknowledgements

We thank the FLARE 2026 organizers for the data and the evaluation platform, and the authors of [nnU-Net](https://github.com/MIC-DKFZ/nnUNet) and the [FLARE24 Task 1 winning solution](https://github.com/Ziyan-Huang/FLARE24), on which this work builds.
