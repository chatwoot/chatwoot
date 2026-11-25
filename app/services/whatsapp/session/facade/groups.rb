# The group half of the Facade. It was split out because the class was doing two jobs
# at once: translating the messaging API and translating the group API. Same contract,
# same legacy shapes the six group controllers and Groups::CreateService already read.
module Whatsapp::Session::Facade::Groups
  # The properties the group settings endpoint accepts, in contract terms.
  GROUP_SETTINGS = { 'announce' => 'announce', 'restrict' => 'locked', 'locked' => 'locked' }.freeze

  # --- groups --------------------------------------------------------------------

  def allow_group_creation?
    capability?('group_management')
  end

  def create_group(subject, participants)
    refuse_group_management unless capability?('group_management')

    info = backend.create_group(model::Commands::GroupCreate.new(subject: subject, participants: addresses(participants)))
    # Groups::CreateService reads :id from this, the same key the Baileys response had.
    { id: info.group.to_jid, subject: info.subject }
  end

  def update_group_subject(group_jid, subject)
    backend.update_group_name(model::Commands::GroupNameSet.new(group: group(group_jid), subject: subject))
  end

  def update_group_description(group_jid, description)
    backend.update_group_description(model::Commands::GroupDescriptionSet.new(group: group(group_jid), description: description))
  end

  def update_group_picture(group_jid, image_base64)
    backend.update_group_photo(model::Commands::GroupPhotoSet.new(group: group(group_jid), image: image_base64))
  end

  def update_group_participants(group_jid, participants, action)
    backend.update_group_participants(
      model::Commands::GroupParticipantsUpdate.new(group: group(group_jid), participants: addresses(participants), action: action)
    )
  end

  def group_invite_code(group_jid)
    backend.group_invite_code(model::Commands::GroupInviteGet.new(group: group(group_jid)))
  end

  def revoke_group_invite(group_jid)
    backend.group_invite_code(model::Commands::GroupInviteGet.new(group: group(group_jid), revoke: true))
  end

  # Rendered straight to the dashboard, so the entries keep the keys it already reads.
  #
  # Approving people into a group is a capability of its own, and a provider can do groups
  # without it: Uazapi is one. Asking its backend anyway raises NotSupported, which the
  # controller does not answer for, so a routable endpoint turns into a 500.
  def group_join_requests(group_jid)
    return [] unless capability?('group_join_requests')

    requests = backend.group_join_requests(model::Commands::GroupJoinRequestsList.new(group: group(group_jid)))
    Array(requests).map { |request| join_request_payload(request) }
  end

  def handle_group_join_requests(group_jid, participants, action)
    raise Whatsapp::Session::Errors::NotSupported, 'this provider cannot approve join requests' unless capability?('group_join_requests')

    backend.handle_group_join_requests(
      model::Commands::GroupJoinRequestsUpdate.new(group: group(group_jid), participants: addresses(participants), action: action)
    )
  end

  def group_leave(group_jid)
    backend.leave_group(model::Commands::GroupLeave.new(group: group(group_jid)))
  end

  def group_setting_update(group_jid, property, enabled)
    setting = GROUP_SETTINGS[property.to_s]
    raise Whatsapp::Session::Errors::InvalidPayload, "unknown group setting: #{property}" if setting.blank?

    update_group_setting(group_jid, setting, enabled)
  end

  def group_join_approval_mode(group_jid, mode)
    update_group_setting(group_jid, 'join_approval', mode.to_s == 'on')
  end

  def group_member_add_mode(group_jid, mode)
    update_group_setting(group_jid, 'member_add_mode', mode.to_s == 'all_member_add')
  end

  # Guarded on `group_management` and not on `groups`: the roster comes from the provider's
  # own group read, so an inbox that takes group conversations without the command surface
  # has nothing to sync from. There is no group conversation to reach here without
  # `groups` anyway.
  def sync_group(conversation, soft: false)
    return unless capability?('group_management')

    Whatsapp::Session::Groups::Syncer.new(channel: channel, group_contact: conversation.contact, soft: soft).perform
  end

  private

  # `WHATSAPP_GROUPS_ENABLED=false` takes every group capability away from the descriptor,
  # `group_management` included, and the dashboard hides the group panel accordingly. The
  # API endpoints behind that panel are still routable, though, so the switch has to be
  # enforced where the calls land: gating only creation left participants, metadata,
  # invites, settings, leaving and syncing reaching the provider on an installation that
  # turned groups off.
  #
  # Now also the gate for an inbox whose provider takes group conversations and answers no
  # group commands, which the switch being on does not make possible.
  # Two refusals wearing one capability, and an agent reading the reply has to be able to
  # tell them apart. The installation turned groups off entirely, and nothing about groups
  # works; or this inbox takes group conversations and its provider answers no group
  # commands, in which case the threads in the sidebar are real and only this button is
  # not. Saying "groups are disabled" for the second sends whoever reads it looking for a
  # switch that is already on.
  def refuse_group_management
    raise Whatsapp::Session::Errors::NotSupported,
          if Whatsapp::Session::Registry.groups_enabled?
            'this inbox receives group conversations but cannot manage groups'
          else
            'groups are disabled on this installation'
          end
  end

  def group(group_jid)
    refuse_group_management unless capability?('group_management')

    parsed = model::Address.parse(group_jid)
    raise Whatsapp::Session::Errors::InvalidPayload, "not a group: #{group_jid}" unless parsed&.group?

    parsed
  end

  def addresses(jids)
    Array(jids).filter_map { |jid| model::Address.parse(jid) }
  end

  def update_group_setting(group_jid, setting, value)
    backend.update_group_setting(model::Commands::GroupSettingsSet.new(group: group(group_jid), setting: setting, value: value))
  end

  def join_request_payload(request)
    request = request.stringify_keys
    party = model::Party.from_h(request['party'] || {})
    {
      'jid' => party.identifier || model::Address.phone(party.phone)&.to_jid,
      'phone_number' => party.phone,
      'request_time' => request['requested_at']
    }.compact
  end
end
