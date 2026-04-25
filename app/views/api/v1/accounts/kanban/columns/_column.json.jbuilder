json.id column.id
json.name column.name
json.position column.position
json.color column.color
json.cards_count column.cards.size
json.potential_value_sum column.cards.sum { |c| c.potential_value.to_f }
