ARG ROS_DISTRO="jazzy"

##########################################
# Base Image for UR Simulation and Tests #
##########################################

FROM osrf/ros:${ROS_DISTRO}-desktop AS base

LABEL maintainer="TankalaSatyaSai<satyasai2004.edu@gmail.com"

ENV ROS_DISTRO=${ROS_DISTRO}

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl git libcanberra-gtk-module libcanberra-gtk3-module fuse3 libfuse2 libqt5svg5-dev \
    python3-pip python3-opencv python3-vcstool python3-tk python3-pyqt5.qtwebengine && \
    apt-get clean

RUN pip3 install --break-system-packages matplotlib transforms3d

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp && \
    apt-get clean
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

RUN mkdir -p /ur_ws/src
WORKDIR /ur_ws/src
COPY dependancies.repos .
RUN vcs import < dependancies.repos

WORKDIR /ur_ws
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    apt-get update -y && \
    rosdep install --from-paths src --ignore-src --ros-distro ${ROS_DISTRO} -y && \
    colcon build --symlink-install 

# Download Groot2 AppImage and place it in the home folder    
WORKDIR /root/
RUN curl -o Groot2.AppImage https://s3.us-west-1.amazonaws.com/download.behaviortree.dev/groot2_linux_installer/Groot2-v1.6.1-x86_64.AppImage && \
    chmod a+x Groot2.AppImage

RUN mkdir /tmp/runtime-root
ENV XDG_RUNTIME_DIR="/tmp/runtime-root"
RUN chmod -R 0700 /tmp/runtime-root
ENV NO_AT_BRIDGE=1

WORKDIR /ur_ws
COPY ./docker/entrypoint.sh /
ENTRYPOINT [ "entrypoint.sh" ]

##########################################
# Overlay Image for TurtleBot Simulation #
##########################################

FROM base AS overlay

RUN mkdir -p /overlay_ws/src
WORKDIR /overlay_ws
# COPY ./<our own package> ./src/<our own package>
RUN source /ur_ws/install/setup.bash && \
    rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y && \
    colcon build --symlink-install

COPY ./docker/entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]    

#####################
# Development Image #
#####################

FROM overlay AS dev

ARG USERNAME=devuser
ARG UID=1000
ARG GID=${UID}

RUN apt-get update && apt-get install -y --no-install-recommends \
    gdb gdbserver nano

RUN touch /var/mail/ubuntu \
    && chown ubuntu /var/mail/ubuntu \
    && userdel -r ubuntu

RUN groupadd --gid $GID $USERNAME \
    && useradd --uid ${GID} --gid ${UID} --create-home ${USERNAME} \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /home/${USERNAME} \
    && chown -R ${UID}:${GID} /home/${USERNAME}    

RUN chown -R ${UID}:${GID} /overlay_ws/

RUN groupadd fuse \
    && usermod -aG fuse ${USERNAME}
RUN mv /root/Groot2.AppImage /home/${USERNAME} \ 
    && chown ${UID}:${GID} /home/${USERNAME}/Groot2.AppImage

USER ${USERNAME}
RUN echo "source /entrypoint.sh" >> /home/${USERNAME}/.bashrc