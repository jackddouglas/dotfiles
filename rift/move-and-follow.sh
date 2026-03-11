#!/bin/sh
rift-cli execute workspace move-window "$1"
rift-cli execute workspace switch "$1"
