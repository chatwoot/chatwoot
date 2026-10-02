json.array! @channel_groups do |channel_group|
  json.partial! 'api/v1/models/channel_group',
                formats: [:json],
                resource: channel_group,
                inbox_ids: channel_group.inboxes.map(&:id) & @accessible_inbox_ids
end
