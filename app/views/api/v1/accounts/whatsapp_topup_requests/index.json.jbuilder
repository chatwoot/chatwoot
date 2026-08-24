json.array! @whatsapp_topup_requests do |whatsapp_topup_request|
  json.partial! 'whatsapp_topup_request', whatsapp_topup_request: whatsapp_topup_request
end
