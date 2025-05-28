class Instagram::ReadStatusService
  pattr_initialize [:params!, :channel!]

  def perform
    return if channel.blank?

    ::Conversations::UpdateMessageStatusJob.perform_later(message.conversation.id, message.created_at) if message.present?
  end

  def instagram_id
    params[:recipient][:id]
  end

  def message
    return unless params[:read][:mid]

    @message ||= @channel.inbox.messages.find_by(source_id: params[:read][:mid])
  end
end
