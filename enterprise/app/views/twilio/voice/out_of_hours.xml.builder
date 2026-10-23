xml.Response do
  if @inbox.out_of_hours_call_audio.attached?
    xml.Play url_for(@inbox.out_of_hours_call_audio)
  else
    xml.Say @inbox.channel.out_of_hours_call_message, language: out_of_hours_call_language(@inbox)
  end
  xml.Hangup
end
