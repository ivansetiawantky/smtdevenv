# -*- coding: utf-8 -*-
# Modified by Ivan Setiawan
# 'Last modified: Sat Jan 25 08:46:27 2020.'
#
# Docker container create:
# docker run (--rm OR --restart=unless-stopped) -ti --name mysmtdev \
# -v $HOME/work/smtdevenv/sharedwks:/home/smtdev/sharedwks \
# -v $HOME/.ssh:/home/smtdev/.ssh \
# ivansetiawantky/smtdevenv:3.0 \
# byobu new
#
# Detach: Control p q
# Attach: docker container attach mysmtdev
#
# docker inspect -f "{{ .HostConfig.RestartPolicy.Name }}" mysmtdev
# docker update --restart={unless-stopped|always} mysmtdev
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
LABEL version="3.0"

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
    libcmph-dev \
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

# COPY ./dot.vimrc /tmp/dot.vimrc
COPY ./dot.* /tmp/

# Below command must be run by the $DOCKER_USER, so put after USER is defined.
# In case byobu-ctrl-a still cannot work, then put it inside ~/.profile
RUN cat /tmp/dot.bashrc-append >> /home/$DOCKER_USER/.bashrc && \
    # echo 'set -o noclobber' >> /home/$DOCKER_USER/.bashrc && \
    echo '2' | byobu-ctrl-a && \
    cat /tmp/dot.vimrc > /home/$DOCKER_USER/.vimrc && \
    cat /tmp/dot.dircolors > /home/$DOCKER_USER/.dircolors && \
    cat /tmp/dot.svn-prompt.sh > /home/$DOCKER_USER/.svn-prompt.sh && \
    cat /tmp/dot.git-prompt.sh > /home/$DOCKER_USER/.git-prompt.sh && \
    cat /tmp/dot.gitconfig > /home/$DOCKER_USER/.gitconfig && \
    sudo rm /tmp/dot.* && \
    #
    # Below prepare container local directory for mosesdecoder and clone it.
    # Put everything unique to the container directly below ~/localwks.
    mkdir -p /home/$DOCKER_USER/localwks/mosesdecoder && \
    git clone https://github.com/moses-smt/mosesdecoder.git \
    /home/$DOCKER_USER/localwks/mosesdecoder && \
    # Download sample-models here, to reduce cd by WORKDIR...
    curl -L -o /home/$DOCKER_USER/localwks/sample-models.tgz \
    http://www.statmt.org/moses/download/sample-models.tgz && \
    tar xzf /home/$DOCKER_USER/localwks/sample-models.tgz \
    -C /home/$DOCKER_USER/localwks && \
    #
    # Compile mosesdecoder. RELEASE-4.0
    # Switch directory (cd) to container local directory for mosesdecoder
    cd /home/$DOCKER_USER/localwks/mosesdecoder && \
    git checkout RELEASE-4.0 && \
    ./bjam --with-cmph=/usr/lib/x86_64-linux-gnu && \
    #
    # Test the compilation of mosesdecoder. MUST BE RUN IN sample-models dir.
    cd /home/$DOCKER_USER/localwks/sample-models && \
    /home/$DOCKER_USER/localwks/mosesdecoder/bin/moses \
    -f phrase-model/moses.ini < phrase-model/in > out
# Check /home/$DOCKER_USER/localwks/sample-models/out !

# Go back to home directory! <== NOT needed!
# WORKDIR "/home/$DOCKER_USER" <== NOT needed!
# The final WORKDIR (or /, if WORKDIR not used at all) is the pwd
# when entering container.

CMD ["/bin/bash" ]
