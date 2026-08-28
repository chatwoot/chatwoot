json.status 'calling'
json.call_id @call.provider_call_id
json.id @call.id
json.message_id @message.id
json.conversation_id @conversation.display_id
json.recording_enabled @call.recording_enabled != false
json.provider 'whatsapp'
