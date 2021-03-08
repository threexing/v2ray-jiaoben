#!/bin/bash

#==========================#

###### Author: Threexing ######

#==========================#

#Stop v2ray/Caddy & delete v2ray/Caddy files.

Delete() {

    "$install_dir"/v2ray.init stop

    systemctl disable v2ray.service

    rm -rf /etc/init.d/v2ray /etc/systemd/system/v2ray.service /etc/init.d/Caddy /etc/systemd/system/Caddy.service

}

#Print error message and exit.

Error() {

    echo $echo_e_arg "\033[41;37m$1\033[0m"

    echo -n "remove v2ray?[y]: "

    read remove

    echo "$remove"|grep -qi 'n' || Delete

    exit 1

}

#Make v2ray.json

Config() {

    clear

    uuid=`cat /proc/sys/kernel/random/uuid`

    tcpFastOpen=`[ -f /proc/sys/net/ipv4/tcp_fastopen ] && echo -n 'true' || -n echo 'false'`

    echo -n $echo_e_arg "0. github全球最大的同性交友网（压缩）\n1. coding（官方源）\n2. tencent（国内压缩备份）\nPlease input v2ray core source(default is github): "

    read v2rayCoreSource

    echo -n "Please input v2ray install directory(default is /usr/local/v2ray): "

    read install_dir

    echo -n "Please input v2ray http server port(If not, do not enter): "

    read http_server_port

    echo -n "Please input v2ray webSocket server port(If not, do not enter): "

    read ws_server_port

    echo -n "Please input v2ray mKCP server port(If not, do not enter): "

    read mkcp_server_port

    [ -n "$http_server_port" ] && \

        in_networks='{

            "port": "'$http_server_port'",

            "protocol": "vmess",

            "settings": {

                "udp": true,

                "clients": [{

                     "id": "'$uuid'",

                     "level": 0,

                     "alterId": 4

                }]

            },

            "streamSettings": {

                "sockopt": {

                    "tcpFastOpen": '$tcpFastOpen'

                },

                "network": "tcp",

                "tcpSettings": {

                    "header": {

                        "type": "http"

                    }

                }

            }

        }'

    if [ -n "$ws_server_port" ]; then

        echo -n "Please input v2ray webSocket Path(default is '/'): "

        read ws_path

        echo -n "Please input webSocket tls domain(If not, do not enter): "

        read tls_domain

        [ -n "$in_networks" ] && in_networks="$in_networks, "

        in_networks=''"$in_networks"'{

            "port": "'$ws_server_port'",

            "protocol": "vmess",

            "settings": {

                "udp": true,

                "clients": [{

                    "id": "'$uuid'",

                    "level": 0,

                    "alterId": 4

                }]

            },

            "streamSettings": {

                "sockopt": {

                    "tcpFastOpen": '$tcpFastOpen'

                },

                "network": "ws",

                "wsSettings": {

                    "path": "'${ws_path:-/}'"

                }

            }

        }'

    fi

    if [ -n "$mkcp_server_port" ]; then

        [ -n "$in_networks" ] && in_networks="$in_networks, "

        in_networks=''"$in_networks"'{

            "port": "'$mkcp_server_port'",

            "protocol": "vmess",

            "settings": {

                "udp": true,

                "clients": [{

                    "id": "'$uuid'",

                    "level": 0,

                    "alterId": 4

                }]

            },

            "streamSettings": {

                "network": "kcp",

                "kcpSettings": {

                    "header": {

                        "type": "utp"

                    }

                }

            }

        }'

    fi

    mkdir -p ${install_dir:=/usr/local/v2ray}

    echo $echo_E_arg '

    {

        "log" : {

            "loglevel": "none"

        },

        "inbounds": ['"$in_networks"'],

        "outbounds": [{

            "protocol": "freedom"

        }]

    }

    ' >"$install_dir/v2ray.json"

}

