# The group half of the Uazapi backend. Same split as the facade makes, for the same
# reason: managing groups is a different API from sending messages, and reading them
# together made one class out of two.
module Whatsapp::Session::Backends::Uazapi::Backend::Groups
  # Group setting -> the endpoint that changes it and the field it takes.
  GROUP_SETTINGS = {
    'announce' => ['/group/updateAnnounce', 'announce'],
    'locked' => ['/group/updateLocked', 'locked'],
    'join_approval' => ['/group/updateJoinApproval', 'joinApproval'],
    'member_add_mode' => ['/group/updateMemberAddMode', 'memberAddMode']
  }.freeze

  def create_group(command)
    result = client.post('/group/create', { name: command.subject, participants: command.participants.map { |party| number(party) } })
    group_info_from(result)
  end

  # `/group/info` is the direct answer, but the build we captured did not serve it. The
  # listing does, and it carries the same snapshot for every group, so a provider without
  # the endpoint still syncs its groups instead of losing the capability altogether.
  def group_info(command)
    group_info_from(client.post('/group/info', { groupjid: command.group.to_jid, getInviteLink: false }))
  rescue Whatsapp::Session::Errors::NotSupported, Whatsapp::Session::Errors::SessionNotFound
    find_in_listing(command.group)
  end

  def list_groups(_command)
    groups_in(client.get('/group/list', { force: true })).map { |group| group_info_from(group) }
  end

  def leave_group(command)
    client.post('/group/leave', { groupjid: command.group.to_jid })
    true
  end

  # No per-participant result: the provider answers with the group snapshot, which says
  # who is in it now but not which of the changes asked for actually landed.
  def update_group_participants(command)
    client.post(
      '/group/updateParticipants',
      { groupjid: command.group.to_jid, action: command.action, participants: command.participants.map { |party| number(party) } }
    )
    []
  end

  def update_group_name(command)
    client.post('/group/updateName', { groupjid: command.group.to_jid, name: command.subject })
    true
  end

  def update_group_description(command)
    client.post('/group/updateDescription', { groupjid: command.group.to_jid, description: command.description })
    true
  end

  def update_group_photo(command)
    client.post('/group/updateImage', { groupjid: command.group.to_jid, image: command.image })
    true
  end

  def update_group_setting(command)
    endpoint, field = GROUP_SETTINGS[command.setting]
    raise Whatsapp::Session::Errors::InvalidPayload, "unknown group setting: #{command.setting}" if endpoint.nil?

    client.post(endpoint, { :groupjid => command.group.to_jid, field => command.value })
    true
  end

  private

  def find_in_listing(group)
    jid = group.to_jid
    found = groups_in(client.get('/group/list', { force: true })).find { |entry| entry.to_h['JID'] == jid }
    raise Whatsapp::Session::Errors::SessionNotFound, "uazapi does not know group #{jid}" if found.nil?

    group_info_from(found)
  end

  def groups_in(response)
    response.is_a?(Array) ? response : Array(response.to_h['groups'])
  end

  # `/group/create` and `/group/updateParticipants` wrap the snapshot in a `group` key;
  # `/group/list` hands the entries bare.
  def group_info_from(response)
    group = response.to_h['group'] || response.to_h
    Whatsapp::Session::Backends::Uazapi::GroupMapper.new(group).perform
  end
end
