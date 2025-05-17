#!/bin/bash 

Xvfb :1 -screen 0 1920x1080x24 &
export DISPLAY=:1

startxfce4 &

sleep 5

x11vnc -display :1 -nopw -forever -shared &

/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 & 

ros2 launch ur_robot_driver ur_control.launch.py ur_type:=ur5e robot_ip:=192.168.56.101