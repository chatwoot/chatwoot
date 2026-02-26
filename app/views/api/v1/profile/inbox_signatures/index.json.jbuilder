json.array! @inbox_signatures do |inbox_signature|
  json.partial! 'inbox_signature', inbox_signature: inbox_signature
end
