#!/bin/bash

    if ! grep 127.0.0.1 /etc/resolv.conf -q
    then
            echo "127.0.0.1 not in /etc/resolv.conf"
            cp /etc/resolv.conf /etc/resolv.conf.old
            echo "nameserver 127.0.0.1" > /etc/resolv.conf
            cat /etc/resolv.conf.old >> /etc/resolv.conf
    fi
