BEGIN;
DELETE FROM properties WHERE handlerId='org.kindlemodding.emergency_launcher';
DELETE FROM mimetypes WHERE ext='run_emergency';
DELETE FROM extenstions WHERE ext='run_emergency';
DELETE FROM handlerIds WHERE handlerId='org.kindlemodding.emergency_launcher';
DELETE FROM associations WHERE handlerId='org.kindlemodding.emergency_launcher';

INSERT INTO mimetypes (ext, mimetype) VALUES ('run_emergency', 'MT:kindlemodding/run_emergency');
INSERT INTO extenstions (ext, mimetype) VALUES ('run_emergency', 'MT:kindlemodding/run_emergency');

INSERT INTO associations (interface, handlerId, contentId, defaultAssoc) VALUES ('extractor', 'com.lab126.generic.extractor', 'GL:*.run_emergency', 'true');

INSERT INTO handlerIds (handlerId) VALUES ('org.kindlemodding.emergency_launcher');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.emergency_launcher', 'extend-start', 'Y');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.emergency_launcher', 'unloadPolicy', 'unloadOnPause');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.emergency_launcher', 'maxGoTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.emergency_launcher', 'maxPauseTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.emergency_launcher', 'maxUnloadTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.emergency_launcher', 'maxLoadTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.emergency_launcher', 'command', '/bin/sh /mnt/us/emergency.sh');

INSERT INTO associations (interface, handlerId, contentId, defaultAssoc) VALUES ('application', 'org.kindlemodding.emergency_launcher', 'MT:kindlemodding/run_emergency', 'true');


COMMIT;