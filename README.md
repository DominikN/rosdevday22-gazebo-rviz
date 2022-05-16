# rosdevday22-gazebo-rviz

Controlling ROSbot XL running in Gazebo on ROS DS platform from RViz running on a local computer.

Husarnet VPN is a very handy way to connect remote ROS 2 nodes over WAN. In this project the simulation model of Husarion ROSbot XL together with Nav2 is running on the local computer and we control it from RViz running in the ROSject.

> **Prerequisites**
>
> Make sure you have [Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) and [Docker Compose v2](https://docs.docker.com/compose/cli-command/#install-on-linux) installed on your laptop. Tested on Ubuntu 20.04.
>
> If you don't have, here's a quick summary for Ubuntu 20.04:
> 
> 1. Installing Docker (just click the `copy` button, and paste it to the Linux terminal):
>     ```bash
>     sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg lsb-release
>     ```
>     ```bash
>     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
>     ```
>     ```bash
>     echo \
>     "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
>     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
>     ```
>     ```bash
>     sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io
>     ```
>
> 2. Installing Docker Compose v2
>     ```bash
>     mkdir -p /usr/local/lib/docker/cli-plugins
>     ```
>     ```bash
>     curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
>     ```
>     ```bash
>     chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
>     ```
>
> The proper version of Docker and Docker Compose are already installed in the ROSject

## Testing everything on local device

```
xhost local:root
docker compose -f compose.rviz.yaml -f compose.gazebo.yaml up
```

![Gazebo and RViz running on the same host](.docs/rviz_gazebo.png)

## Running on remote devices

Get your Husarnet VPN `Join Code` first:

1. Log in to https://app.husarnet.com/
2. Select or create a network
3. Click the **[Add element]** button and select a `Join Code` tab:

![Husarnet Join Code](.docs/join-code.png)

Next create an `.env` file and place your Husarnet Join Code here:

```
HUSARNET_JOINCODE=fc94:b01d:1803:8dd8:b293:5c7d:7639:932a/xxxxxxxxxxxxxxxxxxxxxx
```

Finally, generate Husarnet `id` files to know your end-devices Husarnet IPv6 addresses before the first run. The same IP addresses are needed to be copied then to a custom `dds-config.xml` file to the section with **known hosts** (because mulitcasting over VPN is not recommended - [read more](https://husarnet.com/blog/ros2-dds-discovery-server/#using-multicasting-based-dds-simple-discovery)). Of course it could be done manually, but I have created a simple bash script to do so. Just run:

```
./generate-dds-config.sh
```

Now on the same, or on different hosts, in different networks launch Docker deployments for `rviz` and `gazebo` Husarnet hostnames:

### `rviz` device

```
xhost local:root
docker compose -f compose.rviz.yaml -f compose.rviz.husarnet.yaml up
```

### `gazebo` device

```
xhost local:root
docker compose -f compose.gazebo.yaml -f compose.gazebo.husarnet.yaml up
```

At this point you should be able to control the ROSbot XL simulation model from RViz running on the other computer.

### ROS DS platform

OK, so you know how to run dockerized setup on three different devices. So right now let's try to control the Gazebo model running on your laptop from RViz running in the ROS DS.

This ROSject is based on ROS 2 Galactic that is shipped with a Cyclone DDS by default that supports only the Simple discovery mechanism. Fast DDS is the only one that supports Discovery Server, so we need to install it and use the custom XML config:

Run all commands bellow in your ROSject. It's handy to do it as a root user:

```
sudo su
```

#### Connecting to your Husarnet network

ROSjects are Docker containers by their own and we can not run our own containers inside. So we need to configure everything on the "ROSject host" level, without Docker. 

Husarnet VPN client is preinstalled inside this ROSject.  ROSjects don't have systemd, so to start Husarnet daemon, open a new terminal window and run:

```
sudo husarnet daemon
```

Open one more terminal window and execute:

```
sudo husarnet join fc94:b01d:1803:8dd8:b293:5c7d:7639:932a/xxxxxxxxxxxxxxxxxxxxxx my_rosject
```

...  to connect your ROSject to the same Husarnet network as containers running on your laptop. Of course instead of `fc94:b01d:1803:8dd8:b293:5c7d:7639:932a/xxxxxxxxxxxxxxxxxxxxxx` use your own Husarnet Join Code (the same as you placed in `.env` file before).

#### Installing FastDDS

```
apt-get update && apt-get install -y ros-${ROS_DISTRO}-rmw-fastrtps-cpp
```

#### Create a custom XML config for DDS

Read your Husarnet IPv6 address and copy it:

```
user:~$ sudo husarnet status
Version: 2020.06.29.1
Husarnet IP address: fc94:252c:ccb0:11db:9e63:e5a3:d6c4:ab5c
UDP connection to base: [188.165.23.196]:5582
Peer fc94:b01d:1803:8dd8:b293:5c7d:7639:932a
  addresses from base=[51.178.64.85]:1056 [51.178.64.85]:5582 [127.0.0.1]:5582 [172.20.0.3]:5582
  tunnelled
  secure connection established
```

Create `dds-config.xml` file in the `/home/user` directory, and paste the content of `rosdevday22-gazebo-rviz/secret/dds-config.xml` from your laptop. Add a new record with your ROSject's Husarnet IPv6 address:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<dds>
    <profiles xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles">
        <transport_descriptors>
            <transport_descriptor>
                <transport_id>udpv6_transport</transport_id>
                <type>UDPv6</type>
                <maxInitialPeersRange>40</maxInitialPeersRange>
                <!-- <non_blocking_send>true</non_blocking_send> -->
            </transport_descriptor>
        </transport_descriptors>

        <participant profile_name="husarnet_simple_profile" is_default_profile="true">
            <rtps>
                <userTransports>
                    <transport_id>udpv6_transport</transport_id>
                </userTransports>
                <useBuiltinTransports>false</useBuiltinTransports>
                <defaultUnicastLocatorList>
                    <locator>
                        <udpv6>
                            <address>fc94:8da9:3bfe:bcc6:xxxx:xxxx:xxxx:xxxx</address>
                        </udpv6>
                    </locator>
                    <locator>
                        <udpv6>
                            <address>fc94:8f7d:2313:xxxx:xxxx:xxxx:xxxx:xxxx</address>
                        </udpv6>
                    </locator>
                    <locator>
                        <udpv6>
                            <!-- Place the ROSject's IPv6 address here -->
                            <address>fc94:252c:ccb0:11db:9e63:e5a3:d6c4:ab5c</address>
                        </udpv6>
                    </locator>
                </defaultUnicastLocatorList>
                <builtin>
                    <initialPeersList>
                        <locator>
                            <udpv6>
                                <address>fc94:8da9:3bfe:bcc6:xxxx:xxxx:xxxx:xxxx</address>
                            </udpv6>
                        </locator>
                        <locator>
                            <udpv6>
                                <address>fc94:8f7d:2313:xxxx:xxxx:xxxx:xxxx:xxxx</address>
                            </udpv6>
                        </locator>
                        <locator>
                            <udpv6>
                                <!-- Place the ROSject's IPv6 address here -->
                                <address>fc94:252c:ccb0:11db:9e63:e5a3:d6c4:ab5c</address>
                            </udpv6>
                        </locator>
                    </initialPeersList>

                    <metatrafficUnicastLocatorList>
                        <locator>
                            <udpv6>
                                <address>fc94:8da9:3bfe:bcc6:xxxx:xxxx:xxxx:xxxx</address>
                            </udpv6>
                        </locator>
                        <locator>
                            <udpv6>
                                <address>fc94:8f7d:2313:xxxx:xxxx:xxxx:xxxx:xxxx</address>
                            </udpv6>
                        </locator>
                        <locator>
                            <udpv6>
                                <!-- Place the ROSject's IPv6 address here -->
                                <address>fc94:252c:ccb0:11db:9e63:e5a3:d6c4:ab5c</address> 
                            </udpv6>
                        </locator>
                    </metatrafficUnicastLocatorList>     
                </builtin>
            </rtps>
        </participant>
    </profiles>
</dds>
```

Save the file.

#### Running the RViz with FastDDS and a custom XML configuration

In the ROSject create `/home/user/.rviz2/default.rviz` file and paste `rosdevday22-gazebo-rviz/config/slam.rviz` file content inside.

Now execute this command in the ROSject's Linux terminal control your Gazebo model remotely:

```
RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
FASTRTPS_DEFAULT_PROFILES_FILE=/home/user/dds-config.xml \
ros2 run rviz2 rviz2
```