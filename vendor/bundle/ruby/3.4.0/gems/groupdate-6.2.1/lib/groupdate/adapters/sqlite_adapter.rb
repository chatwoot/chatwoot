module Groupdate
  module Adapters
    class SQLiteAdapter < BaseAdapter
      def group_clause
        raise Groupdate::Error, "Time zones not supported for SQLite" unless @time_zone.utc_offset.zero?
        raise Groupdate::Error, "day_start not supported for SQLite" unless day_start.zero?

        query =
          if period == :week
            ["strftime('%Y-%m-%d', #{column}, '-6 days', ?)", "weekday #{(week_start + 1) % 7}"]
          elsif period == :custom
            ["datetime((strftime('%s', #{column}) / ?) * ?, 'unixepoch')", n_seconds, n_seconds]
          else
            format =
              case period
              when :minute_of_hour
                "%M"
              when :hour_of_day
                "%H"
              when :day_of_week
                "%w"
              when :day_of_month
                "%d"
              when :day_of_year
                "%j"
              when :month_of_year
                "%m"
              when :second
                "%Y-%m-%d %H:%M:%S UTC"
              when :minute
                "%Y-%m-%d %H:%M:00 UTC"
              when :hour
                "%Y-%m-%d %H:00:00 UTC"
              when :day
                "%Y-%m-%d"
              when :month
                "%Y-%m-01"
              when :quarter
                raise Groupdate::Error, "Quarter not supported for SQLite"
              else # year
                "%Y-01-01"
              end

            ["strftime(?, #{column})", format]
          end

        @relation.send(:sanitize_sql_array, query)
      end
    end
  end
end
