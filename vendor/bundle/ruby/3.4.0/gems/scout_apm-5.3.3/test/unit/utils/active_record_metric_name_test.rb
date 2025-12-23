require 'test_helper'
require 'scout_apm/utils/active_record_metric_name'


class ActiveRecordMetricNameTest < Minitest::Test
  # This is a bug report from Андрей Филиппов <tmn.sun@gmail.com>
  # The code that triggered the bug was: ActiveRecord::Base.connection.execute("%some sql%", :skip_logging)
  def test_symbol_name
    sql = "SELECT * FROM users /*application:Testapp,controller:public,action:index*/"
    name = :skip_logging

    mn = ScoutApm::Utils::ActiveRecordMetricName.new(sql, name)
    assert_equal "User/find", mn.to_s
  end

  def test_postgres_column_lookup
    sql = <<-EOF
    SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, r.rngsubtype, t.typtype, t.typbasetype
                  FROM pg_type as t
                  LEFT JOIN pg_range as r ON oid = rngtypid
                  WHERE
                    t.typname IN ('int2', 'int4', 'int8', 'oid', 'float4', 'float8', 'text', 'varchar', 'char', 'name', 'bpchar', 'bool', 'bit', 'varbit', 'timestamptz', 'date', 'time', 'money', 'bytea', 'point', 'hstore', 'json', 'jsonb', 'cidr', 'inet', 'uuid', 'xml', 'tsvector', 'macaddr', 'citext', 'ltree', 'interval', 'path', 'line', 'polygon', 'circle', 'lseg', 'box', 'timestamp', 'numeric')
                    OR t.typtype IN ('r', 'e', 'd')
                    OR t.typinput::varchar = 'array_in'
                    OR t.typelem != 0
    EOF

    name = "SCHEMA"

    mn = ScoutApm::Utils::ActiveRecordMetricName.new(sql, name)
    assert_equal "SQL/other", mn.to_s
  end


  def test_user_find
    sql = %q|SELECT "users".* FROM "users" /*application:Testapp,controller:public,action:index*/|
    name = "User Load"

    mn = ScoutApm::Utils::ActiveRecordMetricName.new(sql, name)
    assert_equal "User/find", mn.to_s
  end

  def test_without_name
    sql = %q|SELECT "users".* FROM "users" /*application:Testapp,controller:public,action:index*/|
    name = nil

    mn = ScoutApm::Utils::ActiveRecordMetricName.new(sql, name)
    assert_equal "User/find", mn.to_s
  end

  def test_with_sql_name
    sql = %q|INSERT INTO "users" VALUES (1,2,3)|
    name = "SQL"

    mn = ScoutApm::Utils::ActiveRecordMetricName.new(sql, name)
    assert_equal "User/create", mn.to_s
  end

  def test_with_custom_name
    sql = %q|SELECT "users".* FROM "users" /*application:Testapp,controller:public,action:index*/|
    name = "A whole sentance describing what's what"

    mn = ScoutApm::Utils::ActiveRecordMetricName.new(sql, name)
    assert_equal "User/find", mn.to_s
  end

  def test_begin_statement
    mn = ScoutApm::Utils::ActiveRecordMetricName.new("BEGIN", nil)
    assert_equal "SQL/begin", mn.to_s
  end

  def test_commit
    mn = ScoutApm::Utils::ActiveRecordMetricName.new("COMMIT", nil)
    assert_equal "SQL/commit", mn.to_s
  end


  # Regex test cases, pass these in w/ "SQL" as the AR provided name field
  [
    ["LoginRecord/save",     'UPDATE "login_record" SET "updated_at" = ? WHERE "login_record"."login_record_id" = ?'],
    ["UserAccount/save",     'UPDATE "user_account" SET "last_activity" = ? WHERE "user_account"."user_account_id" = ?'],
    ["Membership/save",      'UPDATE "membership" SET "updated_at" = ? WHERE "membership"."membership_id" = ?'],
    ["Membership/save",      'UPDATE "membership" SET "updated_by" = ? WHERE "membership"."membership_id" = ?'],
    ["Project/find",         'SELECT "project".project_id FROM "project" INNER JOIN "membership" ON "project"."project_id" = "membership"."project_id" WHERE "membership"."user_account_id" = ?'],
    ["Entity/count",         'SELECT COUNT(*) FROM "entity" WHERE "entity"."entity_id" IN (?)'],
    ["EntityEventStep/find", 'SELECT entity_event_step.entity_id, entity_event_step.event_step_id, event_step.event_id FROM entity_event_step INNER JOIN event_step ON event_step.event_step_id = entity_event_step.event_step_id WHERE event_step.event_id in (?) AND entity_event_step.entity_id in (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'],
    ["CustomField/count",    'SELECT COUNT(*) FROM "custom_field" WHERE "custom_field"."project_id" = ? AND "custom_field"."enabled" = ?'],
    ["Event/find",           'SELECT MAX("events"."updated_at") AS max_id FROM "events" LEFT OUTER JOIN "configurations" ON "configurations"."event_id" = "events"."id" WHERE (configurations.date >= ?)'],
    ["Sponsorship/find",     '  SELECT   "sponsorships"."id" AS t0_r0, "sponsorships"."event_id" AS t0_r1, "sponsorships"."name" AS t0_r2, "sponsorships"."position" AS t0_r3, "sponsorships"."created_at" AS t0_r4, "sponsorships"."updated_at" AS t0_r5, "sponsorships"."display_name" AS t0_r6, "sponsorships"."home_page_id" AS t0_r7, "sponsors"."id" AS t1_r0, "sponsors"."name" AS t1_r1, "sponsors"."url" AS t1_r2, "sponsors"."created_at" AS t1_r3, "sponsors"."updated_at" AS t1_r4, "assets"."id" AS t2_r0, "assets"."type" AS t2_r1, "assets"."assetable_id" AS t2_r2, "assets"."assetable_type" AS t2_r3, "assets"."attachment_file_name" AS t2_r4, "assets"."attachment_content_type" AS t2_r5, "assets"."attachment_file_size" AS t2_r6, "assets"."attachment_updated_at" AS t2_r7, "assets"."created_at" AS t2_r8, "assets"."updated_at" AS t2_r9 FROM    "sponsorships" LEFT OUTER JOIN "ranks" ON "ranks"."sponsorship_id" = "sponsorships"."id" LEFT OUTER JOIN "sponsors" ON "sponsors"."id" = "ranks"."sponsor_id" LEFT OUTER JOIN "assets" ON "assets".'],
    ["MaxmindGeoliteCountry/find", 'SELECT country, country_code FROM maxmind_geolite_country WHERE start_ip_num <= ? AND ? <= end_ip_num'],
    ["Activity/find", 'SELECT `activities`.`id` FROM `activities` INNER JOIN `activity_attendees` ON `activity_attendees`.`activity_id` = `activities`.`id` AND `activity_attendees`.`deleted` = ? LEFT JOIN activity_recurrence_periods arp ON arp.activity_id = activities.id WHERE (activities.updated_at >= ?) AND ((activities.start_date between ? and ? and activities.all_day = ?) or (CAST(activities.start_date as Date) between ? and ? and activities.all_day = ?)) AND (activity_attendees.user_id IN (?)) AND (arp.id IS NULL)'],

    # Lower Case.
    # ["MaxmindGeoliteCountry#Select", 'select country, country_code from maxmind_geolite_country where start_ip_num <= ? and ? <= end_ip_num'],

    # No FROM clause (was clipped off)
    ["SQL/other", 'SELECT "events"."id" AS t0_r0, "events"."name" AS t0_r1, "events"."subdomain" AS t0_r2, "events"."created_at" AS t0_r3, "events"."updated_at" AS t0_r4, "events"."slug" AS t0_r5, "events"."domain" AS t0_r6, "events"."published" AS t0_r7, "events"."category" AS t0_r8, "events"."venue_id" AS t0_r9, "events"."bitly_url" AS t0_r10, "events"."shown_in_events_list" AS t0_r11, "venues"."id" AS t1_r0, "venues"."name" AS t1_r1, "venues"."capacity" AS t1_r2, "venues"."address" AS t1_r3, "venues"."parking_info" AS t1_r4, "venues"."manual_coordinates" AS t1_r5, "venues"."latitude" AS t1_r6, "venues"."longitude" AS t1_r7, "venues"."description" AS t1_r8, "venues"."created_at" AS t1_r9, "venues"."updated_at" AS t1_r10, "venue_translations"."id" AS t2_r0, "venue_translations"."venue_id" AS t2_r1, "venue_translations"."locale" AS t2_r2, "venue_translations"."created_at" AS t2_r3, "venue_translations"."updated_at" AS t2_r4, "venue_translations"."name" AS t2_r5, "venue_translations"."description" AS t2_r6'],

    # Stuff we don't care about in SQL
    ["SQL/other", 'SET SESSION statement_timeout = ?'],
    ["SQL/other", 'SHOW TIME ZONE'],

    # Empty strings, or invalid SQL
    ["SQL/other", ''],
    ["SQL/other", 'not sql at all!'],
  ].each_with_index do |(expected, sql), i|
    define_method :"test_regex_naming_#{i}" do
      actual = ScoutApm::Utils::ActiveRecordMetricName.new(sql, "SQL").to_s
      assert_equal expected, actual
    end
  end
end
