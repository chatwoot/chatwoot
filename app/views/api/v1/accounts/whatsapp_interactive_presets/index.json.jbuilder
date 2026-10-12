json.payload do
  json.array! @whatsapp_interactive_presets do |whatsapp_interactive_preset|
    json.partial! 'api/v1/models/whatsapp_interactive_preset', whatsapp_interactive_preset: whatsapp_interactive_preset
  end
end