GetAbi() {

    machine=`uname -m`

    #mips[...] use 'le' version

    if echo "$machine"|grep -q 'mips64'; then

        machine='mips64le'

    elif echo "$machine"|grep -q 'mips'; then

        machine='mipsle'

    elif echo "$machine"|grep -Eq 'i686|i386'; then

        machine='32'

    elif echo "$machine"|grep -Eq 'armv7|armv6'; then

        machine='arm'

    elif echo "$machine"|grep -Eq 'armv8|aarch64'; then

        machine='arm64'

    else

        machine='64'

    fi

}

#Install v2ray & v2ctl from github.

InstallV2ray_From_Coding() {

    version=`$download_tool_cmd - https://api.github.com/repos/v2ray/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4 | grep '^v'`

    $download_tool_cmd v2ray.zip https://github.com/v2ray/v2ray-core/releases/download/${version:-v4.21.3}/v2ray-linux-${machine}.zip || Error "v2ray.zip download failed."

    unzip -q v2ray.zip

    rm -f v2ray.zip

}

#Install v2ray & v2ctl from coding.

InstallV2ray_From_Github() {

    $download_tool_cmd v2ray https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/v2/$machine/v2ray && $download_tool_cmd v2ctl https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/v2/$machine/v2ctl

    [ $? != 0 ] && Error "v2ray or v2ctl core download failed."

}

#Install v2ray & v2ctl from tencent.

InstallV2ray_From_Tencent() {

    $download_tool_cmd v2ray https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/v2/$machine/v2ray && $download_tool_cmd v2ctl https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/v2/$machine/v2ctl

    [ $? != 0 ] && Error "v2ray or v2ctl core download failed."

}

#install v2ray v2ctl v2ray.init v2ray.service Caddy

InstallFiles() {

    GetAbi

    cd "$install_dir"

    #install v2ray & v2ctl

    case $v2rayCoreSource in

        1) InstallV2ray_From_Coding;;

        2) InstallV2ray_From_Tencent;;

        *) InstallV2ray_From_Github;;

    esac

    $download_tool_cmd v2ray.init https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/v2/v2ray.init || Error "v2ray.init download failed."

    sed -i "s~\[v2ray_install_dir\]~$install_dir~g" v2ray.init

    sed -i "s~#!/bin/bash~#!$SHELL~" v2ray.init

    ln -s "$install_dir/v2ray.init" /etc/init.d/v2ray

    chmod -R 777 "$install_dir" /etc/init.d/v2ray

    if type systemctl; then

        $download_tool_cmd /etc/systemd/system/v2ray.service https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/v2/v2ray.service || Error "v2ray.service download failed."

        chmod 777 /etc/systemd/system/v2ray.service

        sed -i "s~\[v2ray_install_dir\]~$install_dir~g"  /etc/systemd/system/v2ray.service

        systemctl daemon-reload

    fi

    #install Caddy

    if [ -n "$tls_domain" ]; then

        $download_tool_cmd Caddy https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/Caddy/${machine} || Error "Caddy download failed."

        $download_tool_cmd Caddy.json https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/Caddy/Caddy.json || Error "Caddy.json download failed."

        $download_tool_cmd /etc/init.d/Caddy https://wuyi-1251424646.cos.ap-beijing-1.myqcloud.com/Caddy/Caddy.init || Error "Caddy.init download failed."

        chmod 777 Caddy* /etc/init.d/Caddy

        sed -i "s~\[domain\]~$tls_domain~g" Caddy.json

        sed -i "s~\[toPort\]~$ws_server_port~g" Caddy.json

        sed -i "s~\[Caddy_install_dir\]~$install_dir~g" /etc/init.d/Caddy

        sed -i "s~#!/bin/bash~#!$SHELL~" /etc/init.d/Caddy

        if false; then  #type systemctl; then

            $download_tool_cmd /etc/systemd/system/Caddy.service http://pros.cutebi.xyz:666/v2ray/Caddy/Caddy.service || Error "Caddy.service download failed."

            chmod 777 /etc/systemd/system/Caddy.service

            sed -i "s~\[Caddy_install_dir\]~$install_dir~g"  /etc/systemd/system/Caddy.service

            systemctl daemon-reload

        fi

    fi

}

