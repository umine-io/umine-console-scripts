#!/bin/bash

export PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin

export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100

sleep 10

touch /tmp/mining-session.tmp

EWAL="0x64904acd8ebf8bfd986c7b0f8c8d96b8d760a62e"
email="asdf@asdf.com"
pool0="eth-asia1.nanopool.org:9999"
pool1="eth-hk.dwarfpool.com:8008"

re='^[0-9]+$'

num_amd_cards=`lspci | grep -i amd | wc -l`
num_nv_dev=$(lspci | grep -i NVIDIA | wc -l)
extra_args=""

if [ "$num_amd_cards" -eq "0" ]; then
    echo "No AMD card detected, using nVIDIA cards.";
    #./oc.sh
    export GPU_FORCE_64BIT_PTR=0
else
    echo "AMD cards detected.";
    extra_args="${extra_args} -lidag 1"
    if [ "${num_nv_dev}" -eq "0" ]; then
        extra_args="${extra_args} -etha 2"
    fi
fi

NETRETRYCOUNT=0

while [[ ! ${ip_part3} =~ ${re} ]]; do
    if [ "${NETRETRYCOUNT}" -gt 300 ]; then
        echo "Retry too many times for DHCP, reboot...."
        reboot
    fi

    if [ "${NETRETRYCOUNT}" -gt 30 ]; then
        echo "Failed to DHCP for waiting 30 times, retry...."
        killall -9 dhclient
        dhclient eth0
    fi

    ip_part3=`ifconfig eth0 | grep inet | head -n 1 | cut -d \t -f 2 | cut -d " " -f 2 | cut -d "." -f 3`
    ip_part4=`ifconfig eth0 | grep inet | head -n 1 | cut -d \t -f 2 | cut -d " " -f 2 | cut -d "." -f 4`
    echo "Getting ip address, wait 1 sec!"
    sleep 1
    NETRETRYCOUNT=$(expr ${NETRETRYCOUNT} + 1)
done

PMAC=$(macchanger -s eth0 | grep 'Permanent MAC')
if [ x"${PMAC}" != "x" ]; then
    PMAC=$(echo ${PMAC:15} | cut -f1 -d' ')
    PMAC_F4=$(echo ${PMAC} | cut -f4 -d':')
    PMAC_F5=$(echo ${PMAC} | cut -f5 -d':')
    PMAC_F6=$(echo ${PMAC} | cut -f6 -d':')
else
    PMAC=$(</sys/class/net/eth0/address)

    if [ x"${PMAC}" != "x" ]; then
        PMAC_F4=$(echo ${PMAC} | cut -f4 -d':')
        PMAC_F5=$(echo ${PMAC} | cut -f5 -d':')
        PMAC_F6=$(echo ${PMAC} | cut -f6 -d':')
    else
        PMAC_F4="xx"
        PMAC_F5="xx"
        PMAC_F6="xx"
    fi
fi

machine_id=`hostname`-"${ip_part3}.${ip_part4}"-"${PMAC_F4}${PMAC_F5}${PMAC_F6}"

echo $machine_id

source /media/storage/ewal.txt

MINER="ETH"

if [ x"${EMAIL}" != "x" ]; then
    email="${EMAIL}"
fi

if [ x"${EWORKER}" != "x" ]; then
    extra_args="${extra_args} -eworker ${EWORKER}"
else
    EWAL=$(echo "${EWAL}.${machine_id}/${email}")
fi

if [ x"${EPOOL}" != "x" ]; then
    pool0="${EPOOL}"

    if [ x"${EPOOLPORT}" != "x"]; then
        poolport="${EPOOLPORT}"
    fi
fi

source /media/storage/customminer.sh

if [ x"${CUSTOMMINER}" != x"1" ]; then

    case "${EWAL}" in
        "0x"* )
            echo "ETH address detected, using claymore miner."
            ;;
        "t1"* | "z"* )
            echo "ZEC address detected, using zec miner."
            MINER="ZEC"
            if [ x"${EPOOL}" = "x" ]; then
                pool0="zec-asia1.nanopool.org"
                if [ x"${EPOOLPORT}" = "x"]; then
                    poolport="6666"
                fi
            fi
            ;;
        * )
            echo "Unknown address ${EWAL}, please check if your wallet address is correct."
            read
            exit 127
            ;;
    esac

    /opt/umine_linux/reporter.sh "${MINER}" >/dev/null 2>/dev/null &

    case "${MINER}" in
        "ZEC" )
            /home/umine/mining/zec/miner --server ${pool0} --port ${poolport} --user ${EWAL} --pass z --api
            ;;
        * )
            /home/umine/mining/claymore/ethdcrminer64 -dbg -1 -epool ${pool0} -ewal ${EWAL} -epsw x -mode 1 -r -1 ${extra_args}
            ;;
    esac

    echo "Mining program exited, reboot...."
    sleep 10
    sudo reboot

else
    /opt/umine_linux/reporter.sh "CUSTOM" >/dev/null 2>/dev/null &
fi

