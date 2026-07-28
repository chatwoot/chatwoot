json.payload do
  json.array! @announcements, partial: 'widget_announcement', as: :widget_announcement
end
