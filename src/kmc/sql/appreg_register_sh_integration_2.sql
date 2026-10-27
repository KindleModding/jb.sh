PRAGMA busy_timeout = 5000;
BEGIN;
INSERT INTO properties (handlerId, name, value) VALUES ('tech.hackerdude.shell_integration.extractor', 'lib', '/usr/lib/ccat/sh_integration_extractor.so');
COMMIT;