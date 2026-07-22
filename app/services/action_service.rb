class ActionService
  include EmailHelper
  include FileTypeHelper

  def initialize(conversation)
    @conversation = conversation.reload
    @account = @conversation.account
  end

  def mute_conversation(_params)
    @conversation.mute!
  end

  def snooze_conversation(_params)
    @conversation.snoozed!
  end

  def resolve_conversation(_params)
    @conversation.resolved!
  end

  def open_conversation(_params)
    @conversation.open!
  end

  def pending_conversation(_params)
    @conversation.pending!
  end

  def change_status(status)
    @conversation.update!(status: status[0])
  end

  def change_priority(priority)
    @conversation.update!(priority: (priority[0] == 'nil' ? nil : priority[0]))
  end

  def add_label(labels)
    return if labels.empty?

    @conversation.reload.add_labels(labels)
  end

  def assign_agent(agent_ids = [])
    if agent_ids[0] == 'nil'
      return Conversations::AssignmentService.new(conversation: @conversation, assignee_id: nil).perform
    end

    agent_ids = [last_responding_agent_id] if agent_ids[0] == 'last_responding_agent'
    return unless agent_belongs_to_inbox?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)
    return unless @agent.present? && @agent.confirmed?

    Conversations::AssignmentService.new(conversation: @conversation, assignee_id: @agent.id).perform
  end

  def remove_label(labels)
    return if labels.empty?

    labels = @conversation.label_list - labels
    @conversation.update(label_list: labels)
  end

  def assign_team(team_ids = [])
    # Keep nil/0 handling for existing automation and macro payloads.
    should_unassign = team_ids.blank? || %w[nil 0].include?(team_ids[0].to_s)
    if should_unassign
      return Conversations::TeamAssignmentService.new(conversation: @conversation, team_id: nil).perform
    end

    # check if team belongs to account only if team_id is present
    # if team_id is nil, then it means that the team is being unassigned
    return unless !team_ids[0].nil? && team_belongs_to_account?(team_ids)

    Conversations::TeamAssignmentService.new(
      conversation: @conversation,
      team_id: team_ids[0]
    ).perform
  end

  def remove_assigned_agent(_params)
    Conversations::AssignmentService.new(conversation: @conversation, assignee_id: nil).perform
  end

  def remove_assigned_team(_params)
    Conversations::TeamAssignmentService.new(conversation: @conversation, team_id: nil).perform
  end

  def send_email_transcript(emails)
    return unless @account.email_transcript_enabled?

    emails = emails[0].gsub(/\s+/, '').split(',')

    emails.each do |email|
      break unless @account.within_email_rate_limit?

      email = parse_email_variables(@conversation, email)
      ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, email)&.deliver_later
      @account.increment_email_sent_count
    end
  end

  private

  def last_responding_agent_id
    @conversation.messages.outgoing.where(sender_type: 'User', private: false).last&.sender_id
  end

  def agent_belongs_to_inbox?(agent_ids)
    member_ids = @conversation.inbox.members.pluck(:user_id)
    assignable_agent_ids = member_ids + @account.administrators.ids

    assignable_agent_ids.include?(agent_ids[0])
  end

  def team_belongs_to_account?(team_ids)
    @account.team_ids.include?(team_ids[0])
  end

  def conversation_a_tweet?
    return false if @conversation.additional_attributes.blank?

    @conversation.additional_attributes['type'] == 'tweet'
  end

  def attachment_message_params(blobs)
    blobs.each { |blob| normalize_blob_audio_content_type!(blob) }

    whatsapp = @conversation.inbox.whatsapp?
    {
      content: nil,
      private: false,
      attachments: blobs,
      is_voice_message: whatsapp && blobs.any? { |blob| voice_note_blob?(blob) },
      force_audio_as_file: !whatsapp
    }
  end

  def normalize_blob_audio_content_type!(blob)
    resolved = resolve_audio_content_type(blob.content_type, blob.filename.to_s)
    return if resolved.blank? || resolved == blob.content_type

    blob.update!(content_type: resolved)
  end

  def voice_note_blob?(blob)
    voice_note_content_type?(blob.content_type)
  end
end

ActionService.include_mod_with('ActionService')
