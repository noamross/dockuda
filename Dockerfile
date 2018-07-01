FROM rocker/geospatial:latest
LABEL maintainer "Noam Ross <noam.ross@gmail.com>"

# install from nvidia repositories
RUN apt-get update && apt-get install --no-install-recommends -y \
    gnupg2 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN wget -nv -P /root/manual http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1704/x86_64/7fa2af80.pub \
 && echo "47217c49dcb9e47a8728b354450f694c9898cd4a126173044a69b1e9ac0fba96  /root/manual/7fa2af80.pub" | sha256sum -c --strict - \
 && apt-key add /root/manual/7fa2af80.pub \
 && wget -nv -P /root/manual http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1704/x86_64/cuda-repo-ubuntu1704_9.1.85-1_amd64.deb \
 && dpkg -i /root/manual/cuda-repo-ubuntu1704_9.1.85-1_amd64.deb \
 && echo 'deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /' > /etc/apt/sources.list.d/nvidia-ml.list \
 && rm -rf /root/manual
 
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
    # install cuda toolkit
    # cuda-toolkit-9-0 \
    libncurses5-dev htop cmake \
    cuda-toolkit-9-0 \
    # install cudnn
    libcudnn7=7.0.5.15-1+cuda9.0 \
    libcudnn7-dev=7.0.5.15-1+cuda9.0 \
    #libcudnn7=7.0.5.15-1+cuda9.1 \
    #libcudnn7-dev=7.0.5.15-1+cuda9.1 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# fix issues with shared objects
RUN ls /usr/local/cuda-9.0/targets/x86_64-linux/lib/stubs/* | xargs -I{} ln -s {} /usr/lib/x86_64-linux-gnu/ \
 && ln -s libcuda.so /usr/lib/x86_64-linux-gnu/libcuda.so.1 \
 && ln -s libnvidia-ml.so /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1

LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="9.0.176"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV CUDA_HOME /usr/local/cuda
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /user/local/nvidia/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH}
RUN echo "rsession-ld-library-path=$LD_LIBRARY_PATH" >> /etc/rstudio/rserver.conf \
 && mkdir -p /usr/lib/R/etc \ 
 && echo 'Sys.setenv(CUDA_HOME="/usr/local/cuda"): Sys.setenv(PATH=paste(Sys.getenv("PATH"), "/usr/local/cuda/bin", sep = ":"))' >> /usr/lib/R/etc/Rprofile.site

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=9.0"


RUN git clone https://github.com/Syllo/nvtop.git \
 && mkdir -p ~/nvtop/build && cd ~/nvtop/build \
 && cmake .. \
 && make \
 && make install \
 && cd ~/ && rm -rf nvtop

RUN apt-get update && apt-get -y install \
     python-virtualenv \
     python-pip && \
     pip install h5py pyyaml requests Pillow scipy tensorflow-gpu keras  && \
     install2.r --error keras 
