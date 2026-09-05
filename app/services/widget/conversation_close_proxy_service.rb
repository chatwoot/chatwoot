class Widget::ConversationCloseProxyService
  def initialize(conversation)
    @conversation = conversation
  end

  def call
    return if Thread.current[:closing_proxy_chain]
    return unless should_cascade_close?

    Thread.current[:closing_proxy_chain] = true
    close_all_linked_proxy_conversations
  rescue StandardError => e
    Rails.logger.error(
      "[CloseProxyService] failed for conversation ##{@conversation.id}: #{e.class} - #{e.message}\n" \
      "#{e.backtrace.first(10).join("\n")}"
    )
  ensure
    Thread.current[:closing_proxy_chain] = nil
  end

  private

  def should_cascade_close?
    return false if @conversation.proxied?
    return false unless @conversation.resolved?

    root_widget_id = @conversation.additional_attributes&.dig('source_widget_id')
    return false if root_widget_id.blank?

    other_active = Conversation
      .where("additional_attributes->>'source_widget_id' = ?", root_widget_id.to_s)
      .where(status: [:open, :pending])
      .where.not(id: @conversation.id)
      .exists?

    !other_active
  end

  def close_all_linked_proxy_conversations
    root_widget_id = @conversation.additional_attributes&.dig('source_widget_id')
    return if root_widget_id.blank?

    root_widget = Conversation.find_by(id: root_widget_id)
    return if root_widget.blank?

    close_conversation_chain(root_widget)
  end

  def close_conversation_chain(start_conversation)
    visited = Set.new
    queue = [start_conversation]

    while queue.present?
      conv = queue.shift
      next if conv.blank? || visited.include?(conv.id)

      visited << conv.id

      if conv.open? || conv.pending? || conv.proxied?
        previous_status = conv.status
        conv.update!(status: :resolved)
        Rails.logger.info("[CloseProxyService] closed conversation ##{conv.id} (was #{previous_status})")
      end

      linked_id = conv.additional_attributes&.dig('linked_conversation_id')
      if linked_id.present? && !visited.include?(linked_id)
        linked = Conversation.find_by(id: linked_id)
        queue << linked if linked.present?
      end

      Conversation
        .where("additional_attributes->>'source_widget_id' = ?", conv.id.to_s)
        .where.not(id: visited.to_a)
        .find_each { |c| queue << c }
    end
  end
end
