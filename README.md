# Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation

This repository contains our submission to **MICCAI FLARE 2026 Task 1**, which focuses on whole-body pan-cancer segmentation in CT scans.

Our method is based on the nnU-Net setup used by the FLARE24 Task 1 winning solution.

We made two main changes:

1. **Reduced the patch depth from 96 to 64**
2. **Added a Tversky loss term** to reduce false-positive predictions

The model was trained **from scratch using only the FLARE 2026 training data**. We did not use external pretrained weights.

---

## What we changed

### Smaller patch depth

FLARE 2026 CT scans are shorter than the scans used in FLARE24.

Because of this, the original patch depth of 96 was too large for many training cases, especially after data augmentation.

We reduced the patch size to:

```text
64 × 128 × 128
```

This made training more stable for the FLARE 2026 data.

### Tversky loss

Our final loss is:

```text
Dice + Cross Entropy + 0.3 × Tversky
```

For the Tversky loss, we used:

```text
alpha = 0.7
beta = 0.3
```

This gives more weight to false-positive predictions.

We used this because false positives can strongly reduce the score, especially in cases with no annotated lesion.

---

## Results

We evaluated the models on the **50-case public validation set**.

All results were measured on one NVIDIA L40S GPU with test-time augmentation disabled.

| Model                      |               DSC | Zero-DSC cases | Cases with DSC > 0.5 | GPU memory | Time / case |
| -------------------------- | ----------------: | -------------: | -------------------: | ---------: | ----------: |
| **Dice + CE + Tversky**    | **0.492 ± 0.337** |              6 |                   29 |   1403 MiB |       4.1 s |
| Dice + CE                  |     0.477 ± 0.333 |              6 |                   26 |   1403 MiB |       4.1 s |
| FLARE25 baseline container |     0.467 ± 0.372 |              – |                    – |   1779 MiB |       2.6 s |

Adding Tversky improved the mean DSC from **0.477 to 0.492**.

Compared with the Dice + CE baseline:

- 29 cases improved
- 15 cases became worse
- 6 cases stayed the same

The paired Wilcoxon test gave **p = 0.158**, so the improvement was not statistically significant on the 50-case validation set.

On the **100 hidden validation cases**, inference took about **2.8 seconds per case** on average.

---

## Ablation results

We also tested a few other settings.

| Variant                                  |   DSC | Notes                            |
| ---------------------------------------- | ----: | -------------------------------- |
| Spacing 2.0 × 0.75 × 0.75 mm             | 0.432 | Slower and used more GPU memory  |
| Tversky fine-tuning for 250 epochs       | 0.482 | Started from the Dice + CE model |
| Boundary loss fine-tuning for 250 epochs | 0.473 | Much slower training             |

The **3 × 2 × 2 mm spacing** gave the best balance between accuracy, speed, and memory use.

---

## Final model setup

| Setting               | Value               |
| --------------------- | ------------------- |
| Network               | PlainConvUNet       |
| Encoder stages        | 4                   |
| Features              | 32 / 64 / 128 / 256 |
| Spacing               | 3.0 × 2.0 × 2.0 mm  |
| Patch size            | 64 × 128 × 128      |
| Batch size            | 2                   |
| Epochs                | 2000                |
| Initial learning rate | 1e-3                |

---

## Training data

The FLARE 2026 training set contains **17,575 labelled CT scans**.

Thirteen scans could not be loaded because of invalid image direction information, so we trained on **17,562 cases**.

The labels are binary:

- background
- lesion

---

## Main takeaway

The main changes were simple:

- use a **smaller patch depth** 
- use a **coarse 3 × 2 × 2 mm spacing**
- add **Tversky loss** to reduce false positives

These changes improved the public validation DSC while keeping inference fast and memory use low.

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

We thank the FLARE 2026 organizers for the dataset and evaluation platform.

This work builds on **nnU-Net** and the **FLARE24 Task 1 winning solution**.
