BEGIN;
DELETE FROM properties WHERE handlerId='org.kindlemodding.persistence_launcher';
DELETE FROM mimetypes WHERE ext='run_persistence';
DELETE FROM extenstions WHERE ext='run_persistence';
DELETE FROM handlerIds WHERE handlerId='org.kindlemodding.persistence_launcher';
DELETE FROM associations WHERE handlerId='org.kindlemodding.persistence_launcher';

INSERT INTO mimetypes (ext, mimetype) VALUES ('run_persistence', 'MT:kindlemodding/run_persistence');
INSERT INTO extenstions (ext, mimetype) VALUES ('run_persistence', 'MT:kindlemodding/run_persistence');

INSERT INTO associations (interface, handlerId, contentId, defaultAssoc) VALUES ('extractor', 'com.lab126.generic.extractor', 'GL:*.run_persistence', 'true');

INSERT INTO handlerIds (handlerId) VALUES ('org.kindlemodding.persistence_launcher');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.persistence_launcher', 'extend-start', 'Y');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.persistence_launcher', 'unloadPolicy', 'unloadOnPause');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.persistence_launcher', 'maxGoTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.persistence_launcher', 'maxPauseTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.persistence_launcher', 'maxUnloadTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.persistence_launcher', 'maxLoadTime', '600');
INSERT INTO properties (handlerId, name, value) VALUES ('org.kindlemodding.persistence_launcher', 'command', '/bin/sh /var/local/kmc/persistence/run_persistence.sh');

INSERT INTO associations (interface, handlerId, contentId, defaultAssoc) VALUES ('application', 'org.kindlemodding.persistence_launcher', 'MT:kindlemodding/run_persistence', 'true');


COMMIT;