#install initialization

InstallInit() {

    echo -n "make a update?[n]: "

    read update

    PM=`which apt-get || which yum`

    echo "$update"|grep -qi 'y' && $PM -y update

    $PM -y install curl wget unzip

    type curl && download_tool_cmd='curl -L -ko' || download_tool_cmd='wget --no-check-certificate -O'

    getip_urls="http://ipinfo.io/ip http://myip.dnsomatic.com/ http://ip.sb/"

    for url in $getip_urls; do

        ip=`$download_tool_cmd - "$url"`

    done

}

outputVmessLink() {

    [ -z "$ip" ] && return

    [ -n "$http_server_port" ] && echo -n $echo_e_arg "\rhttp: vmess://" && echo -n $echo_E_arg '{"add": "'$ip'", "port": '$http_server_port', "aid": "4", "host": "wapzt.189.cn", "id": "'$uuid'", "net": "tcp", "path": "/", "ps": "http_'$ip:$http_server_port'", "tls": "", "type": "http", "v": "2"}'|base64 -w 0 && echo

    [ -n "$ws_server_port" ] && echo -n $echo_e_arg "\rws: vmess://" && echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$ws_server_port'", "aid": "4", "host": "wapzt.189.cn", "id": "'$uuid'", "net": "ws", "path": "'$ws_path'", "ps": "ws_'$ip:$ws_server_port'", "tls": "", "type": "none", "v": "2"}'|base64 -w 0 && echo

    [ -n "$tls_domain" ] && echo -n $echo_e_arg "\rws_tls: vmess://" && echo -n $echo_E_arg '{"add": "'$ip'", "port": "443", "aid": "4", "host": "'$tls_domain'", "id": "'$uuid'", "net": "ws", "path": "'$ws_path'", "ps": "ws_tls_'$ip':443", "tls": "tls", "type": "none", "v": "2"}'|base64 -w 0 && echo

    [ -n "$mkcp_server_port" ] && echo -n $echo_e_arg "\rmkcp: vmess://" && echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$mkcp_server_port'", "aid": "4", "host": "", "id": "'$uuid'", "net": "kcp", "path": "", "ps": "mkcp_'$ip:$mkcp_server_port'", "tls": "", "type": "utp", "v": "2"}'|base64 -w 0 && echo

}

Install() {

    Config

    Delete >/dev/null 2>&1

    InstallInit

    InstallFiles

    "$install_dir/v2ray.init" start|grep -q FAILED && Error "v2ray install failed."

    echo $echo_e_arg \

        "\033[44;37mv2rayinstall success.\033[0;34m

        \r    http server port:\033[35G${http_server_port:-NULL}

        \r    webSocket server port:\033[35G${ws_server_port:-NULL}`[ -n \"$tls_domain\" ] && echo \ tls: 443`

        \r    mKCP server port:\033[35G${mkcp_server_port:-NULL} type: utp

        \r    uuid:\033[35G$uuid

        \r    alterId:\033[35G4

        \r`[ -f /etc/init.d/v2ray ] && /etc/init.d/v2ray usage || \"$install_dir/v2ray.init\" usage`

        \033[44;37m`outputVmessLink`\033[0m"

}

Uninstall() {

    echo -n "Please input v2ray install directory(default is /usr/local/v2ray): "

    read install_dir

    Delete >/dev/null 2>&1 && \

        echo $echo_e_arg "\n\033[44;37mv2ray uninstall success.\033[0m" || \

        echo $echo_e_arg "\n\033[41;37mv2ray uninstall failed.\033[0m"

}

#script initialization

ScriptInit() {

    emulate bash 2>/dev/null #zsh emulation mode

    if echo -e ''|grep -q 'e'; then

        echo_e_arg=''

        echo_E_arg=''

    else

        echo_e_arg='-e'

        echo_E_arg='-E'

    fi

}

ScriptInit

echo $*|grep -qi uninstall && Uninstall || Install
