#!/bin/bash
od -t x1 -v -w1 < $1 | awk '{ print $2 }'
