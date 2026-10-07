# Coarse-Spacing nnU-Net with Tversky Loss for Pan-Cancer CT Segmentation

🏆 **Outstanding Winner Award — FLARE 2026 Challenge (MICCAI 2026), Task 1**

Whole-body pan-cancer lesion segmentation in CT. The model is a compact 4-stage nnU-Net v2 (PlainConvUNet) trained at 3.0 × 2.0 × 2.0 mm spacing with Dice + CE + 0.3 × Tversky loss. It runs at roughly **3–4 s per case** using about **1.4 GB of GPU memory**.

🔗 Challenge: https://www.codabench.org/competitions/7149/

---

## Requirements

- Linux with an NVIDIA GPU (tested on NVIDIA L40S)
- NVIDIA driver installed (`nvidia-smi` should work)
- Docker
- NVIDIA Container Toolkit (lets Docker use the GPU)

---

## 1. Install Docker

On Ubuntu:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out and back in afterwards
```

For other systems, see https://docs.docker.com/engine/install/

## 2. Install the NVIDIA Container Toolkit

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Check that Docker can see the GPU:

```bash
docker run --rm --gpus all ubuntu nvidia-smi
```

Full instructions: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

---

## 3. Load the Docker image

```bash
docker load -i <team_name>.tar.gz
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
