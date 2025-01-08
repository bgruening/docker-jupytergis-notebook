# Jupyter container used for Galaxy IPython (+other kernels) Integration

# We want to support Python, R, Julia, Bash and to a lesser degree ansible, octave
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html
# Accoring to the link above we should take scipy-notebook and add additional kernels.
# Since Julia installation seems to be complicated we will take the Julia notebook as base and install separate kernels into separate envs
FROM quay.io/jupyter/julia-notebook:python-3.12

MAINTAINER Anne Fouilloux, annef@simula.no

ENV DEBIAN_FRONTEND=noninteractive

# Set channels to bioconda > conda-forge
RUN conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda config --set channel_priority strict && \
    conda --version

# Install python and jupyter packages
RUN conda install --yes \ 
    bioblend galaxy-ie-helpers \
    biopython \
    jupyterlab-geojson \
    jupytergis_qgis \
    qgis \
    pip && \
    ##
    ## Now create separate environments, that are managed by nb_conda_kernels
    ##
    conda create -n python-kernel-3.12 --yes python=3.12 ipykernel bioblend galaxy-ie-helpers  && \
    conda clean --all -y && \
    chmod a+w+r /opt/conda/ -R

ADD ./startup.sh /startup.sh
#ADD ./monitor_traffic.sh /monitor_traffic.sh
ADD ./get_notebook.py /get_notebook.py

# We can get away with just creating this single file and Jupyter will create the rest of the
# profile for us.
RUN mkdir -p /home/$NB_USER/.ipython/profile_default/startup/ && \
    mkdir -p /home/$NB_USER/.jupyter/custom/

ADD ./ipython-profile.py /home/$NB_USER/.ipython/profile_default/startup/00-load.py
ADD jupyter_notebook_config.py /home/$NB_USER/.jupyter/
ADD jupyter_lab_config.py /home/$NB_USER/.jupyter/

ADD ./custom.js /home/$NB_USER/.jupyter/custom/custom.js
ADD ./custom.css /home/$NB_USER/.jupyter/custom/custom.css
ADD ./default_notebook.ipynb /home/$NB_USER/notebook.ipynb

# ENV variables to replace conf file
ENV DEBUG=false \
    GALAXY_WEB_PORT=10000 \
    NOTEBOOK_PASSWORD=none \
    CORS_ORIGIN=none \
    DOCKER_PORT=none \
    API_KEY=none \
    HISTORY_ID=none \
    REMOTE_HOST=none \
    GALAXY_URL=none

# @jupyterlab/google-drive  not yet supported

USER root

# R pre-requisites
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    net-tools \
    procps \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# /import will be the universal mount-point for Jupyter
# The Galaxy instance can copy in data that needs to be present to the Jupyter webserver
RUN mkdir -p /import/jupyter/outputs/ && \
    mkdir -p /import/jupyter/data && \
    mkdir /export/ && \
    chown -R $NB_USER:users /home/$NB_USER/ /import /export/ && \
    chmod -R 777 /home/$NB_USER/ /import /export/

##USER jovyan

WORKDIR /import

# Start Jupyter Notebook
CMD /startup.sh