#!/bin/bash

    if ! grep 127.0.0.1 /etc/resolv.conf -q
    then
            echo "No existe 127.0.0.1 en /etc/resolv.conf"
            cp /etc/resolv.conf /etc/resolv.conf.old
            echo "nameserver 127.0.0.1" > /etc/resolv.conf
            cat /etc/resolv.conf.old >> /etc/resolv.conf
    fi

    if ! grep api.melicloud.com /etc/hosts -q
    then
            echo "172.16.1.80 api.melicloud.com" >> /etc/hosts

    fi
