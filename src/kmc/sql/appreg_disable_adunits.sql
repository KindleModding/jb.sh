BEGIN;
UPDATE properties SET value="false" WHERE name="adunit.viewable";
COMMIT;