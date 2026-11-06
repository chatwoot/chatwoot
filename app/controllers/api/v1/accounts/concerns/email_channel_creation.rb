module Api::V1::Accounts::Concerns::EmailChannelCreation
  extend ActiveSupport::Concern

  private

  def validate_new_email_channel
    return unless params.dig(:channel, :type) == 'email'

    attributes = permitted_params(Channel::Email::EDITABLE_ATTRS)[:channel].except(:type)
    channel_data = Channel::Email.new(attributes).attributes.with_indifferent_access
    validate_imap(channel_data)
    validate_smtp(channel_data)
  rescue StandardError => e
    render json: { message: e }, status: :unprocessable_entity
  end

  def enqueue_initial_imap_fetch
    return unless @inbox.channel.is_a?(Channel::Email)
    return unless @inbox.channel.imap_fetchable?

    ::Inboxes::FetchImapEmailsJob.perform_later(@inbox.channel)
  end
end
