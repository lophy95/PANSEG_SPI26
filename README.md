# Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation

🏆 **Outstanding Winner Award — FLARE 2026 Challenge (MICCAI 2026), Task 1**

Whole-body pan-cancer lesion segmentation in CT. The model is a compact 4-stage nnU-Net v2 (PlainConvUNet) trained at 3.0 × 2.0 × 2.0 mm spacing with Dice + CE + 0.3 × Tversky loss. It runs at roughly **3–4 s per case** using about **1.4 GB of GPU memory**.

🔗 Challenge: https://www.codabench.org/competitions/7149/

---

## 1. Install Docker

Install Docker for your system by following the official guide: https://docs.docker.com/get-docker/

Check that it works:

```bash
docker --version
```

## 2. Load the Docker image

```bash
docker load -i panseg_spi26.tar.gz
```

## 4. Prepare your data

Put the CT scans (`.nii.gz`) in an `inputs/` folder and create an empty `outputs/` folder:

```text
inputs/
  case_0001_0000.nii.gz
  case_0002_0000.nii.gz
  ...
outputs/
```

## 5. Run inference

```bash
docker container run --gpus "device=0" -m 28G --name <team_name> --rm \
  -v $PWD/inputs/:/workspace/inputs/ \
  -v $PWD/outputs/:/workspace/outputs/ \
  <team_name>:latest /bin/bash -c "sh predict.sh"
```

Segmentation masks are written to `outputs/` with the same file names as the inputs:

- `0` — background
- `1` — lesion

---

## Citation

```bibtex
@inproceedings{nayak2026coarse,
  title     = {Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation},
  author    = {Nayak, L. and Ebrahimpour, S. L. and Jiang, J.},
  booktitle = {FLARE 2026 Challenge at MICCAI 2026},
  year      = {2026}
}
```

## Acknowledgements

We thank the FLARE 2026 organizers for the dataset and evaluation platform.

For questions, please open an issue in this repository.
