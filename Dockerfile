FROM ensemblorg/ensembl-vep:release_113.3

USER root

# install some useful tools
RUN \
    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y \
    aptitude \
    bash-completion \
    bcftools \
    curl \
    dnsutils \
    elinks \
    emacs-nox emacs-goodies-el \
    fish \
    git \
    gzip \
    htop \
    iperf3 \
    iproute2 \
    iputils-ping \
    less \
    liblapack-dev libopenblas-dev liblz4-dev \
    liblapack3 \
    libopenblas0 \
    mc \
    netcat-openbsd \
    nload \
    nmon \
    openjdk-11-jdk \
    python3 python3-pip \
    python3-venv \
    rsync \
    source-highlight \
    ssh \
    sudo \
    tar \
    telnet \
    tmux \
    unzip \
    vim \
    && rm -rf /var/lib/apt/lists/* && apt-get clean

########################################################################
# download and install spark
########################################################################
ARG SPARK_V=3.5
RUN \
    export SPARK_VER=$(curl -L 'https://archive.apache.org/dist/spark/' | grep -o "$SPARK_V\.[[:digit:]]\+" | tail -n 1) \
    && echo $SPARK_VER > /tmp/spark_ver \
    && cd /tmp && curl -L --remote-name "https://archive.apache.org/dist/spark/spark-$SPARK_VER/spark-$SPARK_VER-bin-hadoop3.tgz" \
    && cd / && tar xfz "/tmp/spark-$SPARK_VER-bin-hadoop3.tgz" \
    && rm -f "/tmp/spark-$SPARK_VER-bin-hadoop3.tgz" \
    && ln -s "spark-$SPARK_VER-bin-hadoop3" spark

WORKDIR /spark/jars
COPY varia/spark-defaults.conf /spark/conf
RUN curl -LO 'https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.2/hadoop-aws-3.3.2.jar' \
    && curl -LO 'https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.1026/aws-java-sdk-bundle-1.11.1026.jar'

ENV PYSPARK_DRIVER_PYTHON=python3
ENV PYSPARK_PYTHON=python3
ENV PYTHONPATH /spark/python:/spark/python/lib/py4j-0.10.9.5-src.zip
EXPOSE 8080
EXPOSE 7077
EXPOSE 4040

RUN \
    useradd -u 1000 -m -G sudo -s /usr/bin/fish -p '*' ubuntu \
    && sed -i 's/ALL$/NOPASSWD:ALL/' /etc/sudoers 
RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ubuntu
WORKDIR /home/ubuntu
RUN mkdir -p /home/ubuntu/.config/fish/conf.d/ volume

### HAIL installation
RUN python3 -m venv venv
RUN . venv/bin/activate && pip3 install --no-cache-dir IPython hail tqdm jupyterlab
# RUN . venv/bin/activate && pip3 install --no-cache-dir pyspark==$(cat /tmp/spark_ver)
RUN echo 'source ~/venv/bin/activate.fish' >> ~/.config/fish/config.fish

########################################################################
# RUN git clone https://github.com/hail-is/hail.git
# ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
# RUN . venv/bin/activate && cd hail/hail && make clean && \
#     make install-on-cluster HAIL_COMPILE_NATIVES=1 SCALA_VERSION=2.12.18 SPARK_VERSION=3.3.2

ENV PYTHONPATH $PYTHONPATH /home/ubuntu/hail/python

USER ubuntu
RUN mkdir .jupyter
COPY --chown=ubuntu:ubuntu varia/jupyter_lab_config.py .jupyter/
COPY --chown=ubuntu:ubuntu --chmod=755 varia/entrypoint-hail.sh .
COPY --chown=ubuntu:ubuntu notebooks notebooks

EXPOSE 8888
EXPOSE 8889

ENTRYPOINT fish
