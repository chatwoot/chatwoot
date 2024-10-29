json.id webhook.id
json.url webhook.url
json.account_id webhook.account_id
json.subscriptions webhook.subscriptions
if webhook.inbox
  json.inbox do
    json.id webhook.inbox.id
    json.name webhook.inbox.name
  end
end
