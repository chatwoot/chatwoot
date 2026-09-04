#######################################
# To create an external channel reply service
# - Inherit this as the base class.
# - Implement `channel_class` method in your child class.
# - Implement `perform_reply` method in your child class.
# - Implement additional custom logic for your `perform_reply` method.
# - When required override the validation_methods.
# - Use Childclass.new.perform.
######################################
class Base::SendOnChannelService
  pattr_initialize [:message!]

  def perform
    validate_target_channel
    return unless outgoing_message?
    return if invalid_message?

    perform_reply
  end

  private

  delegate :conversation, to: :message
  delegate :contact, :contact_inbox, :inbox, to: :conversation
  delegate :channel, to: :inbox

  def channel_class
    raise 'Overwrite this method in child class'
  end

  def perform_reply
    raise 'Overwrite this method in child class'
  end

  def outgoing_message_originated_from_channel?
    # Prefer external_echo flag (set by WhatsApp, Facebook, Instagram, TikTok, Twitter).
    # Fall back to source_id for channels that haven't migrated yet (e.g. Telegram business mode),
    # but only if the message hasn't failed — failed messages retain source_id from the first attempt
    # and should be retried.
    message.content_attributes['external_echo'].present? || (message.source_id.present? && !message.failed?)
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end

  def invalid_message?
    # private notes aren't send to the channels
    # we should also avoid the case of message loops, when outgoing messages are created from channel
    # voice_call bubbles are call status indicators, not deliverable messages
    message.private? || outgoing_message_originated_from_channel? || message.content_type == 'voice_call'
  end

  def validate_target_channel
    raise 'Invalid channel service was called' if inbox.channel.class != channel_class
  end
end
