PRAGMA busy_timeout = 5000;
BEGIN;
UPDATE properties SET value="false" WHERE name="adunit.viewable";
COMMIT;