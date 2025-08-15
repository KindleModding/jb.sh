#!/bin/sh

echo "Monolithic jb.sh Builder"
echo "Created by HackerDude"
echo ""

echo $LOGGING
LOG="/dev/null"
if [ $LOGGING = "true" ]; then
    echo "Logging to stdout."
    LOG=/proc/self/fd/1 # Cursed, I know
fi