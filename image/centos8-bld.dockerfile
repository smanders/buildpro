FROM centos:8
LABEL maintainer="smanders"
LABEL org.opencontainers.image.source https://github.com/smanders/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
VOLUME /bpvol
# dnf repositories
# NOTE: multiple layers to reduce layer sizes
RUN dnf -y update \
  && dnf clean all \
  && dnf -y install --setopt=tsflags=nodocs \
     ghostscript `#LaTeX` \
     git \
     graphviz \
     gtk2-devel.x86_64 \
     iproute \
     libSM-devel.x86_64 \
     mesa-libGL-devel.x86_64 \
     mesa-libGLU-devel.x86_64 \
     redhat-lsb-core \
     rpm-build \
     sudo \
     unixODBC-devel \
     vim \
     wget \
     https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
  && dnf clean all
# git-lfs
RUN export LFS_VER=2.12.1 \
  && mkdir /usr/local/src/lfs \
  && wget -qO- "https://github.com/git-lfs/git-lfs/releases/download/v${LFS_VER}/git-lfs-linux-amd64-v${LFS_VER}.tar.gz" \
  | tar -xz -C /usr/local/src/lfs \
  && /usr/local/src/lfs/install.sh \
  && rm -rf /usr/local/src/lfs/ \
  && unset LFS_VER
# doxygen
RUN export DXY_VER=1.8.13 \
  && wget -qO- --no-check-certificate \
  "https://downloads.sourceforge.net/project/doxygen/rel-${DXY_VER}/doxygen-${DXY_VER}.linux.bin.tar.gz" \
  | tar -xz -C /usr/local/ \
  && mv /usr/local/doxygen-${DXY_VER}/bin/doxygen /usr/local/bin/ \
  && rm -rf /usr/local/doxygen-${DXY_VER}/ \
  && unset DXY_VER
# LaTeX
# NOTE: multiple layers, small subset of collection-latexextra to reduce layer sizes
COPY texlive.profile /usr/local/src/
RUN export TEX_VER=2017 \
  && wget -qO- "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${TEX_VER}/tlnet-final/install-tl-unx.tar.gz" \
  | tar -xz -C /usr/local/src/ \
  && /usr/local/src/install-tl-20180303/install-tl -profile /usr/local/src/texlive.profile \
     -repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${TEX_VER}/tlnet-final/archive/ \
  && rm -rf /usr/local/src/install-tl-20180303 /usr/local/src/texlive.profile \
  && unset TEX_VER
RUN  tlmgr install collection-fontsrecommended \
  && tlmgr install collection-latexrecommended \
  && tlmgr install tabu varwidth multirow wrapfig adjustbox collectbox sectsty tocloft `#collection-latexextra` \
  && tlmgr install epstopdf
ENV PATH=$PATH:/usr/local/texlive/2017/bin/x86_64-linux
# CUDA https://developer.nvidia.com/cuda-10.1-download-archive-update1
# NOTE: only subset of cuda-libraries-dev to reduce layer sizes
RUN export CUDA_VER=10.1.168-1 \
  && export CUDA_RPM=cuda-repo-rhel6-${CUDA_VER}.x86_64.rpm \
  && wget -q "https://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64/${CUDA_RPM}" \
  && rpm --install ${CUDA_RPM} \
  && dnf clean all \
  && dnf -y install \
     cuda-compiler-10-1 \
  `# cuda-libraries-dev-10-1` \
     cuda-cudart-dev-10-1 \
     cuda-cusolver-dev-10-1 \
     libcublas-devel-10-2 \
  && ln -s cuda-10.1 /usr/local/cuda \
  && dnf clean all \
  && rm ${CUDA_RPM} \
  `# libcublas installed to 10.2, move to 10.1` \
  && mv /usr/local/cuda-10.2/targets/x86_64-linux/include/* /usr/local/cuda-10.1/targets/x86_64-linux/include/ \
  && mv /usr/local/cuda-10.2/targets/x86_64-linux/lib/stubs/* /usr/local/cuda-10.1/targets/x86_64-linux/lib/stubs/ \
  && rmdir /usr/local/cuda-10.2/targets/x86_64-linux/lib/stubs/ \
  && mv /usr/local/cuda-10.2/targets/x86_64-linux/lib/* /usr/local/cuda-10.1/targets/x86_64-linux/lib/ \
  && rm -rf /usr/local/cuda-10.2 \
  && unset CUDA_VER && unset CUDA_RPM
# cmake
RUN export CMK_VER=3.17.5 \
  && export CMK_DL=releases/download/v${CMK_VER}/cmake-${CMK_VER}-Linux-x86_64.tar.gz \
  && wget -qO- "https://github.com/Kitware/CMake/${CMK_DL}" \
  | tar --strip-components=1 -xz -C /usr/local/ \
  && unset CMK_DL && unset CMK_VER
# copy from local into image
COPY scripts/ /usr/local/bpbin
COPY git-prompt.sh /etc/profile.d/
# environment: gcc version
ENV GCC_VER=gcc731
# externpro
RUN export XP_VER=20.10.1 \
  && mkdir /opt/extern \
  && export XP_DL=releases/download/${XP_VER}/externpro-${XP_VER}-${GCC_VER}-64-Linux.tar.xz \
  && wget -qO- "https://github.com/smanders/externpro/${XP_DL}" \
   | tar -xJ -C /opt/extern/ \
  && unset XP_DL && unset XP_VER
ENTRYPOINT ["/bin/bash", "/usr/local/bpbin/entry.sh"]
