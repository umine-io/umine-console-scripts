#!/bin/bash

RCOUNTER="0"

PMAC=$(macchanger -s eth0 | grep 'Permanent MAC')
PMAC=$(echo ${PMAC:15} | cut -f1 -d' ')

RKEY=${RANDOM}

if [ x"${PMAC}" = "x" ]; then
    PMAC=$(</sys/class/net/eth0/address)
fi

HAVE_HWDOG="0"
if [ -c "/dev/ttyUSB0" ]; then
    HAVE_HWDOG="1"
fi

MINER="ETH"

if [ x"$1" != "x" ]; then
    MINER="$1"
fi

while true; do
    sleep 60

    UPTIME=$(</proc/uptime)
    UPTIME=${UPTIME%%.*}

    IPADDR=$(ifconfig eth0 | grep inet | head -n 1 | cut -d \t -f 2 | cut -d " " -f 2)
    IPADDR=$(echo ${IPADDR:5})

    if [ x"${MINER}" = x"ZEC" ]; then
        rm -f /tmp/zec-report.json
        wget -T 15 -O /tmp/zec-report.json http://127.0.0.1:42000/getstat
        REPORT_DATA_ARG1=""
        REPORT_DATA_ARG2=""

        if [ -f "/tmp/zec-report.json" ]; then
            CMCR=$(cat /tmp/zec-report.json | jq ".result[].speed_sps" | awk '{s+=$1} END {printf "%.0f\n", s}')

            if [ x"${CMCR}" != "x" ]; then
               if [ ${CMCR} -ge 1 ]; then
                   RCOUNTER="0"
               else
                   RCOUNTER=$(expr ${RCOUNTER} + 1)
               fi
            else
                RCOUNTER=$(expr ${RCOUNTER} + 1)
            fi
            REPORT_DATA_ARG1="-F"
            REPORT_DATA_ARG2="html=@/tmp/zec-report.json"
        else
            RCOUNTER=$(expr ${RCOUNTER} + 1)
        fi

    elif [ x"${MINER}" = x"ETH" ]; then
        rm -f /tmp/claymore-report.html
        wget -T 15 -O /tmp/claymore-report.html http://127.0.0.1:3333  
        REPORT_DATA_ARG1=""
        REPORT_DATA_ARG2=""

        if [ -f /tmp/claymore-report.html ]; then
            CMCR=$(html2text /tmp/claymore-report.html | grep 'Total Speed' | tail -n1)
            CMCR=$(echo ${CMCR:19} | cut -f1 -d'.')

            if [ x"${CMCR}" != "x" ]; then
               if [ ${CMCR} -ge 1 ]; then
                   RCOUNTER="0"
               else
                   RCOUNTER=$(expr ${RCOUNTER} + 1)
               fi
            else
                RCOUNTER=$(expr ${RCOUNTER} + 1)
            fi
            REPORT_DATA_ARG1="-F"
            REPORT_DATA_ARG2="html=@/tmp/claymore-report.html"

        else
            RCOUNTER=$(expr ${RCOUNTER} + 1)
        fi
    else
        REPORT_DATA_ARG1=""
        REPORT_DATA_ARG2=""
    fi

    SSHSTATE=$(ps -A | egrep ssh$ | wc -l)

    CRESULT=$(curl -F "type=${MINER}" -F "mac=${PMAC}" -F "ipaddr=${IPADDR}" -F "uptime=${UPTIME}" \
        -F "rkey=${RKEY}" -F "hwdog=${HAVE_HWDOG}" -F "sshstate=${SSHSTATE}" ${REPORT_DATA_ARG1} \
        ${REPORT_DATA_ARG2} http://test.umine.io/api/v1/client_logs)

    IFS="#"

    CRKEY=""
    REMOTECMD=""
    RPORT="20000"
    RHOST="45.77.173.150"

    for CM in ${CRESULT}; do
        case "${CM}" in
            "rkey="*)
                CRKEY="${CM:5}"
                ;;
            "reboot")
                REMOTECMD="reboot"
                ;;
            "remoteopen")
                REMOTECMD="remoteopen"
                ;;
            "remoteclose")
                REMOTECMD="remoteclose"
                ;;
            "rport="*)
                RPORT="${CM:6}"
                ;;
            "rhost="*)
                RHOST="${CM:6}"
                ;;
            *)
                ;;
        esac
    done

    if [ x"${CRKEY}" = x"${RKEY}" ]; then
        case "${REMOTECMD}" in
            "reboot")
                sudo reboot
                ;;
            "remoteopen")
                killall -9 ssh
                ssh -o StrictHostKeyChecking=no -NR ${RPORT}:127.0.0.1:22 tunneluser@${RHOST} >/dev/null 2>/dev/null &
                ;;
            "remoteclose")
                killall -9 ssh
                ;;
            *)
                ;;
        esac
    fi

    if [ ${RCOUNTER} -gt 3 ]; then
        if [ x"${HAVE_HWDOG}" = x"1"  ]; then
            sync
            sleep 3
            echo -en '\xFF' >/dev/ttyUSB0
            sleep 3
            sudo reboot
        else
            sudo reboot
        fi
    fi
done
