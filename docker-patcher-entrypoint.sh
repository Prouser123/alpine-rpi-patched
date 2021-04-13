#!/bin/sh

apk add --no-cache bash

echo "Found argument: $1"

bash patcher.sh $1