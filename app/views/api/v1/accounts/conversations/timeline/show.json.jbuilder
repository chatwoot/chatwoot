json.array! @timeline do |item|
  json.type item[:type]
  json.id item[:id]
  json.occurred_at item[:occurred_at].to_i
  json.payload item[:payload]
end
