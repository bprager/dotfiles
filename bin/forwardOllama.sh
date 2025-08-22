#!/usr/bin/env bash
socat -d -d TCP-LISTEN:11434,fork TCP:192.168.1.3:11434
