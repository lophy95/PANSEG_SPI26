# 🏆 Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation

**Outstanding Winner Award — FLARE 2026 Challenge at MICCAI 2026**

This repository contains our submission to **MICCAI FLARE 2026 Task 1: whole-body pan-cancer segmentation in CT images**.

Our team received the **Outstanding Winner Award** in the FLARE 2026 Challenge.

🔗 **Challenge:** https://www.codabench.org/competitions/7149/

Our method is designed around the key requirement of the challenge: achieving strong segmentation performance while remaining **fast, reliable, and computationally efficient** on large 3D CT volumes.

The final model uses a compact **4-stage PlainConvUNet** with coarse image spacing, a reduced patch depth, and an additional **Tversky loss** term to place greater emphasis on false-positive control. The model was trained entirely from scratch using the FLARE 2026 training data, without external pretrained weights. 

---

## Method

Our implementation is based on **nnU-Net v2** and follows the general configuration used by the previous FLARE Task 1 winning solution.

The final network is a **PlainConvUNet with four encoder stages**:

```text
32 → 64 → 128 → 256 feature channels
```

with two convolutions per stage and the following pooling kernels:

```text
[1, 1, 1]
[2, 2, 2]
[2, 2, 2]
[2, 2, 2]
```

The complete training configuration is:

| Setting | Value |
|---|---|
| Network | PlainConvUNet |
| Encoder stages | 4 |
| Feature channels | 32 / 64 / 128 / 256 |
| Target spacing | 3.0 × 2.0 × 2.0 mm |
| Patch size | 64 × 128 × 128 |
| Batch size | 2 |
| Epochs | 2000 |
| Optimizer | SGD |
| Initial learning rate | 1e-3 |
| Loss | Dice + CE + 0.3 × Tversky |
| Training GPU | NVIDIA L40S |

---

## Coarse spatial resolution

The final model uses a target spacing of:

```text
3.0 × 2.0 × 2.0 mm
```

At this spacing, a `64 × 128 × 128` patch covers approximately:

```text
192 × 256 × 256 mm
```

of physical space.

This provides a relatively large anatomical field of view while keeping the number of processed voxels manageable.

We also evaluated the finer spacing automatically selected by the nnU-Net experiment planner:

```text
2.0 × 0.75 × 0.75 mm
```

The finer spacing performed worse and was substantially more expensive computationally. Mean DSC decreased from **0.477 to 0.432**, GPU memory increased from **1403 MiB to 3671 MiB**, and inference time increased from **4.1 s to 33 s per case**. Training time increased from approximately **10 h to 21 h**. 

### Spacing ablation

| Spacing | Patch size | DSC | GPU memory | Time / case | Training time |
|---|---:|---:|---:|---:|---:|
| **3.0 × 2.0 × 2.0 mm** | **64 × 128 × 128** | **0.477** | **1403 MiB** | **4.1 s** | **10 h** |
| 2.0 × 0.75 × 0.75 mm | 56 × 192 × 192 | 0.432 | 3671 MiB | 33 s | 21 h |

---

## Tversky loss

The default nnU-Net objective combines Dice and cross-entropy loss.

For our final model, we add a Tversky term:

```text
L = L_Dice + L_CE + 0.3 × L_Tversky
```

with:

```text
alpha = 0.7
beta  = 0.3
```

Using the convention:

```text
                    TP
TI = --------------------------------
     TP + α × FP + β × FN
```

the larger value of `alpha` places greater emphasis on **false-positive predictions**.

This is particularly important because the validation set contains lesion-free scans, where any predicted foreground is penalized. 

---

## Training data

The FLARE 2026 training set contains:

```text
17,575 labelled CT volumes
```

The task uses binary segmentation labels:

```text
0 — Background
1 — Lesion
```

Only the primary lesion is annotated in each case; other visible disease, including metastases, may be present without corresponding labels. 

---

## Training

The final model was trained from scratch using only the FLARE 2026 data.

```text
Optimizer             : SGD
Initial learning rate : 1e-3
Batch size            : 2
Epochs                 : 2000
```

No external pretrained weights were used. 

Training the final coarse-spacing configuration required approximately:

```text
10 hours
```

on a single:

```text
NVIDIA L40S
```

---

## Public validation results

All models were evaluated on the same **50-case public validation set** using a single **NVIDIA L40S GPU**, with test-time augmentation disabled. 

| Model | DSC | Zero-DSC cases | Cases with DSC > 0.5 | GPU memory | Time / case |
|---|---:|---:|---:|---:|---:|
| **Dice + CE + Tversky** | **0.492 ± 0.337** | **6** | **29** | **1403 MiB** | **4.1 s** |
| Dice + CE | 0.477 ± 0.333 | 6 | 26 | 1403 MiB | 4.1 s |
| FLARE25 baseline container | 0.467 ± 0.372 | – | – | 1779 MiB | 2.6 s |

