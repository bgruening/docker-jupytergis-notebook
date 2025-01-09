# Jupyter container used for Galaxy IPython (+other kernels) Integration

# We want to support Python, R, Julia, Bash and to a lesser degree ansible, octave
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html
# Accoring to the link above we should take scipy-notebook and add additional kernels.
# Since Julia installation seems to be complicated we will take the Julia notebook as base and install separate kernels into separate envs
FROM ubuntu:20.04

MAINTAINER Anne Fouilloux, annef@simula.no

# Install basic packages
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget && \
    apt-get clean

# Install Miniforge3
RUN wget -q -nc --no-check-certificate -P /var/tmp https://github.com/conda-forge/miniforge/releases/download/24.9.2-0/Miniforge3-24.9.2-0-Linux-x86_64.sh && \
    bash /var/tmp/Miniforge3-24.9.2-0-Linux-x86_64.sh -b -p /opt/conda

# Create the environment for OSU Micro-Benchmarks
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda install -y jupytergis qgis && \
    conda install -y -c bioconda galaxy-ie-helpers && \
    conda clean -afy && \
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
