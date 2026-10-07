# 🏆 Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation

**Outstanding Winner Award — FLARE 2026 Challenge at MICCAI 2026**

This repository contains our submission to **MICCAI FLARE 2026 Task 1**, which focuses on **whole-body pan-cancer segmentation in CT images**.

Our team received the **Outstanding Winner Award** in the FLARE 2026 Challenge.

**Challenge:** https://www.codabench.org/competitions/7149/

The challenge is particularly demanding because the goal is not only to achieve high segmentation accuracy, but also to build a **fast, reliable, and computationally efficient** model that can process large 3D CT volumes.

Our final solution uses a compact **4-stage PlainConvUNet** with coarse image spacing, a reduced patch depth, and a Tversky loss term to better control false-positive lesion predictions.

The model was trained **from scratch using only the FLARE 2026 training data**. No external pretrained weights were used.

---

## Method

Our framework is based on **nnU-Net** and follows the general setup used by the FLARE24 Task 1 winning solution.

The final model uses:

- **4-stage PlainConvUNet**
- Feature channels: **32 / 64 / 128 / 256**
- Target spacing: **3.0 × 2.0 × 2.0 mm**
- Patch size: **64 × 128 × 128**
- Batch size: **2**
- Training for **2000 epochs**
- Initial learning rate: **1e-3**
- Optimizer: **SGD**
- Loss: **Dice + Cross-Entropy + 0.3 × Tversky**

---

## Network architecture

We use a compact **4-stage PlainConvUNet** with encoder feature widths:

```text
32 → 64 → 128 → 256
