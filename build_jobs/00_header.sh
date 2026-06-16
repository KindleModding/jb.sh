#!/bin/sh

echo "Monolithic jb.sh Builder"
echo "Created by HackerDude"
echo ""

LOG="/dev/null"
if [ $LOGGING -eq 1 ]; then
    echo "Logging to stdout."
    LOG=/proc/self/fd/1 # Cursed, I know
fi