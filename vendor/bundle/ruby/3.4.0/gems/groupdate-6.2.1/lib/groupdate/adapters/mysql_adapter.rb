module Groupdate
  module Adapters
    class MySQLAdapter < BaseAdapter
      def group_clause
        time_zone = @time_zone.tzinfo.name
        day_start_column = "CONVERT_TZ(#{column}, '+00:00', ?) - INTERVAL ? second"

        query =
          case period
          when :minute_of_hour
            ["MINUTE(#{day_start_column})", time_zone, day_start]
          when :hour_of_day
            ["HOUR(#{day_start_column})", time_zone, day_start]
          when :day_of_week
            ["DAYOFWEEK(#{day_start_column}) - 1", time_zone, day_start]
          when :day_of_month
            ["DAYOFMONTH(#{day_start_column})", time_zone, day_start]
          when :day_of_year
            ["DAYOFYEAR(#{day_start_column})", time_zone, day_start]
          when :month_of_year
            ["MONTH(#{day_start_column})", time_zone, day_start]
          when :week
            ["CAST(DATE_FORMAT(#{day_start_column} - INTERVAL ((? + DAYOFWEEK(#{day_start_column})) % 7) DAY, '%Y-%m-%d') AS DATE)", time_zone, day_start, 12 - week_start, time_zone, day_start]
          when :quarter
            ["CAST(CONCAT(YEAR(#{day_start_column}), '-', LPAD(1 + 3 * (QUARTER(#{day_start_column}) - 1), 2, '00'), '-01') AS DATE)", time_zone, day_start, time_zone, day_start]
          when :day, :month, :year
            format =
              case period
              when :day
                "%Y-%m-%d"
              when :month
                "%Y-%m-01"
              else # year
                "%Y-01-01"
              end

            ["CAST(DATE_FORMAT(#{day_start_column}, ?) AS DATE)", time_zone, day_start, format]
          when :custom
            ["FROM_UNIXTIME((UNIX_TIMESTAMP(#{column}) DIV ?) * ?)", n_seconds, n_seconds]
          else
            format =
              case period
              when :second
                "%Y-%m-%d %H:%i:%S"
              when :minute
                "%Y-%m-%d %H:%i:00"
              else # hour
                "%Y-%m-%d %H:00:00"
              end

            ["CONVERT_TZ(DATE_FORMAT(#{day_start_column}, ?) + INTERVAL ? second, ?, '+00:00')", time_zone, day_start, format, day_start, time_zone]
          end

        clean_group_clause(@relation.send(:sanitize_sql_array, query))
      end

      def clean_group_clause(clause)
        # zero quoted in Active Record 7+
        clause.gsub(/ (\-|\+) INTERVAL 0 second/, "").gsub(/ (\-|\+) INTERVAL '0' second/, "")
      end
    end
  end
end
