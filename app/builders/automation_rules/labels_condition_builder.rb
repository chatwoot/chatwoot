class AutomationRules::LabelsConditionBuilder < AutomationRules::BaseConditionsBuilder
  LABELS_RELATION = <<~SQL.squish.freeze
    FROM taggings
    INNER JOIN tags ON tags.id = taggings.tag_id
    WHERE taggings.taggable_id = conversations.id
      AND taggings.taggable_type = 'Conversation'
      AND taggings.context = 'labels'
  SQL

  def build
    query = case filter_operator
            when 'equal_to' then "(#{exact_match_query})"
            when 'not_equal_to' then "NOT (#{exact_match_query})"
            when 'contains' then contains_query
            when 'does_not_contain' then "NOT (#{contains_query})"
            when 'is_present' then presence_query
            when 'is_not_present' then "NOT (#{presence_query})"
            else raise ArgumentError, "Unsupported label filter operator: #{filter_operator}"
            end

    condition(query)
  end

  private

  def exact_match_query
    labels = bind(values)
    label_count = bind(values.size, prefix: 'value_count')

    <<~SQL.squish
      NOT EXISTS (SELECT 1 #{LABELS_RELATION} AND tags.name NOT IN (#{labels}))
      AND (SELECT COUNT(DISTINCT tags.name) #{LABELS_RELATION}) = #{label_count}
    SQL
  end

  def contains_query
    labels = bind(values)
    "EXISTS (SELECT 1 #{LABELS_RELATION} AND tags.name IN (#{labels}))"
  end

  def presence_query
    "EXISTS (SELECT 1 #{LABELS_RELATION})"
  end
end
