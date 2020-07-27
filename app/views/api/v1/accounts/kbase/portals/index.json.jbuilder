json.payload do
  json.array! @portals, partial: 'portal', as: :portal
end
