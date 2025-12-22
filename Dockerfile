FROM quay.io/galaxy/docker-jupyter-notebook:25.12.1

# Install python and jupyter packages
RUN conda install --yes \ 
    bioblend galaxy-ie-helpers \
    qgis && \
    conda clean --all -y  && \
    fix-permissions /opt/conda

RUN pip install jupytergis==0.11.1 'jupyter-ai[all]'

ADD jupyter_notebook_config.py /home/$NB_USER/.jupyter/
ADD jupyter_lab_config.py /home/$NB_USER/.jupyter/

# /import will be the universal mount-point for Jupyter
# The Galaxy instance can copy in data that needs to be present to the Jupyter webserver
RUN chown -R $NB_USER:users /home/$NB_USER/ /import /export/ && \
    chmod -R 777 /home/$NB_USER/ /import /export/

# Create a directory for Ollama
RUN mkdir -p /opt/ollama/bin /opt/ollama/models && \
    chown -R $NB_USER:users /opt/ollama

# Download and extract Ollama binary (amd64 assumed)
RUN cd /opt/ollama && \
    curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz && \
    tar -xzf ollama-linux-amd64.tgz && \
    rm ollama-linux-amd64.tgz

# Add Ollama to PATH
ENV PATH="/opt/ollama/bin:${PATH}"

# Pre-pull the model
RUN ollama serve & \
    until curl -s http://localhost:11434/api/tags > /dev/null; do sleep 1; done && \
    ollama pull llama3.2 && \
    pkill ollama

WORKDIR /import

# Copy Ollama startup script
COPY start-ollama.sh /usr/local/bin/start-ollama.sh
RUN chmod +x /usr/local/bin/start-ollama.sh

# Start Jupyter Notebook
CMD /startup.sh
