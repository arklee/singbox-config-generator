#!/bin/bash

WORKDIR=$HOME/.config/singbox
SINGBOX=/usr/bin/sing-box

LINK="https://fcsblka.fcsubcn.cc:2096/api/v1/client/subscribe?token=8788dd5b8aa58ccf6a1f4a81a10eb4b1"
#LINK="https://ul6zrv9.bigme.online/api/v1/client/subscribe?token=1ec4e5d58bfdb86340d6fd82184d1571"
LINK2="https://bigmesub001.azure-api.net/happy/api/v1/client/subscribe?token=1ec4e5d58bfdb86340d6fd82184d1571&flag=sing-box&types=all"

cd $WORKDIR

TUNFILE=config/sub_tun.json
NOTUNFILE=config/sub_mixed.json
TPROFILE=config/sub_tproxy.json

MAINFILE=defaultconfig/custom_config.jsonc

download_config() {
  wget -O $WORKDIR/sub.json -q $LINK2
  wget -O $WORKDIR/sub.txt -q $LINK
  if [ $? -eq 0 ]; then
    node script/convert.js sub.txt sub.json outbounds.json
    $SINGBOX merge $TUNFILE -c ./defaultconfig/inbounds_tun.json \
                            -c $MAINFILE \
                            -c outbounds.json
    $SINGBOX merge $NOTUNFILE -c ./defaultconfig/inbounds_mixed.json \
                              -c $MAINFILE \
                              -c outbounds.json
    $SINGBOX merge $TPROFILE -c ./defaultconfig/inbounds_tproxy.json \
                             -c $MAINFILE \
                             -c outbounds.json
    rm outbounds.json sub.txt sub.json
    echo "updated"
  else
    echo "update failed"
  fi
}

enable_gnome_proxy() {
  gsettings set org.gnome.system.proxy mode 'manual'
  gsettings set org.gnome.system.proxy.https port 2080
  gsettings set org.gnome.system.proxy.http port 2080
  gsettings set org.gnome.system.proxy.socks port 2080
}

set_cap_net() {
  sudo setcap cap_net_admin+ep $SINGBOX
}

enable_system_tproxy() {
  sudo nft flush ruleset
  sudo bash ./script/nftables-gateway.sh
}

disable_system_tproxy() {
  sudo ip rule del fwmark 1 table 100
  sudo ip route del local 0.0.0.0/0 dev lo table 100
  sudo nft flush ruleset
}

run_notun() {
  #enable_gnome_proxy
  $SINGBOX run -D $WORKDIR -c $NOTUNFILE
}

run_notun_daemon() {
  nohup $SINGBOX run -D $WORKDIR -c $NOTUNFILE &>/dev/null &
}

run_tun() {
  $SINGBOX run -D $WORKDIR -c $TUNFILE
}

run_tun_daemon() {
  nohup $SINGBOX run -D $WORKDIR -c $TUNFILE &>/dev/null &
}

run_tproxy() {
  $SINGBOX run -D $WORKDIR -c $TPROFILE
}

run_tproxy_daemon() {
  nohup $SINGBOX run -D $WORKDIR -c $TPROFILE &>/dev/null &
}

kill_singbox() {
  killall sing-box
}

check_status() {
  if pgrep -f 'sing-box' >/dev/null; then
    echo "running"
  else
    echo "not running"
  fi
}

if [ $1 == "update" ]; then
  download_config
elif [ $1 == "run" ]; then
  if [[ -z $2 ]]; then
    run_notun
  elif [ $2 == "tun" ]; then
    run_tun
  elif [ $2 == "tproxy" ]; then
    run_tproxy
  else
    echo "invalid 2nd command"
  fi
elif [ $1 == "start" ]; then
  if [[ -z $2 ]]; then
    run_notun_daemon
  elif [ $2 == "tun" ]; then
    run_tun_daemon
  elif [ $2 == "tproxy" ]; then
    run_tproxy_daemon
  else
    echo "invalid 2nd command"
  fi
elif [ $1 == "restart" ]; then
  if [[ -z $2 ]]; then
    killall sing-box
    run_notun_daemon
  elif [ $2 == "tun" ]; then
    killall sing-box
    run_tun_daemon
  else
    echo "invalid 2nd command"
  fi
elif [ $1 == "stop" ]; then
  kill_singbox
elif [ $1 == "status" ]; then
  check_status
elif [ $1 == "setcap" ]; then
  set_cap_net
elif [ $1 == "enableT" ]; then
  enable_system_tproxy
elif [ $1 == "disableT" ]; then
  disable_system_tproxy
else
  echo "invalid 1st command"
fi
