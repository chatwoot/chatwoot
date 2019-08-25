json.data do
  json.meta do
  end

  json.payload do
    json.array! @inboxes do |inbox|
      json.id inbox.id
      json.channel_id inbox.channel_id
      json.name inbox.name
      json.channel_type inbox.channel_type
      json.avatar_url inbox.channel.avatar.url
      if inbox.channel.class.method_defined?(:page_id)
        json.page_id inbox.channel.page_id
      end
    end
  end
end
