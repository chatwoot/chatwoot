class ActionService
  include EmailHelper

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
    return @conversation.update!(assignee_id: nil) if agent_ids[0] == 'nil'

    return unless agent_belongs_to_inbox?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)

    @conversation.update!(assignee_id: @agent.id) if @agent.present?
  end

  def remove_label(labels)
    return if labels.empty?

    labels = @conversation.label_list - labels
    @conversation.update!(label_list: labels)
  end

  def assign_team(team_ids = [])
    # FIXME: The explicit checks for zero or nil (string) is bad. Move
    # this to a separate unassign action.
    should_unassign = team_ids.blank? || %w[nil 0].include?(team_ids[0].to_s)
    return @conversation.update!(team_id: nil) if should_unassign

    # check if team belongs to account only if team_id is present
    # if team_id is nil, then it means that the team is being unassigned
    return unless !team_ids[0].nil? && team_belongs_to_account?(team_ids)

    @conversation.update!(team_id: team_ids[0])
  end

  def remove_assigned_team(_params)
    @conversation.update!(team_id: nil)
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

  def create_scheduled_message(action_params)
    return if conversation_a_tweet?

    params = action_params.first&.with_indifferent_access || {}
    delay_minutes = params[:delay_minutes].to_i.clamp(1, AutomationRule::MAX_SCHEDULED_MESSAGE_DELAY_MINUTES)
    scheduled_at = delay_minutes.minutes.from_now

    scheduled_message = @conversation.scheduled_messages.new(
      account: @account,
      inbox: @conversation.inbox,
      author: scheduled_message_author,
      content: params[:content],
      scheduled_at: scheduled_at,
      status: :pending,
      template_params: params[:template_params] || {}
    )

    blob = scheduled_message_attachment_blob(params[:blob_id])
    scheduled_message.attachment.attach(blob) if blob.present?

    scheduled_message.save!
    dispatch_scheduled_message_created(scheduled_message)
  end

  private

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

  def scheduled_message_author
    Current.executed_by || Current.user
  end

  def scheduled_message_attachment_blob(blob_id)
    return if blob_id.blank?

    ActiveStorage::Blob.find_by(id: blob_id)
  end

  def dispatch_scheduled_message_created(scheduled_message)
    Rails.configuration.dispatcher.dispatch(
      Events::Types::SCHEDULED_MESSAGE_CREATED,
      Time.zone.now,
      scheduled_message: scheduled_message
    )
  end
end

ActionService.include_mod_with('ActionService')
