json.payload do
  json.portal do
    json.partial! 'portal', portal: @portal
  end
end
