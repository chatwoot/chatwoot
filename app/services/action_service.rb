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
    Rails.logger.info "[ACTION_SERVICE] 🎯 assign_agent called with agent_ids: #{agent_ids.inspect}"
    Rails.logger.info "[ACTION_SERVICE] Conversation: #{@conversation.id}, Current.executed_by: #{Current.executed_by.inspect}"

    return @conversation.update!(assignee_id: nil) if agent_ids[0] == 'nil'

    return unless agent_belongs_to_inbox?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)
    Rails.logger.info "[ACTION_SERVICE] Found agent: #{@agent&.id} (#{@agent&.name}), is_ai: #{@agent&.is_ai?}"

    return unless @agent.present?

    Rails.logger.info "[ACTION_SERVICE] 💾 Updating conversation #{@conversation.id} assignee to #{@agent.id}"
    @conversation.update!(assignee_id: @agent.id)
    Rails.logger.info "[ACTION_SERVICE] ✅ Conversation updated, assignee_id: #{@conversation.assignee_id}"

    # Trigger AI response if assigned agent is AI and last message is from customer
    if @agent.is_ai?
      Rails.logger.info '[ACTION_SERVICE] 🤖 Agent is AI, checking if response needed'
      trigger_ai_response_if_needed
    else
      Rails.logger.info '[ACTION_SERVICE] 👤 Agent is human, skipping AI response trigger'
    end
  end

  def remove_label(labels)
    return if labels.empty?

    labels = @conversation.label_list - labels
    @conversation.update(label_list: labels)
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
    emails = emails[0].gsub(/\s+/, '').split(',')

    emails.each do |email|
      email = parse_email_variables(@conversation, email)
      ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, email)&.deliver_later
    end
  end

  private

  def trigger_ai_response_if_needed
    # Get the last incoming message from the customer
    # Exclude activity and template messages (system messages like "Get notified by email", "Give the team a way to reach you", etc.)
    last_message = @conversation.messages.where(message_type: :incoming).last

    Rails.logger.info "[AUTOMATION] 🤖 AI agent assigned to conversation #{@conversation.id}, checking if AI response needed"
    Rails.logger.info "[AUTOMATION] Last incoming message: #{last_message&.id} (content: '#{last_message&.content&.truncate(50)}')"

    # Only trigger AI response if:
    # 1. There is a last incoming message from customer
    # 2. The conversation is not resolved or snoozed
    unless last_message
      Rails.logger.info "[AUTOMATION] No incoming messages in conversation #{@conversation.id}, skipping AI response"
      return
    end

    if @conversation.resolved? || @conversation.snoozed?
      Rails.logger.info "[AUTOMATION] Conversation #{@conversation.id} is resolved or snoozed, skipping AI response"
      return
    end

    Rails.logger.info "[AUTOMATION] ✅ Triggering AI response for message #{last_message.id} in conversation #{@conversation.id}"

    # Clear Redis lock to allow AI response trigger
    # This is needed because the message may have been processed before AI was assigned
    clear_ai_response_lock(last_message)

    # Trigger AI response service
    Messages::AiResponseTriggerService.new(message: last_message).perform
  rescue StandardError => e
    Rails.logger.error "[AUTOMATION] Error triggering AI response: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def clear_ai_response_lock(message)
    # Clear the Redis lock that prevents duplicate AI responses
    # This allows automation to trigger AI response even if message was already processed
    dedup_key = (message.source_id.presence || "msg_#{message.id}")
    redis_key = "ai_response_triggered:#{dedup_key}"

    Rails.logger.info "[AUTOMATION] 🔓 Clearing Redis lock for message #{message.id}: #{redis_key}"
    Redis::Alfred.del(redis_key)
  rescue StandardError => e
    Rails.logger.error "[AUTOMATION] ⚠️  Failed to clear Redis lock: #{e.message}"
    # Don't raise - this is not critical, AI trigger will just fail if lock exists
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
end

ActionService.include_mod_with('ActionService')
