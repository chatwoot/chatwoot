json.payload do
  json.array! @suggestions do |suggestion|
    json.id suggestion['id']
    json.name suggestion['name']
    json.url suggestion['url']
    json.url_template suggestion['url_template']
    json.input suggestion['input']
    json.recommended suggestion['recommended']
    json.connected @connected_urls.include?(suggestion['url'])
  end
end
