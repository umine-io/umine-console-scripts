#!/bin/bash

if [ -f "/media/storage/customoc.sh" ]; then
    source /media/storage/customoc.sh
fi

if [ x"${CUSTOMOC}" = x"1" ]; then
    exit 0
fi

NV_NUM=$(nvidia-smi -L | grep GPU | wc -l)
COUNT=0

while [ $COUNT -lt $NV_NUM ]; do
    XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUPowerMizerMode=1

    PNAME=$(nvidia-smi -i $COUNT -q | grep 'Product Name' | cut -f2 -d':')

    case "${PNAME}" in
        *"P106"*)
            echo "P106 detected on ${COUNT}."
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUGraphicsClockOffset[1]=80
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUMemoryTransferRateOffset[1]=800
            ;;

        *"P104"*)
            echo "P104 detected on ${COUNT}."
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUGraphicsClockOffset[1]=80
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUMemoryTransferRateOffset[1]=800
            ;;

        *"P102"*)
            echo "P102 detected on ${COUNT}."
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUGraphicsClockOffset[1]=80
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUMemoryTransferRateOffset[1]=800
            ;;

        *"GeForce GTX 1050"*)
            echo "GeForce GTX 1050 detected on ${COUNT}."
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUGraphicsClockOffset[2]=50
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUMemoryTransferRateOffset[2]=500
            ;;
        *)
            echo "Generic NV graphic card detected on ${COUNT}."
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUGraphicsClockOffset[3]=80
            XAUTHORITY=/var/lib/mdm/:0.Xauth nvidia-settings -a [gpu:$COUNT]/GPUMemoryTransferRateOffset[3]=800
            ;;
    esac

    COUNT=$(expr $COUNT + 1)
done

