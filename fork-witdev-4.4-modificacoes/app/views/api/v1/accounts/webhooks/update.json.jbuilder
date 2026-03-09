json.payload do
  json.webhook do
    json.partial! 'webhook', webhook: @webhook
  end
end
