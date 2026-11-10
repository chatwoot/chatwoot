module Captain::Conversation::ResponseLifecycleLogging
  private

  def conversation_owned?
    Conversation.uncached do
      Conversation.pending.exists?(id: @conversation.id, ai_assignee: @assistant)
    end
  end

  def log_not_owned
    return if @responding_to_message_id.nil?

    Rails.logger.info(
      "[CAPTAIN][ResponseLifecycle] event=job_skipped reason=conversation_not_owned conversation_id=#{@conversation.id} " \
      "responding_to_message_id=#{@responding_to_message_id} assistant_id=#{@assistant.id}"
    )
  end

  def log_pre_generation_discard
    Rails.logger.info(
      '[CAPTAIN][ResponseLifecycle] event=response_discarded reason=newer_customer_message_before_generation ' \
      "conversation_id=#{@conversation.id} responding_to_message_id=#{@responding_to_message_id}"
    )
  end
end
