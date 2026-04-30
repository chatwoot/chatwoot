json.has_more @has_more
json.total_count @total_count
json.items @items do |item|
  json.partial! "api/v1/accounts/pipeline_statuses/board_items/#{@pipeline_type}", item: item
end
