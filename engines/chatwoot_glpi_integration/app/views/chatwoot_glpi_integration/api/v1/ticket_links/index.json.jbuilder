json.data do
  json.array! @links, partial: 'chatwoot_glpi_integration/api/v1/ticket_links/ticket_link', as: :link
end
