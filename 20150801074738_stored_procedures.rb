class StoredProcedures < ActiveRecord::Migration
	# rake db:migrate:redo VERSION=20150801074738 RAILS_ENV=test
  def self.up
    execute <<-__EOI

CREATE TYPE compliance_sum AS (score INT, conflicts INT);



CREATE OR REPLACE FUNCTION subject_compliance(wanted INT, stored INT) RETURNS INT AS $$
BEGIN
	RETURN CASE wanted
		WHEN -1 THEN
			CASE stored
				WHEN -1 THEN 2
				WHEN 0 THEN 1
				WHEN 1 THEN 0
				WHEN 2 THEN -1 END
		WHEN 0 THEN
			CASE stored
				WHEN -1 THEN 0
				WHEN 0 THEN 2
				WHEN 1 THEN 1
				WHEN 2 THEN -1 END
		WHEN 1 THEN
			CASE stored
				WHEN -1 THEN 0
				WHEN 0 THEN 1
				WHEN 1 THEN 2
				WHEN 2 THEN 2 END
		WHEN 2 THEN
			CASE stored
				WHEN -1 THEN -2
				WHEN 0 THEN -1
				WHEN 1 THEN 1
				WHEN 2 THEN 2 END
	END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION my_gender_compliance(my_gender CHAR(1), stored CHAR(1)) RETURNS INT AS $$
BEGIN
	RETURN CASE my_gender
		WHEN '-' THEN
			CASE stored
				WHEN '-' THEN 1
				ELSE -1 END
		WHEN 'm' THEN
			CASE stored
				WHEN 'm' THEN 1
				WHEN '-' THEN 0
				WHEN 'w' THEN -5 END
		WHEN 'w' THEN
			CASE stored
				WHEN 'w' THEN 1
				WHEN '-' THEN 0
				WHEN 'm' THEN -5 END
	END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION wanted_gender_compliance(wanted CHAR(1), stored CHAR(1)) RETURNS INT AS $$
BEGIN
	RETURN CASE wanted
		WHEN '-' THEN
			CASE stored
				WHEN '-' THEN 1
				ELSE 0 END
		WHEN 'm' THEN
			CASE stored
				WHEN 'm' THEN 1
				WHEN '-' THEN -1
				WHEN 'w' THEN -5 END
		WHEN 'w' THEN
			CASE stored
				WHEN 'w' THEN 1
				WHEN '-' THEN -1
				WHEN 'm' THEN -5 END
	END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calc_compliance_sum(arr1 INT[], ages INT[]) RETURNS compliance_sum AS $$
DECLARE
  r compliance_sum;
	item INT;
BEGIN
	r.score=0;r.conflicts=0;

   FOREACH item IN ARRAY arr1 LOOP
			r.score = r.score + item;
		  r.conflicts = r.conflicts +
				CASE
					WHEN item < 0 THEN item
					ELSE 0
				END;
   END LOOP;

   FOREACH item IN ARRAY ages LOOP
		  r.conflicts = r.conflicts +
				CASE
					WHEN item < 0 THEN item
					ELSE 0
				END;
   END LOOP;

  RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "json_object_update_key"(
  "json"          json,
  "key_to_set"    TEXT,
  "value_to_set"  anyelement
)
  RETURNS json
  LANGUAGE sql
  IMMUTABLE
  STRICT
AS $function$
SELECT CASE
  WHEN ("json" -> "key_to_set") IS NULL THEN "json"
  ELSE (SELECT concat('{', string_agg(to_json("key") || ':' || "value", ','), '}')
          FROM (SELECT *
                  FROM json_each("json")
                 WHERE "key" <> "key_to_set"
                 UNION ALL
                SELECT "key_to_set", to_json("value_to_set")) AS "fields")::json
END
$function$;

    __EOI
	end

	def self.down
		execute <<-__EOI

		DROP FUNCTION IF EXISTS  calc_compliance_sum(INT[], INT[]);
		DROP FUNCTION IF EXISTS  calc_compliance_sum(INT[]);
		DROP TYPE IF EXISTS compliance_sum;

		__EOI

	end
end
