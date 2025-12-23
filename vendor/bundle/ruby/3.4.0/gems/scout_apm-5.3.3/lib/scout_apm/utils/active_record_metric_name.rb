module ScoutApm
  module Utils
    class ActiveRecordMetricName
      attr_reader :sql, :name
      DEFAULT_METRIC = 'SQL/other'.freeze

      def initialize(sql, name)
        @sql = sql || ""
        @name = name.to_s
      end

      # Converts an SQL string and the name (typically assigned automatically
      # by rails) into a Scout metric_name.
      #
      # This prefers to use the ActiveRecord-provided name over parsing SQL as parsing is slower.
      #
      # sql: SELECT "places".* FROM "places"  ORDER BY "places"."position" ASC
      # name: Place Load
      # metric_name: Place/find
      def to_s
        return @to_s if @to_s
        parsed = parse_operation
        if parsed
          @to_s = "#{model}/#{parsed}"
        else
          @to_s = regex_name(sql)
        end
      end

      # This only returns a value if a name is provided via +initialize+.
      def model
        parts.first
      end

      # This only returns a value if a name is provided via +initialize+.
      def normalized_operation
        parse_operation
      end

      # For the layer lookup.
      def hash
        h = name.downcase.hash
        h
      end

      # For the layer lookup.
      # Reminder: #eql? is for Hash equality: returns true if obj and other refer to the same hash key.
      def eql?(o)
        self.class    == o.class &&
        name.downcase == o.name.downcase
      end

      alias_method :==, :eql?

      private

      # This only returns a value if a name is provided via +initialize+.
      def operation
        if parts.length >= 2
          parts[1].downcase
        end
      end

      # This only returns a value if a name is provided via +initialize+.
      def parts
        name.split(" ")
      end

      # Returns nil if no match
      # Returns nil if the operation wasn't under developer control (and hence isn't interesting to report)
      def parse_operation
        case operation
        when 'indexes', 'columns' then nil # not under developer control
        when 'load' then 'find'
        when 'destroy', 'find', 'save', 'create', 'exists' then operation
        when 'update' then 'save'
        else
          if model == 'Join'
            operation
          end
        end
      end


      ########################
      #  Regex based naming  #
      ########################
      #
      WHITE_SPACE = '\s*'
      REGEX_OPERATION = '(SELECT|UPDATE|INSERT|DELETE)'
      FROM = 'FROM'
      INTO = 'INTO'
      NON_GREEDY_CONSUME = '.*?'
      TABLE = '(?:"|`)?(.*?)(?:"|`)?\s'
      COUNT = 'COUNT\(.*?\)'
      BEGIN_STATEMENT = 'BEGIN'.freeze # BEGIN is a reserved keyword
      COMMIT = 'COMMIT'.freeze

      SELECT_REGEX = /\A#{WHITE_SPACE}(SELECT)#{WHITE_SPACE}(#{COUNT})?#{NON_GREEDY_CONSUME}#{FROM}#{WHITE_SPACE}#{TABLE}/i.freeze
      UPDATE_REGEX = /\A#{WHITE_SPACE}(UPDATE)#{WHITE_SPACE}#{TABLE}/i.freeze
      INSERT_REGEX = /\A#{WHITE_SPACE}(INSERT)#{WHITE_SPACE}#{INTO}#{WHITE_SPACE}#{TABLE}/i.freeze
      DELETE_REGEX = /\A#{WHITE_SPACE}(DELETE)#{WHITE_SPACE}#{FROM}#{TABLE}/i.freeze

      COUNT_LABEL = 'count'.freeze
      SELECT_LABEL = 'find'.freeze
      UPDATE_LABEL = 'save'.freeze
      INSERT_LABEL = 'create'.freeze
      DELETE_LABEL = 'destroy'.freeze
      UNKNOWN_LABEL = 'SQL/other'.freeze

      # Attempt to do some basic parsing of SQL via regexes to extract the SQL
      # verb (select, update, etc) and the table being operated on.
      #
      # This is a fallback from what ActiveRecord gives us, we prefer its
      # names. But sometimes it is giving us a no-name query, and we have to
      # attempt to figure it out ourselves.
      #
      # This relies on ActiveSupport's classify method. If it's not present,
      # just skip the attempt to rename here. This could happen in a Grape or
      # Sinatra application that doesn't import ActiveSupport. At this point,
      # you're already using ActiveRecord, so it's likely loaded anyway.
      def regex_name(sql)
        # We rely on the ActiveSupport inflections code here. Bail early if we can't use it.
        return UNKNOWN_LABEL unless UNKNOWN_LABEL.respond_to?(:classify)

        if match = SELECT_REGEX.match(sql)
          operation =
            if match[2]
              COUNT_LABEL
            else
              SELECT_LABEL
            end
          "#{match[3].gsub(/\W/,'').classify}/#{operation}"
        elsif match = UPDATE_REGEX.match(sql)
          "#{match[2].classify}/#{UPDATE_LABEL}"
        elsif match = INSERT_REGEX.match(sql)
          "#{match[2].classify}/#{INSERT_LABEL}"
        elsif match = DELETE_REGEX.match(sql)
          "#{match[2].classify}/#{DELETE_LABEL}"
        elsif sql == BEGIN_STATEMENT
          "SQL/#{BEGIN_STATEMENT.downcase}"
        elsif sql == COMMIT
          "SQL/#{COMMIT.downcase}"
        else
          UNKNOWN_LABEL
        end
      rescue
        UNKNOWN_LABEL
      end
    end
  end
end
