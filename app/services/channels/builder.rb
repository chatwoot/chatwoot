# Centralized channel + inbox creation. Every channel creation flow (the generic
# inbox creation endpoint, WhatsApp embedded signup, OAuth callbacks) routes
# through here so there is a single, validated entry point. The channel class is
# resolved from the create-slug via Channel::Registry, and the channel owns its
# own editable attributes.
class Channels::Builder
  # Create a channel (and optionally its inbox) for the given account.
  #
  #   account:            the owning account
  #   param_type:         create-slug (e.g. 'whatsapp') resolved via Channel::Registry
  #   channel_attributes: channel fields to set (validated against the channel)
  #   inbox_name:         optional inbox name; when provided an inbox is created
  #   inbox_attributes:   extra inbox fields merged into the created inbox
  #
  # Returns the created channel.
  def self.create!(account:, param_type:, channel_attributes:, inbox_name: nil, inbox_attributes: {})
    channel_class = Channel::Registry.channel_class_for(param_type)
    raise CustomExceptions::Channel::Unsupported, param_type unless channel_class

    ActiveRecord::Base.transaction do
      channel = channel_class.create!(channel_attributes.merge(account: account))
      create_inbox(account, channel, inbox_name, inbox_attributes)
      channel
    end
  end

  def self.create_inbox(account, channel, inbox_name, inbox_attributes)
    return if inbox_name.blank? && inbox_attributes.blank?

    inbox_params = inbox_attributes.merge(channel: channel, account: account)
    inbox_params[:name] = inbox_name if inbox_name.present?

    Inbox.create!(inbox_params)
  end
  private_class_method :create_inbox
end
