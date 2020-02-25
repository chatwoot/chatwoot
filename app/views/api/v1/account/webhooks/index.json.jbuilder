json.payload do
  json.webhooks do
    json.array! @webhooks, partial: 'webhooks/webhook', as: :webhook
  end
end
