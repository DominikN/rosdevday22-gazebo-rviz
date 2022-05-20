FROM ros:galactic-ros-core

# Use bash instead of sh for the RUN steps
SHELL ["/bin/bash", "-c"]

# Install ros packages and dependencies
RUN apt-get update && apt-get install -y \
        ros-${ROS_DISTRO}-demo-nodes-cpp \
        ros-${ROS_DISTRO}-rmw-fastrtps-cpp && \
    rm -rf /var/lib/apt/lists/*

ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp