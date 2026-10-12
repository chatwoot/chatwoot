class Whatsapp::InteractiveMessages::RetryService
  def initialize(message)
    @message = message
  end

  def perform
    previous_state = @message.with_lock do
      validate_retry!
      state = retry_state
      @message.update!(
        status: :pending,
        source_id: nil,
        content_attributes: content_attributes_with_incremented_retry_count
      )
      state
    end

    enqueue(previous_state)
    @message
  end

  private

  def validate_retry!
    raise ArgumentError, 'Only failed messages can be retried' unless @message.failed?
    raise ArgumentError, 'Only outgoing messages can be retried' unless @message.outgoing?
    raise ArgumentError, 'Only WhatsApp Cloud interactive messages can use same-message retry' unless supported_cloud_interaction?
  end

  def retry_state
    {
      status: @message.status,
      source_id: @message.source_id,
      content_attributes: @message.content_attributes.deep_dup
    }
  end

  def enqueue(previous_state)
    SendReplyJob.perform_later(@message.id)
  rescue StandardError
    restore_retry_state(previous_state)
    raise
  end

  def restore_retry_state(previous_state)
    @message.with_lock do
      next unless @message.pending? && @message.source_id.nil?

      @message.update!(previous_state)
    end
  end

  def supported_cloud_interaction?
    channel = @message.inbox.channel
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud' &&
      Whatsapp::InteractiveMessages::Registry.implemented?(interactive_snapshot['type'])
  end

  def interactive_snapshot
    @message.content_attributes['whatsapp_interactive'].to_h
  end

  def content_attributes_with_incremented_retry_count
    attributes = @message.content_attributes.deep_dup
    delivery = attributes['whatsapp_delivery'].to_h
    delivery['retry_count'] = delivery.fetch('retry_count', 0).to_i + 1
    attributes['whatsapp_delivery'] = delivery
    attributes
  end
end
