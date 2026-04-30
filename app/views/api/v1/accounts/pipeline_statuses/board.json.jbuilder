json.columns @columns do |column|
  json.id column[:id]
  json.name column[:name]
  json.position column[:position]
  json.total_count column[:total_count]
  json.has_more column[:has_more]
  json.items column[:items] do |item|
    json.partial! "api/v1/accounts/pipeline_statuses/board_items/#{@pipeline_type}", item: item
  end
end
