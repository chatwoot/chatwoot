json.payload do
  json.array! @portals, partial: 'portal', as: :portal
end

json.meta do
  json.current_page @current_page
  json.portals_count @portals.size
end
