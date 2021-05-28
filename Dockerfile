#run sample
#export Image_name=localhost:5000/cuda11.1-runtime-ubuntu20.04-conda:2104 
#docker build --no-cache -t $Image_name -f ./Dockerfile .
#docker build --no-cache --build-arg From_docker_image_arg=nvidia/cuda:10.2-runtime-ubuntu18.04  -t localhost:5000/cuda10.2-runtime-ubuntu18.04-conda:2104 -f ./Dockerfile .
#docker build --no-cache -t test/test:latest -t test/test:1.0.0 -f ./Dockerfile
#docker build --no-cache -t rep/name:tag .
#export container_name=test_cont
#sudo docker run --gpus all -td --ipc=host --privileged --userns=host --name $container_name -v /home/jhkim/dev:/root/dev -p 8888:8888 -p 20022:22 $Image_name
#docker exec -it $container_name jupyter lab --no-browser --ip=0.0.0.0 --allow-root --NotebookApp.token= --notebook-dir='/root/dev'

# refer docker hub 
# pull base image
#FROM nvidia/cuda:10.2-base-ubuntu18.04
#FROM nvidia/cuda:11.1-runtime-ubuntu20.04

#this image_arg may be over-written by --build-arg
ARG From_docker_image_arg=nvidia/cuda:11.1-runtime-ubuntu20.04

FROM ${From_docker_image_arg:-nvidia/cuda:11.1-runtime-ubuntu20.04}
RUN echo "From =${From_docker_image_arg:-nvidia/cuda:11.1-runtime-ubuntu20.04}"
ENV LC_ALL=C.UTF-8

# install basic utilities
#RUN . /etc/os-release; \
#                printf "deb http://ppa.launchpad.net/jonathonf/vim/ubuntu %s main" "$UBUNTU_CODENAME" main | tee /etc/apt/sources.list.d/vim-ppa.list && \
#                apt-key  adv --keyserver hkps://keyserver.ubuntu.com --recv-key 4AB0F789CBA31744CC7DA76A8CF63AD3F06FC659 && \

RUN apt-get update --fix-missing && \
    env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --autoremove --purge --no-install-recommends -y \
    			build-essential \
                        bzip2 \
                        ca-certificates \
                        curl \
                        git \
                        libcanberra-gtk-module \
                        libgtk2.0-0 \
                        libx11-6 \
                        sudo \
                        graphviz \
                        vim-nox

# Install miniconda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH
RUN apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion
RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

# Install python packages
RUN pip install jupyterlab jupyterhub

#RUN pip install torch torchvision && \
#    pip install cython && \
#    pip install simplejson && \
#    conda install av -c conda-forge

# install requiremnets when needed
#COPY requirements.txt /tmp
#WORKDIR /tmp
#RUN pip install -r requirements.txt

#setup ssh server
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd

#replace sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config

#set password to pass
RUN echo 'root:pass' | chpasswd

# make folder for volume redirection
RUN mkdir /root/dev


# install tiny init for docker entrypoint
RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

ENTRYPOINT [ "/usr/bin/tini", "--" ]

# run your program under Tini
CMD ["/usr/sbin/sshd", "-D"]
#CMD [ "/bin/bash", "-c", "/usb/sbin/sshd && bash" ]
