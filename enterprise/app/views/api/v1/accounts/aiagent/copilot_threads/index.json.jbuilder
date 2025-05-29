json.payload do
  json.array! @copilot_threads do |thread|
    json.id thread.id
    json.title thread.title
    json.uuid thread.uuid
    json.created_at thread.created_at.to_i
    json.user do
      json.id thread.user.id
      json.name thread.user.name
    end
  end
end
