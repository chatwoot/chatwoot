json.payload do
  json.portals do
    json.array! @portals, partial: 'portal', as: :portal
  end
end
