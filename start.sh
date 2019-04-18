#!/bin/bash

# set correct SSL library (Needed on some debians)
TURBO_LIBSSL=/usr/lib/x86_64-linux-gnu/libssl.so.1.0.2 luajit server.lua
