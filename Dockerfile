FROM ubuntu:20.04

# SEE: https://github.com/phusion/baseimage-docker/issues/58
ARG DEBIAN_FRONTEND=noninteractive
ARG NB_USER="jovyan"
ARG NB_UID="2005"
ARG NB_GID="2005"

# set up environment variables
ENV CONDA_VERSION=4.10.3-2 \
    CONDA_ENV=notebook \
    NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    SHELL=/bin/bash \
    LANG=C.UTF-8  \
    LC_ALL=C.UTF-8 \
    CONDA_DIR=/srv/conda

ENV NB_PYTHON_PREFIX=${CONDA_DIR}/envs/${CONDA_ENV} \
    HOME=/home/${NB_USER}

ENV PATH=${NB_PYTHON_PREFIX}/bin:${CONDA_DIR}/bin:${PATH}


# Create jovyan user, home folder, subfolders, set up permissions
RUN echo "Creating ${NB_USER} user and home folder structure..." \
    && mkdir -p /opt \
    && mkdir -p /srv \
    && groupadd --gid ${NB_GID} ${NB_USER}  \
    && useradd --create-home --gid ${NB_GID} --no-log-init --uid ${NB_UID} ${NB_USER} \
    && chown -R ${NB_USER}:${NB_GID} /opt ${HOME} /srv

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    gfortran \
    python2.7 \
    flex \
    libnetcdf-dev \
    libgsl-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN echo "Installing basic apt-get packages..." \
    && apt-get update --fix-missing \
    && apt-get install -y apt-utils 2> /dev/null \
    && apt-get install -y wget zip tzdata \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Copying bashrc_conda.txt and condarc.yml into the image" 
COPY --chown=${NB_USER}:${NB_GID} ./bashrc_conda.txt /tmp
COPY --chown=${NB_USER}:${NB_GID} ./dotpylrtrc /tmp
COPY --chown=${NB_USER}:${NB_GID} ./condarc.yml /srv

RUN echo "Adding conda environment to /etc/profile.d and /home/jovyan/.bashrc" \
    && cat /tmp/bashrc_conda.txt >> /etc/profile.d/init_conda.sh \
    && cat /tmp/bashrc_conda.txt >> ${HOME}/.bashrc \
    && cat /tmp/dotpylrtrc >> ${HOME}/.pylrtrc \
    && rm /tmp/bashrc_conda.txt
    
RUN echo "conda activate ${CONDA_ENV}" >> ${HOME}/.bashrc

# Switch to jovyan user
USER ${NB_USER}
WORKDIR ${HOME}


# install miniforge
RUN echo "Installing Miniforge..." \
    && URL="https://github.com/conda-forge/miniforge/releases/download/${CONDA_VERSION}/Miniforge3-${CONDA_VERSION}-Linux-x86_64.sh" \
    && wget --quiet ${URL} -O miniconda.sh \
    && /bin/bash miniconda.sh -u -b -p ${CONDA_DIR} \
    && rm miniconda.sh \
    && conda install -y -c conda-forge mamba bokeh \
    && mamba clean -afy \
    && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
    && find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete

# Create "notebook" conda environment
RUN echo "Copying conda-linux-64.lock into homedir..."
COPY ./conda-linux-64.lock ${HOME}
RUN echo "Creating environment from conda-linux-64.lock..." \
    && mamba create --name ${CONDA_ENV} --file ${HOME}/conda-linux-64.lock \
    && mamba clean -yaf \
    && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
    && find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete \
    && rm ${HOME}/conda-linux-64.lock

# Install pip packages
# remove cache https://github.com/pypa/pip/pull/6391 ?
COPY ./requirements.txt ${HOME} 
RUN echo "Checking for 'requirements.txt'..." \
      && ${NB_PYTHON_PREFIX}/bin/pip install --no-cache-dir -r ${HOME}/requirements.txt \
      && rm -rf ${HOME}/requirements.txt 

ENV PATH /opt/libRadtran/bin:$PATH

ENV PYTHON /usr/bin/python2.7

RUN echo "compiling libradtran" \
  && curl -SL http://www.libradtran.org/download/history/libRadtran-2.0.3.tar.gz \
    | tar -xzC /opt/ \
  && mv /opt/libRadtran-2.0.3 /opt/libRadtran \
  && cd /opt/libRadtran \
  && ./configure && make

RUN echo "copying reptran data to /opt/libRadtran"
COPY --chown=${NB_USER}:${NB_GID} ./shared/data/correlated_k /opt/libRadtran/data/


RUN echo "add shared directory" \
    && mkdir -p /opt/libRadtran/shared

WORKDIR /opt/libRadtran

# VOLUME ["/opt/libRadtran/shared"]
