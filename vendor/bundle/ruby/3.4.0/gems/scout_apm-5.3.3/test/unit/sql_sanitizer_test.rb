# frozen_string_literal: false

require 'test_helper'

module ScoutApm
  module Utils
    class SqlSanitizerTest < Minitest::Test
      # Too long, and we just bail out to prevent long running instrumentation
      def test_long_sql
        sql = " " * 1001
        assert_equal '', SqlSanitizer.new(sql).to_s
      end

      def test_postgres_simple_select_of_first
        skip "Broken on Ruby 1.8.7 because regular expressions do not support look-behinds" if RUBY_VERSION.start_with?("1.8.")

        sql = %q|SELECT  "users".* FROM "users"  ORDER BY "users"."id" ASC LIMIT 1|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT 1|, ss.to_s
      end

      def test_postgres_where
        sql = %q|SELECT "users".* FROM "users" WHERE "users"."name" = $1  [["name", "chris"]]|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|SELECT "users".* FROM "users" WHERE "users"."name" = ?|, ss.to_s
      end

      def test_postgres_strips_literals
        # Strip strings
        sql = %q|SELECT "users".* FROM "users" INNER JOIN "blogs" ON "blogs"."user_id" = "users"."id" WHERE (blogs.title = 'hello world')|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|SELECT "users".* FROM "users" INNER JOIN "blogs" ON "blogs"."user_id" = "users"."id" WHERE (blogs.title = ?)|, ss.to_s
      end

      def test_postgres_strips_after_where
        raw_sql = %q|SELECT DISTINCT ON (flagged_traces.metric_name) flagged_traces.metric_name, "flagged_traces"."trace_id", "flagged_traces"."trace_type", "flagged_traces"."trace_occurred_at", flagged_traces.details ->> 'uri' as uri, (flagged_traces.details ->> 'n_sum_millis')::float as potential_savings, (flagged_traces.details ->> 'n_count')::float as num_queries FROM "flagged_traces" WHERE "flagged_traces"."app_id" = 5 AND "flagged_traces"."trace_type" = 'Request' AND ("flagged_traces"."trace_occurred_at" BETWEEN '2019-04-17 12:28:00.000000' AND '2019-04-18 12:28:00.000000') AND "flagged_traces"."flag_type" = 'nplusone' ORDER BY "flagged_traces"."metric_name" ASC, potential_savings DESC|
        sanitized_sql = SqlSanitizer.new(raw_sql).tap { |it| it.database_engine = :postgres}
        expected_sql = %q|SELECT DISTINCT ON (flagged_traces.metric_name) flagged_traces.metric_name, "flagged_traces"."trace_id", "flagged_traces"."trace_type", "flagged_traces"."trace_occurred_at", flagged_traces.details ->> 'uri' as uri, (flagged_traces.details ->> 'n_sum_millis')::float as potential_savings, (flagged_traces.details ->> 'n_count')::float as num_queries FROM "flagged_traces" WHERE "flagged_traces"."app_id" = ? AND "flagged_traces"."trace_type" = ? AND ("flagged_traces"."trace_occurred_at" BETWEEN ? AND ?) AND "flagged_traces"."flag_type" = ? ORDER BY "flagged_traces"."metric_name" ASC, potential_savings DESC|
        assert_equal expected_sql, sanitized_sql.to_s
      end

      def test_postgres_strips_subquery_strings
        raw_sql = %q|"SELECT "orgs".* FROM "orgs" WHERE  "orgs"."name" = 'Scout' AND "orgs"."created_by_user_id" IN (SELECT "users"."id" FROM "users" WHERE (id > AVG(id)) AND "type" = 'USER' AND "created_at" BETWEEN '2019-04-17 12:28:00.000000' AND '2019-04-18 12:28:00.000000')"|
        sanitized_sql = SqlSanitizer.new(raw_sql).tap { |it| it.database_engine = :postgres}
        expected_sql = %q|"SELECT "orgs".* FROM "orgs" WHERE "orgs"."name" = ? AND "orgs"."created_by_user_id" IN (SELECT "users"."id" FROM "users" WHERE (id > AVG(id)) AND "type" = ? AND "created_at" BETWEEN ? AND ?)"|
        assert_equal expected_sql, sanitized_sql.to_s
      end

      def test_postgres_strips_integers
        # Strip integers
        sql = %q|SELECT "blogs".* FROM "blogs" WHERE (view_count > 10)|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|SELECT "blogs".* FROM "blogs" WHERE (view_count > ?)|, ss.to_s
      end

      def test_postgres_collapse_in_clause
        sql = %q|SELECT "blogs".* FROM "blogs" WHERE id IN (?, ?, ?)|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|SELECT "blogs".* FROM "blogs" WHERE id IN (?)|, ss.to_s
      end

      def test_postgres_collapse_in_clause_performacne
        sql = 'SELECT "users".* FROM "users" WHERE "users"."id" IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)'
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }

        assert_faster_than(0.01) do
          assert_equal %q|SELECT "users".* FROM "users" WHERE "users"."id" IN (?)|, ss.to_s
        end
      end

      def test_postgres_inner_join_subquery
        sql = %q{SELECT x AS y
         FROM t1 
         INNER JOIN (
           SELECT id,
           (ts_rank((to_tsvector('simple', coalesce("pg_search_documents"."content"::text, ''))), (to_tsquery('simple', 'xyz' || 'omg' || 'secret')), ?)) AS rank
           FROM t2
           WHERE name = 'literal') sub ON sub.id = t1.id WHERE age > 10}

        expected = %q{SELECT x AS y FROM t1 INNER JOIN ( SELECT id, (ts_rank((to_tsvector(?, coalesce("pg_search_documents"."content"::text, ?))), (to_tsquery(?, ? || ? || ?)), ?)) AS rank FROM t2 WHERE name = ?) sub ON sub.id = t1.id WHERE age > ?}
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }

        assert_equal expected, ss.to_s
      end

      def test_mysql_where
        sql = %q|SELECT `users`.* FROM `users` WHERE `users`.`name` = ?  [["name", "chris"]]|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }
        assert_equal %q|SELECT `users`.* FROM `users` WHERE `users`.`name` = ?|, ss.to_s
      end

      def test_mysql_limit
        skip "Broken on Ruby 1.8.7 because regular expressions do not support look-behinds" if RUBY_VERSION.start_with?("1.8.")

        sql = %q|SELECT  `blogs`.* FROM `blogs`  ORDER BY `blogs`.`id` ASC LIMIT 1|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }
        assert_equal %q|SELECT  `blogs`.* FROM `blogs`  ORDER BY `blogs`.`id` ASC LIMIT 1|, ss.to_s
      end

      def test_mysql_collpase_in_clause_performance
        sql = 'SELECT `users`.* FROM `users` WHERE `users`.`id` IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)'
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }

        assert_faster_than(0.01) do
          assert_equal %q|SELECT `users`.* FROM `users` WHERE `users`.`id` IN (?)|, ss.to_s
        end
      end

      def test_mysql_literals
        sql = %q|SELECT `blogs`.* FROM `blogs` WHERE (title = 'abc')|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }
        assert_equal %q|SELECT `blogs`.* FROM `blogs` WHERE (title = ?)|, ss.to_s

        sql = %q|SELECT `blogs`.* FROM `blogs` WHERE (title = "abc")|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }
        assert_equal %q|SELECT `blogs`.* FROM `blogs` WHERE (title = ?)|, ss.to_s
      end

      def test_mysql_quotes
        sql = %q|INSERT INTO `users` VALUES ('foo', 'b\'ar')|
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }
        assert_equal %q|INSERT INTO `users` VALUES (?, ?)|, ss.to_s
      end

      def test_sqlserver_integers
        sql = "EXEC sp_executesql N'SELECT  [users].* FROM [users] WHERE (age > 50)  ORDER BY [users].[id] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY', N'@0 int', @0 = 10"
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :sqlserver }
        assert_equal "SELECT  [users].* FROM [users] WHERE (age > ?)  ORDER BY [users].[id] ASC OFFSET ? ROWS FETCH NEXT @0 ROWS ONLY?@0 int', @0 = ?", ss.to_s
      end

      def test_sqlserver_strings
        sql = "EXEC sp_executesql N'SELECT  [users].* FROM [users] WHERE first_name = N'john' AND last_name = N'doe' ORDER BY [users].[id] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY', N'@0 int', @0 = 10"
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :sqlserver }
        assert_equal "SELECT  [users].* FROM [users] WHERE first_name = N? AND last_name = N? ORDER BY [users].[id] ASC OFFSET ? ROWS FETCH NEXT @0 ROWS ONLY?@0 int', @0 = ?", ss.to_s
      end

      def test_sqlserver_strings_no_executesql
        sql = "EXEC Authenticate @username = N'abraham.lincoln', @password = N'somepassword!', @token = NULL, @app_name = N'Central Auth Service', @log_login = true, @ip_address = N'127.0.0.1', @external_type = NULL, @external_success = NULL"
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :sqlserver }
        assert_equal "EXEC Authenticate @username = N?, @password = N?, @token = NULL, @app_name = N?, @log_login = true, @ip_address = N?, @external_type = NULL, @external_success = NULL", ss.to_s
      end

      def test_sqlserver_in_clause
        sql = "EXEC sp_executesql N'SELECT  [users].* FROM [users] WHERE (id IN (1,2,3))  ORDER BY [users].[id] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY', N'@0 int', @0 = 10"
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :sqlserver }
        assert_equal "SELECT  [users].* FROM [users] WHERE (id IN (?))  ORDER BY [users].[id] ASC OFFSET ? ROWS FETCH NEXT @0 ROWS ONLY?@0 int', @0 = ?", ss.to_s
      end

      def test_scrubs_invalid_encoding
        skip "Ruby 1.8.7 has no concept of encoding" if RUBY_VERSION.start_with?("1.8.")

        sql = "SELECT `blogs`.* FROM `blogs` WHERE (title = 'a\255c')".force_encoding('UTF-8')
        assert_equal false, sql.valid_encoding?
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }
        assert_equal %q|SELECT `blogs`.* FROM `blogs` WHERE (title = 'a_c')|, ss.sql
        assert_equal %q|SELECT `blogs`.* FROM `blogs` WHERE (title = ?)|, ss.to_s
      end

      def test_set_columns
        sql = %q|UPDATE "mytable" SET "myfield" = 'fieldcontent', "countofthings" = 10 WHERE "user_id" = 10|

        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|UPDATE "mytable" SET "myfield" = ?, "countofthings" = ? WHERE "user_id" = ?|, ss.to_s
      end

      def test_postgres_multiline_sql
        sql = %q|
        SELECT "html_form_payloads".*
        FROM "html_form_payloads"
        INNER JOIN "leads" ON "leads"."payload_id" = "html_form_payloads"."id"
               AND "leads"."payload_type" = ?
        WHERE html_form_payloads.id < 10
          AND "form_type" = 'xyz'
          AND (params::varchar = '{"name":"Chris","resident":"Yes","e-content":"Secret content"}')
          AND (leads.url = 'http://example.com')
        ORDER BY "html_form_payloads"."id" ASC
        LIMIT ?
        |

        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|SELECT "html_form_payloads".* FROM "html_form_payloads" INNER JOIN "leads" ON "leads"."payload_id" = "html_form_payloads"."id" AND "leads"."payload_type" = ? WHERE html_form_payloads.id < ? AND "form_type" = ? AND (params::varchar = ?) AND (leads.url = ?) ORDER BY "html_form_payloads"."id" ASC LIMIT ?|, ss.to_s
      end

      def test_mysql_multiline
        sql = %q|
        SELECT `blogs`.*
        FROM `blogs`
        WHERE (title = 'abc')
        |

        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :mysql }
        assert_equal %q|SELECT `blogs`.*
        FROM `blogs`
        WHERE (title = ?)|, ss.to_s
      end

      def test_postgres_insert_select_from_jsonb_to_recordset_with_as
        sql = %q|
        INSERT INTO foos(foo_id, bar_id, external_id, email_address, created_at, updated_at)
          SELECT 123, 456, external_id, email_address, NOW(), NOW()
          FROM jsonb_to_recordset($${"items":[{"external_id":1234,"email_address":"test@domain.com"}]}$$::jsonb->'items')
            AS t(external_id integer, email_address varchar)
        |
        ss = SqlSanitizer.new(sql).tap{ |it| it.database_engine = :postgres }
        assert_equal %q|INSERT INTO foos(foo_id, bar_id, external_id, email_address, created_at, updated_at) SELECT ?, ?, external_id, email_address, NOW(), NOW() FROM jsonb_to_recordset($${"items":[{"external_id":?,"email_address":"?"}]}$$::jsonb->'items') AS t(external_id integer, email_address varchar)|, ss.to_s
      end

      def assert_faster_than(target_seconds)
        t1 = ::Time.now
        yield
        t2 = ::Time.now

        actual_time = t2.to_f - t1.to_f
        assert (actual_time < target_seconds), "Code took too long to execute, expected time: #{target_seconds}, actual time: #{actual_time}}"
      end
    end
  end
end