Adding the Tversky term increased the mean DSC from:

```text
0.477 → 0.492
```

and increased the number of cases with DSC above 0.5 from:

```text
26 → 29
```

---

## Loss ablation

Keeping the network architecture, data, spacing, and patch size fixed, we compared several loss configurations.

| Loss | Epochs | DSC | Zero-DSC cases | DSC > 0.5 |
|---|---:|---:|---:|---:|
| Dice + CE | 2000 | 0.477 | 6 | 26 |
| **Dice + CE + Tversky** | **2000** | **0.492** | **6** | **29** |
| Tversky fine-tuning | 250 | 0.482 | 7 | 27 |
| Boundary-loss fine-tuning | 250 | 0.473 | 8 | 26 |

The fully trained Tversky model achieved the best mean DSC.

Compared with Dice + CE alone:

- **29 cases improved**
- **15 cases decreased**
- **6 cases were unchanged**

The mean improvement was:

```text
+0.015 DSC
```

A paired Wilcoxon signed-rank test gave:

```text
p = 0.158
```

so the observed improvement was not statistically significant on the 50-case public validation set. :chatgpt-content-reference{index="13"}

---

## Boundary-loss experiment

We also evaluated boundary-loss fine-tuning.

In our implementation, the boundary loss required a CPU distance transform for each training batch and substantially increased computational cost.

Training time increased from approximately:

```text
17.4 s / epoch
```

to:

```text
~130 s / epoch
```

We therefore evaluated it through a 250-epoch fine-tuning experiment at a learning rate of `1e-4`.

The resulting DSC was:

```text
0.473
```

which did not improve over the Dice + CE baseline. :chatgpt-content-reference{index="14"}

---

## Inference efficiency

Efficiency is a key part of the FLARE evaluation.

On the **100 hidden validation cases**, our final submission achieved an average inference time of approximately:

```text
2.8 seconds per case
```

:chatgpt-content-reference{index="15"}

The final configuration therefore balances:

```text
segmentation accuracy
        +
large anatomical context
        +
low GPU memory
        +
fast inference
```

rather than maximizing network depth or spatial resolution.

---

## Why not use a deeper U-Net?

A deeper network can potentially provide greater representational capacity and a larger receptive field.

However, additional encoder and decoder stages also increase:

- GPU memory usage
- computational cost
- inference latency
- training time

For this challenge, these factors matter because the evaluation includes computational efficiency in addition to segmentation accuracy.

Our final model therefore uses a compact **4-stage architecture** together with coarse spatial resolution to provide a large physical field of view without the cost of a substantially deeper network.

---

## Final configuration

```yaml
architecture:
  network: PlainConvUNet
  encoder_stages: 4
  features:
    - 32
    - 64
    - 128
    - 256

preprocessing:
  spacing:
    - 3.0
    - 2.0
    - 2.0

training:
  patch_size:
    - 64
    - 128
    - 128
  batch_size: 2
  epochs: 2000
  optimizer: SGD
  initial_learning_rate: 0.001

loss:
  dice: true
  cross_entropy: true
  tversky:
    weight: 0.3
    alpha_fp: 0.7
    beta_fn: 0.3
```

---

## Main takeaway

Our experiments indicate that a relatively simple configuration can provide a strong accuracy-efficiency trade-off for whole-body pan-cancer segmentation:

```text
4-stage PlainConvUNet
        +
32 / 64 / 128 / 256 channels
        +
64 × 128 × 128 patches
        +
3 × 2 × 2 mm spacing
        +
Dice + CE + 0.3 × Tversky
```

The coarse spacing was both **more accurate and substantially more efficient** than the finer nnU-Net-planned spacing in our experiments, while the Tversky term provided a modest numerical improvement by placing greater emphasis on false-positive control. 

---

## Award

### 🏆 Outstanding Winner Award

**FLARE 2026 Challenge — MICCAI 2026**

**Team**

- L. Nayak
- S. L. Ebrahimpour
- J. Jiang
---

## Citation

If you use this repository or build on this work, please cite:

```bibtex
@inproceedings{nayak2026coarse,
  title     = {Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation},
  author    = {Nayak, L. and Ebrahimpour, S. L. and Jiang, J.},
  booktitle = {FLARE 2026 Challenge at MICCAI 2026},
  year      = {2026}
}
```

Please update this entry with the official proceedings information and DOI once the final publication record is available.


## Acknowledgements

We thank the **FLARE 2026 organizers** for providing the dataset and evaluation platform.

---

## Contact

For questions regarding the implementation or experiments, please open an issue in this repository.

---

<p align="center">
  <b>🏆 Outstanding Winner — FLARE 2026 Challenge at MICCAI 2026</b>
</p>
