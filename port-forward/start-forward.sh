#!/bin/bash
sudo screen -S sudo ./socat TCP4-LISTEN:443,fork,reuseaddr,su=nobody TCP4:127.0.0.1:30742
sudo screen -S sudo ./socat TCP4-LISTEN:80,fork,reuseaddr,su=nobody TCP4:127.0.0.1:30432
