module Api::V1::Accounts::Concerns::EmailChannelCreation
  extend ActiveSupport::Concern

  private

  def validate_new_email_channel
    return unless params.dig(:channel, :type) == 'email'

    validate_email_channel(Channel::Email::EDITABLE_ATTRS)
  rescue StandardError => e
    render json: { message: e }, status: :unprocessable_entity
  end

  def enqueue_initial_imap_fetch
    return unless @inbox.channel.is_a?(Channel::Email)
    return unless @inbox.channel.imap_fetchable?

    ::Inboxes::FetchImapEmailsJob.perform_later(@inbox.channel)
  end
end
