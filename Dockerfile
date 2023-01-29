FROM ubuntu:18.04

# SEE: https://github.com/phusion/baseimage-docker/issues/58
ARG DEBIAN_FRONTEND=noninteractive
ARG NB_USER="jovyan"
ARG NB_UID="2005"
ARG NB_GID="2005"

# Create jovyan user, home folder, subfolders, set up permissions
RUN echo "Creating ${NB_USER} user and home folder structure..." \
    && mkdir -p /opt \
    && groupadd --gid ${NB_GID} ${NB_USER}  \
    && useradd --create-home --gid ${NB_GID} --no-log-init --uid ${NB_UID} ${NB_USER} \
    && chown -R ${NB_USER}:${NB_GID} /opt 

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    gfortran \
    python \
    flex \
    libnetcdf-dev \
    libgsl-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER ${NB_USER}

ENV PATH /opt/libRadtran/bin:$PATH

ENV PYTHON /usr/bin/python2.7

RUN echo "compiling libradtran" \
  && curl -SL http://www.libradtran.org/download/history/libRadtran-2.0.3.tar.gz \
    | tar -xzC /opt/ \
  && mv /opt/libRadtran-2.0.3 /opt/libRadtran \
  && cd /opt/libRadtran \
  && ./configure && make

ENV PATH /opt/libRadtran/bin:$PATH

RUN echo "add shared directory" \
    && mkdir -p /opt/libRadtran/shared

WORKDIR /opt/libRadtran

# VOLUME ["/opt/libRadtran/shared"]
