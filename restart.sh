#!/bin/bash

if [ -f "cname.pid" ]; then
	kill `cat cname.pid`
fi
