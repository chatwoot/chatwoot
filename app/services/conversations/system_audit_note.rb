# frozen_string_literal: true

# Short private timeline note for system actors (automations today; flows later).
class Conversations::SystemAuditNote
  def self.perform(conversation:, content:, content_attributes: {})
    new(conversation: conversation, content: content, content_attributes: content_attributes).perform
  end

  def initialize(conversation:, content:, content_attributes: {})
    @conversation = conversation
    @content = content.to_s.strip
    @content_attributes = content_attributes.to_h
  end

  def perform
    return if @content.blank?
    return if tweet?

    message = Messages::MessageBuilder.new(
      nil,
      @conversation.reload,
      {
        content: @content,
        private: true,
        content_attributes: @content_attributes.merge(system_audit: true)
      }
    ).perform

    # MessageBuilder replaces content_attributes when automation_rule_id is present;
    # re-apply audit attrs so system_audit survives.
    return message if message.blank?

    attrs = (message.content_attributes || {}).with_indifferent_access
    attrs.merge!(@content_attributes)
    attrs[:system_audit] = true
    message.update!(content_attributes: attrs.to_h)
    message
  rescue StandardError => e
    Rails.logger.warn(
      "[SystemAuditNote] failed conversation=#{@conversation&.id} error=#{e.class}: #{e.message}"
    )
    nil
  end

  private

  def tweet?
    return false if @conversation.additional_attributes.blank?

    @conversation.additional_attributes['type'] == 'tweet'
  end
end
