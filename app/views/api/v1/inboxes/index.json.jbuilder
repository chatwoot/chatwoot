json.data do
  json.meta do
  end

  json.payload do
    json.array! @inboxes do |inbox|
      json.id inbox.id
      json.channel_id inbox.channel_id
      json.name inbox.name
      json.channel_type inbox.channel_type
      json.avatar_url inbox.channel.try(:avatar).try(:url)
      json.page_id inbox.channel.try(:page_id)
    end
  end
end
