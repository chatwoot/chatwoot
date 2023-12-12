module SortHandler
  extend ActiveSupport::Concern
  included do
    def self.sort_on_last_activity_at(sort_direction = :desc)
      order(last_activity_at: sort_direction)
    end

    def self.sort_on_created_at(sort_direction = :asc)
      order(created_at: sort_direction)
    end

    def self.sort_on_priority(sort_direction = :desc)
      order(
        Arel::Nodes::SqlLiteral.new(
          sanitize_sql_for_order(
            "priority #{sort_direction.to_s.upcase} NULLS LAST, last_activity_at DESC"
          )
        )
      )
    end

    def self.sort_on_waiting_since(sort_direction = :asc)
      order(
        Arel::Nodes::SqlLiteral.new(
          sanitize_sql_for_order(
            "waiting_since #{sort_direction.to_s.upcase} NULLS LAST, created_at ASC"
          )
        )
      )
    end
  end
end
