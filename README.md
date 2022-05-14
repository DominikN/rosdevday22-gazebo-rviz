# rosdevday22-gazebo-rviz
Controlling ROSbot XL runnin in Gazebo on ROS DS platform from RViz runnin on a local computer

## Testing everthing on local device

```
docker compose -f compose.pc.yaml -f compose.rosds.yaml up
```

## Running on remote devices

### laptop

```
docker compose -f compose.pc.yaml -f compose.pc.husarnet.yaml up
```

### ROS DS platform

```
docker compose -f compose.rosds.yaml -f compose.rosds.husarnet.yaml up
```