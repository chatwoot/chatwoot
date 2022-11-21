json.payload do
  json.array! @portals.each do |portal|
    json.partial! 'portal', formats: [:json], portal: portal, articles: []
  end
end

json.meta do
  json.current_page @current_page
  json.portals_count @portals.size
end
