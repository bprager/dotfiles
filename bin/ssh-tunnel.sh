#!/usr/bin/env bash
echo "establishing ssh jump host as ${USER} on fenrir port 2222 ..."
ssh -R 2222:localhost:22 ${USER}@fenrir
