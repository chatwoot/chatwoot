module Groupdate
  module Adapters
    class PostgreSQLAdapter < BaseAdapter
      def group_clause
        time_zone = @time_zone.tzinfo.name
        day_start_column = "#{column}::timestamptz AT TIME ZONE ? - INTERVAL ?"
        day_start_interval = "#{day_start} second"

        query =
          case period
          when :minute_of_hour
            ["EXTRACT(MINUTE FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :hour_of_day
            ["EXTRACT(HOUR FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_week
            ["EXTRACT(DOW FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_month
            ["EXTRACT(DAY FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :day_of_year
            ["EXTRACT(DOY FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :month_of_year
            ["EXTRACT(MONTH FROM #{day_start_column})::integer", time_zone, day_start_interval]
          when :week
            ["(DATE_TRUNC('day', #{day_start_column} - INTERVAL '1 day' * ((? + EXTRACT(DOW FROM #{day_start_column})::integer) % 7)) + INTERVAL ?)::date", time_zone, day_start_interval, 13 - week_start, time_zone, day_start_interval, day_start_interval]
          when :custom
            if @relation.connection.adapter_name == "Redshift"
              ["TIMESTAMP 'epoch' + (FLOOR(EXTRACT(EPOCH FROM #{column}::timestamp) / ?) * ?) * INTERVAL '1 second'", n_seconds, n_seconds]
            else
              ["TO_TIMESTAMP(FLOOR(EXTRACT(EPOCH FROM #{column}::timestamptz) / ?) * ?)", n_seconds, n_seconds]
            end
          when :day, :month, :quarter, :year
            ["DATE_TRUNC(?, #{day_start_column})::date", period, time_zone, day_start_interval]
          else
            # day start is always 0 for seconds, minute, hour
            ["DATE_TRUNC(?, #{day_start_column}) AT TIME ZONE ?", period, time_zone, day_start_interval, time_zone]
          end

        clean_group_clause(@relation.send(:sanitize_sql_array, query))
      end

      def clean_group_clause(clause)
        clause.gsub(/ (\-|\+) INTERVAL '0 second'/, "")
      end
    end
  end
end
