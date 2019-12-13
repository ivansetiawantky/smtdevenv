# -*- coding: utf-8 -*-
# Modified by Ivan Setiawan
# 'Last modified: Fri Dec 13 23:13:46 2019.'
#
# Docker container create:
# docker run --rm -ti --name mysmtdev \
# -v $HOME/work/smtdevenv/sharedwks:/home/smtdev/sharedwks \
# -v $HOME/.ssh:/home/smtdev/.ssh \
# ivansetiawantky/smtdevenv:2.2 \
# byobu new
#
# Detach: Control p q
# Attach: docker container attach mysmtdev
#
# SSH from inside docker to outside:
# ssh machine.ext -o ControlPath=/dev/shm/control:%h:%p:%r
# scp -o ControlPath=/dev/shm/control:%h:%p:%r remotevm.ext:/home/remoteuser/abc.tgz .
# rsync -ahcvp -e "ssh -o ControlPath=/dev/shm/control:%h:%p:%r" remotevm.ext:/home/remoteuser/170725.tgz .
# Add ssh-agent first: eval `ssh-agent` <= Do first!

FROM ubuntu:18.04

# Check metadata of image with docker inspect image | jq '.[0].Config.Labels'
LABEL description="Ubuntu-based development environment for Statistical Machine Translation (SMT) research."
LABEL reference1="Reference for SMT environment: https://qiita.com/R-Yoshi/items/9a809c0a03e02874fabb#no4"
LABEL reference2="Reference for Dockerfile for containerized dev env: https://dev.to/aghost7/developing-from-containers-42fp"
LABEL reference3="Detailed reference for Dockerfile for containerized dev env: https://github.com/AGhost-7/docker-dev/tree/master/tutorial"
LABEL maintainer="Ivan Setiawan <j.ivan.setiawan@gmail.com>"
LABEL vendor="Arcadia, Inc."
LABEL version="2.2"

ENV DOCKER_USER smtdev
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NOWARNINGS yes

# Add required packages.
# Create user with passwordless sudo. This RUN is run as ROOT.
RUN apt-get update && apt-get install -y \
    sudo \
    build-essential \
    git-core \
    pkg-config \
    automake \
    libtool \
    wget \
    zlib1g-dev \
    python-dev \
    libbz2-dev \
    bash-completion \
    curl \
    tmux \
    byobu \
    vim \
    libboost-all-dev \
    openssh-client \
    && \
    yes | sudo unminimize && \
    adduser --disabled-password --gecos '' "$DOCKER_USER" && \
    adduser "$DOCKER_USER" sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    touch /home/$DOCKER_USER/.sudo_as_admin_successful && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER "$DOCKER_USER"

WORKDIR "/home/$DOCKER_USER"

COPY ./dot.vimrc /tmp/dot.vimrc

# Below command must be run by the $DOCKER_USER, so put after USER is defined.
# In case byobu-ctrl-a still cannot work, then put it inside ~/.profile
RUN echo 'set -o noclobber' >> /home/$DOCKER_USER/.bashrc && \
    echo 'alias ex="exit"' >> /home/$DOCKER_USER/.bashrc && \
    echo 'alias rm="rm -i"' >> /home/$DOCKER_USER/.bashrc && \
    echo 'alias cp="cp -i"' >> /home/$DOCKER_USER/.bashrc && \
    echo 'alias mv="mv -i"' >> /home/$DOCKER_USER/.bashrc && \
    echo '2' | byobu-ctrl-a && \
    cat /tmp/dot.vimrc > /home/$DOCKER_USER/.vimrc && \
    sudo rm /tmp/dot.vimrc && \
    #
    # Below prepare container local directory for moses and clone it.
    mkdir -p /home/$DOCKER_USER/localwks/moses/mosesdecoder && \
    git clone https://github.com/moses-smt/mosesdecoder.git \
    /home/$DOCKER_USER/localwks/moses/mosesdecoder && \
    # Download sample-models here, to reduce cd by WORKDIR...
    curl -L -o /home/$DOCKER_USER/localwks/sample-models.tgz \
    http://www.statmt.org/moses/download/sample-models.tgz && \
    tar xzf /home/$DOCKER_USER/localwks/sample-models.tgz \
    -C /home/$DOCKER_USER/localwks && \
    #
    # Compile mosesdecoder.
    # Switch directory (cd) to container local directory for mosesdecoder
    cd /home/$DOCKER_USER/localwks/moses/mosesdecoder && ./bjam && \
    #
    # Test the compilation of mosesdecoder. MUST BE RUN IN sample-models dir.
    cd /home/$DOCKER_USER/localwks/sample-models && \
    /home/$DOCKER_USER/localwks/moses/mosesdecoder/bin/moses \
    -f phrase-model/moses.ini < phrase-model/in > out
# Check /home/$DOCKER_USER/localwks/sample-models/out !

# Go back to home directory! <== NOT needed!
# WORKDIR "/home/$DOCKER_USER" <== NOT needed!
# The final WORKDIR (or /, if WORKDIR not used at all) is the pwd
# when entering container.

CMD ["/bin/bash" ]
