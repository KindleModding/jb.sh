BEGIN;

UPDATE properties SET value='/bin/sh /var/local/kmc/rootless_menu.sh' WHERE handlerId='com.lab126.helpapp' AND name='command';

COMMIT;