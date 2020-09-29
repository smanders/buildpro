FROM centos:6
LABEL maintainer="smanders"
LABEL org.opencontainers.image.source https://github.com/smanders/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
# yum repositories
RUN yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     centos-release-scl \
     ghostscript `#LaTeX` \
     graphviz \
     gtk2-devel.x86_64 \
     libSM-devel.x86_64 \
     mesa-libGL-devel.x86_64 \
     mesa-libGLU-devel.x86_64 \
     redhat-lsb-core \
     rpm-build \
     sudo \
     unixODBC-devel \
     vim \
     wget \
     xeyes \
     https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm \
     https://repo.ius.io/ius-release-el6.rpm \
  && curl -s "https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh" | bash \
  && yum -y install --setopt=tsflags=nodocs \
     cppcheck `#epel` \
     devtoolset-7-binutils `#scl` \
     devtoolset-7-gcc `#scl` \
     devtoolset-7-gcc-c++ `#scl` \
     git-lfs `#packagecloud` \
     lcov `#epel` \
     python27 `#scl` \
     https://repo.ius.io/6/x86_64/packages/g/git224-2.24.3-1.el6.ius.x86_64.rpm `#ius.io` \
  && yum clean all
ENV GCC_VER=gcc731
# doxygen and LaTeX
COPY texlive.profile /usr/local/src/
RUN wget -qO- --no-check-certificate \
  "https://downloads.sourceforge.net/project/doxygen/rel-1.8.13/doxygen-1.8.13.linux.bin.tar.gz" \
  | tar -xz -C /usr/local/ \
  && mv /usr/local/doxygen-1.8.13/bin/doxygen /usr/local/bin/ \
  && rm -rf /usr/local/doxygen-1.8.13/ \
  && wget -qO- "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2017/tlnet-final/install-tl-unx.tar.gz" \
  | tar -xz -C /usr/local/src/ \
  && /usr/local/src/install-tl-20180303/install-tl -profile /usr/local/src/texlive.profile \
     -repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2017/tlnet-final/archive/ \
  && rm -rf /usr/local/src/install-tl-20180303 /usr/local/src/texlive.profile \
  && tlmgr install epstopdf
ENV PATH=$PATH:/usr/local/texlive/2017/bin/x86_64-linux
# CUDA https://developer.nvidia.com/cuda-10.1-download-archive-update1
RUN wget -q "https://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64/cuda-repo-rhel6-10.1.168-1.x86_64.rpm" \
  && rpm --install cuda-repo-rhel6-10.1.168-1.x86_64.rpm \
  && yum clean all \
  && yum -y install \
     cuda-compiler-10-1 \
     cuda-libraries-dev-10-1 \
  && ln -s cuda-10.1 /usr/local/cuda \
  && yum clean all \
  && rm cuda-repo-rhel6-10.1.168-1.x86_64.rpm
# cmake
RUN wget -qO- "https://github.com/Kitware/CMake/releases/download/v3.17.5/cmake-3.17.5-Linux-x86_64.tar.gz" \
  | tar --strip-components=1 -xz -C /usr/local/
# externpro
RUN export XP_VER=20.08.1 \
  && mkdir /opt/extern \
  && export XP_DL=releases/download/${XP_VER}/externpro-${XP_VER}-${GCC_VER}-64-Linux.tar.xz \
  && wget -qO- "https://github.com/smanders/externpro/${XP_DL}" \
   | tar -xJ -C /opt/extern/ \
  && printf "lsb_release %s\n" "`lsb_release --description`" \
     >> /opt/extern/externpro-${XP_VER}-${GCC_VER}-64-Linux/externpro_${XP_VER}-${GCC_VER}-64.txt \
  && unset XP_DL && unset XP_VER
