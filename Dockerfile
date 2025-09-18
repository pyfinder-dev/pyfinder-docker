FROM ghcr.io/sceylan/finder-base:gmt5

ENV DEBIAN_FRONTEND=noninteractive \
    WORK_DIR=/usr/local/src 

# Skipping additional apt-get installs on the frozen Buster base.
# git/wget/python3-pip are already present; we will install Python 3.9 and needed pip packages below.
RUN mkdir $WORK_DIR/python39 \
    && cd $WORK_DIR/python39 \
    && wget https://www.python.org/ftp/python/3.9.9/Python-3.9.9.tgz \
    && tar xvf Python-3.9.9.tgz \
    && cd Python-3.9.9 \
    && ./configure \
    && make -j$(nproc) \
    && make altinstall \
    && cd .. && rm -rf Python-3.9.9*

# Install pip using ensurepip and install setuptools for pip install -e
RUN python3.9 -m ensurepip --upgrade \
    && python3.9 -m pip install --upgrade pip setuptools wheel \
    && python3.9 -m pip install --no-cache-dir utils m2r 'mistune==0.8.4'

# actual installation of shakemap
RUN git clone --depth 1 https://github.com/DOI-USGS/ghsc-esi-shakemap.git $WORK_DIR/shakemap \
    && cd $WORK_DIR/shakemap \
    && python3.9 -m pip install -e .

 
# Switch to sysop for per-user profiles and data
USER sysop
WORKDIR /home/sysop

# download slab data etc. into data folder
RUN mkdir -p /home/sysop/sm_data \
    && strec_cfg update --datafolder /home/sysop/sm_data --slab # --gcmt

# setup shakemap profile
RUN sm_profile -c default -a

# get pyfinder to wrap FinDer in python
RUN git clone https://github.com/pyfinder-dev/pyfinder.git /home/sysop/pyfinder

# get the parametric web services clients paramws-clients
RUN git clone https://github.com/pyfinder-dev/paramws-clients.git /home/sysop/paramws-clients

# bring in ShakeMap patches into the image
# COPY host_shared /home/sysop/host_shared
# Copy only the ShakeMap patch overrides into the image
COPY host_shared/docker_overrides/shakemap_patches /tmp/shakemap_patches

USER root
# ShakeMap patches (as root)
COPY host_shared/docker_overrides/shakemap_patches /home/sysop/host_shared/docker_overrides/shakemap_patches
RUN cp -f /home/sysop/host_shared/docker_overrides/shakemap_patches/utils/amps.py /usr/local/lib/python3.9/site-packages/shakemap_modules/utils/amps.py \
    && cp -f /home/sysop/host_shared/docker_overrides/shakemap_patches/coremods/assemble.py /usr/local/lib/python3.9/site-packages/shakemap_modules/coremods/assemble.py \
    && cp -f /home/sysop/host_shared/docker_overrides/shakemap_patches/config.ini /home/sysop/.strec/config.ini \
    && cp -f /usr/local/lib/python3.9/site-packages/strec/data/moment_tensors.db /home/sysop/.strec/moment_tensors.db \
    && cp -f /usr/local/lib/python3.9/site-packages/strec/data/moment_tensors.db /home/sysop/sm_data/moment_tensors.db


# Final ownership fix
RUN chown -R sysop:sysop /home/sysop
# Clean-up
RUN rm -rf /root/.cache/pip \
    && rm -rf /tmp/shakemap_patches

USER sysop

# Install local paramws-clients package in editable mode
RUN python3.9 -m pip install -e /home/sysop/paramws-clients

# Install python packages
RUN python3.9 -m pip install psycopg2 xmltodict filelock pandas geopandas geojson shapely tornado

# Clean-up
RUN rm -rf /home/sysop/.cache/pip