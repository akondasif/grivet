#!/usr/bin/env bash

set -e

export DOCKER_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo type "export DOCKER_IP=$DOCKER_IP"