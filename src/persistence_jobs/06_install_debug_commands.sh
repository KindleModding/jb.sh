#!/bin/sh

for JSON_PATH in "/app/kpp_app_cmds.json" "/usr/share/app/kpp_sys_cmds.json" "/usr/share/webkit-1.0/pillow/debug_cmds.json"; do
    if [ -f "$JSON_PATH" ] ; then
        if ! grep -q "logThis.sh" "$JSON_PATH" ; then
            log "Patching debug commands for $JSON_PATH"
            sed -e '/^{/a\' -e '    ";log" : "/usr/bin/logThis.sh",' -i "$JSON_PATH"
        fi
    fi
done