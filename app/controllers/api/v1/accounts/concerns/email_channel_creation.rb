module Api::V1::Accounts::Concerns::EmailChannelCreation
  extend ActiveSupport::Concern

  private

  def validate_new_email_channel
    return unless params.dig(:channel, :type) == 'email'

    initial_imap_fetch_interval if params.key?(:imap_fetch_interval)
    validate_email_channel(Channel::Email::EDITABLE_ATTRS)
  rescue StandardError => e
    render json: { message: e }, status: :unprocessable_entity
  end

  def enqueue_initial_imap_fetch
    return unless @inbox.channel.is_a?(Channel::Email)
    return unless @inbox.channel.imap_fetchable?

    ::Inboxes::FetchImapEmailsJob.perform_later(@inbox.channel, initial_imap_fetch_interval)
  end

  def initial_imap_fetch_interval
    return 1 unless params.key?(:imap_fetch_interval)

    interval = params[:imap_fetch_interval]
    raise ActionController::ParameterMissing, :imap_fetch_interval unless interval.is_a?(Integer) && [1, 7, 30].include?(interval)

    interval
  end
end
