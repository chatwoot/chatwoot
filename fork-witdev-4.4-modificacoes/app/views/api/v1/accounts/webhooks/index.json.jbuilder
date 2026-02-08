json.payload do
  json.webhooks do
    json.array! @webhooks, partial: 'webhook', as: :webhook
  end
end
