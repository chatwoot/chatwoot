json.id webhook.id
json.name webhook.name
json.url webhook.url
json.account_id webhook.account_id
json.subscriptions webhook.subscriptions
json.secret webhook.secret if @access_token&.scope != 'read_only'
if webhook.inbox
  json.inbox do
    json.id webhook.inbox.id
    json.name webhook.inbox.name
  end
end
