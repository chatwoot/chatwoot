json.identifier @inbox_channel.identifier
json.identity_validation_enabled @inbox_channel.hmac_mandatory
json.partial! 'public/api/v1/models/inbox.json.jbuilder', resource: @inbox_channel.inbox
