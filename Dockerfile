FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime
ENV MKL_THREADING_LAYER=GNU
ENV nnUNet_results="/workspace/nnUNet_results"
WORKDIR /workspace
COPY nnUNet_results /workspace/nnUNet_results
COPY predict.sh /workspace/predict.sh
COPY run_inference.py /workspace/run_inference.py
COPY nnUNetTrainer_Tversky.py /workspace/
RUN pip install nnunetv2==2.2 && \
    pip install torch==2.5.1 --index-url https://download.pytorch.org/whl/cu121 && \
    pip install SimpleITK && \
    pip install --force-reinstall numpy==2.0.2 && \
    cp /workspace/nnUNetTrainer_Tversky.py \
       /opt/conda/lib/python3.10/site-packages/nnunetv2/training/nnUNetTrainer/ && \
    sed -i "s/\[i\.pin_memory() for i in item\.values() if isinstance(i, torch\.Tensor)\]/[i.pin_memory() for i in item.values() if isinstance(i, torch.Tensor)] if torch.cuda.is_available() else None/" \
        /opt/conda/lib/python3.10/site-packages/nnunetv2/inference/data_iterators.py && \
    mkdir -p /workspace/inputs /workspace/outputs

