# frozen_string_literal: false

require 'scout_apm/environment'

# Removes actual values from SQL. Used to both obfuscate the SQL and group
# similar queries in the UI.
module ScoutApm
  module Utils
    class SqlSanitizer
      MULTIPLE_SPACES    = %r|\s+|.freeze
      MULTIPLE_QUESTIONS = /\?(,\?)+/.freeze

      PSQL_VAR_INTERPOLATION = %r|\[\[.*\]\]\s*\z|.freeze
      PSQL_REMOVE_STRINGS = /'(?:[^']|'')*'/.freeze
      PSQL_REMOVE_JSON_STRINGS = /:"(?:[^"]|"")*"/.freeze
      PSQL_REMOVE_INTEGERS = /(?<!LIMIT )\b\d+\b/.freeze
      PSQL_AFTER_SELECT = /(?:SELECT\s+).*?(?:WHERE|FROM\z)/im.freeze # Should be everything between a FROM and a WHERE
      PSQL_PLACEHOLDER = /\$\d+/.freeze
      PSQL_IN_CLAUSE = /IN\s+\(\?[^\)]*\)/.freeze
      PSQL_AFTER_FROM = /(?:FROM\s+).*?(?:WHERE|\z)/im.freeze # Should be everything between a FROM and a WHERE
      PSQL_AFTER_FROM_AS = /(?:FROM\s+).*?(?:AS|\z)/im.freeze # Should be everything between a FROM and AS without WHERE
      PSQL_AFTER_JOIN = /(?:JOIN\s+).*?\z/im.freeze
      PSQL_AFTER_WHERE = /(?:WHERE\s+).*?(?:SELECT|\z)/im.freeze
      PSQL_AFTER_SET = /(?:SET\s+).*?(?:WHERE|\z)/im.freeze

      MYSQL_VAR_INTERPOLATION = %r|\[\[.*\]\]\s*$|.freeze
      MYSQL_REMOVE_INTEGERS = /(?<!LIMIT )\b\d+\b/.freeze
      MYSQL_REMOVE_SINGLE_QUOTE_STRINGS = %r{'(?:\\'|[^']|'')*'}.freeze
      MYSQL_REMOVE_DOUBLE_QUOTE_STRINGS = %r{"(?:\\"|[^"]|"")*"}.freeze
      MYSQL_IN_CLAUSE = /IN\s+\(\?[^\)]*\)/.freeze

      SQLITE_VAR_INTERPOLATION = %r|\[\[.*\]\]\s*$|.freeze
      SQLITE_REMOVE_STRINGS = /'(?:[^']|'')*'/.freeze
      SQLITE_REMOVE_INTEGERS = /(?<!LIMIT )\b\d+\b/.freeze

      # => "EXEC sp_executesql N'SELECT  [users].* FROM [users] WHERE (age > 50)  ORDER BY [users].[id] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY', N'@0 int', @0 = 10"
      SQLSERVER_REMOVE_EXECUTESQL = /EXEC sp_executesql (N')?/.freeze
      SQLSERVER_REMOVE_STRINGS = /'(?:[^']|'')*'/.freeze
      SQLSERVER_REMOVE_INTEGERS = /(?<!LIMIT )\b(?<!@)\d+\b/.freeze
      SQLSERVER_IN_CLAUSE = /IN\s+\(\?[^\)]*\)/.freeze

      attr_accessor :database_engine

      def initialize(sql)
        @raw_sql = sql
        @database_engine = ScoutApm::Agent.instance.context.environment.database_engine
        @sanitized = false # only sanitize once.
      end

      def sql
        @sql ||= scrubbed(@raw_sql.dup) # don't do this in initialize as it is extra work that isn't needed unless we have a slow transaction.
      end

      def to_s
        if @sanitized
          sql
        else
          @sanitized = true
        end
        case database_engine
        when :postgres then to_s_postgres
        when :mysql    then to_s_mysql
        when :sqlite   then to_s_sqlite
        when :sqlserver then to_s_sqlserver
        end
      end

      private

      def to_s_sqlserver
        sql.gsub!(SQLSERVER_REMOVE_EXECUTESQL, '')
        sql.gsub!(SQLSERVER_REMOVE_STRINGS, '?')
        sql.gsub!(SQLSERVER_REMOVE_INTEGERS, '?')
        sql.gsub!(SQLSERVER_IN_CLAUSE, 'IN (?)')
        sql
      end

      def to_s_postgres
        sql.gsub!(PSQL_PLACEHOLDER, '?')
        sql.gsub!(PSQL_VAR_INTERPOLATION, '')
        # sql.gsub!(PSQL_REMOVE_STRINGS, '?')
        sql.gsub!(PSQL_AFTER_WHERE) {|c| c.gsub(PSQL_REMOVE_STRINGS, '?')}
        sql.gsub!(PSQL_AFTER_FROM_AS) {|c| c.gsub(PSQL_REMOVE_JSON_STRINGS, ':"?"')}
        sql.gsub!(PSQL_AFTER_JOIN) {|c| c.gsub(PSQL_REMOVE_STRINGS, '?')}
        sql.gsub!(PSQL_AFTER_SET) {|c| c.gsub(PSQL_REMOVE_STRINGS, '?')}
        sql.gsub!(PSQL_REMOVE_INTEGERS, '?')
        sql.gsub!(PSQL_IN_CLAUSE, 'IN (?)')
        sql.gsub!(MULTIPLE_SPACES, ' ')
        sql.strip!
        sql
      end

      def to_s_mysql
        sql.gsub!(MYSQL_VAR_INTERPOLATION, '')
        sql.gsub!(MYSQL_REMOVE_SINGLE_QUOTE_STRINGS, '?')
        sql.gsub!(MYSQL_REMOVE_DOUBLE_QUOTE_STRINGS, '?')
        sql.gsub!(MYSQL_REMOVE_INTEGERS, '?')
        sql.gsub!(MYSQL_IN_CLAUSE, 'IN (?)')
        sql.gsub!(MULTIPLE_QUESTIONS, '?')
        sql.strip!
        sql
      end

      def to_s_sqlite
        sql.gsub!(SQLITE_VAR_INTERPOLATION, '')
        sql.gsub!(SQLITE_REMOVE_STRINGS, '?')
        sql.gsub!(SQLITE_REMOVE_INTEGERS, '?')
        sql.gsub!(MULTIPLE_SPACES, ' ')
        sql.strip!
        sql
      end

      def has_encodings?(encodings=['UTF-8', 'binary'])
        encodings.all?{|enc| Encoding.find(enc) rescue false}
      end

      MAX_SQL_LENGTH = 16384

      def scrubbed(str)
        return '' if !str.is_a?(String) || str.length > MAX_SQL_LENGTH # safeguard - don't sanitize or scrub large SQL statements
        return str if !str.respond_to?(:encode) # Ruby <= 1.8 doesn't have string encoding
        return str if str.valid_encoding? # Whatever encoding it is, it is valid and we can operate on it
        ScoutApm::Agent.instance.context.logger.debug "Scrubbing invalid sql encoding."
        if str.respond_to?(:scrub) # Prefer to scrub before we have to convert
          return str.scrub('_')
        elsif has_encodings?(['UTF-8', 'binary'])
          return str.encode('UTF-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '_')
        end
        ScoutApm::Agent.instance.context.logger.debug "Unable to scrub invalid sql encoding."
        ''
      end

    end
  end
end
