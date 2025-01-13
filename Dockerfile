FROM quay.io/galaxy/docker-jupyter-notebook:24.12

# Install python and jupyter packages
RUN conda install --yes \ 
    bioblend galaxy-ie-helpers \
    jupytergis \
    qgis && \
    conda clean --all -y && \
    chmod a+w+r /opt/conda/ -R

ADD jupyter_notebook_config.py /home/$NB_USER/.jupyter/
ADD jupyter_lab_config.py /home/$NB_USER/.jupyter/

# /import will be the universal mount-point for Jupyter
# The Galaxy instance can copy in data that needs to be present to the Jupyter webserver
RUN chown -R $NB_USER:users /home/$NB_USER/ /import /export/ && \
    chmod -R 777 /home/$NB_USER/ /import /export/

WORKDIR /import

# Start Jupyter Notebook
CMD /startup.sh
