# The widget only needs a contact sender's type
if sender.is_a?(Contact)
  json.type 'contact'
else
  json.merge! sender.push_event_data
end
