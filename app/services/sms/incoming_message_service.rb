class Sms::IncomingMessageService
  include ::FileTypeHelper

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation
    @message = @conversation.messages.create!(
      content: params[:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:id]
    )
    attach_files
    @message.save!
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def phone_number
    params[:from]
  end

  def formatted_phone_number
    TelephoneNumber.parse(phone_number).international_number
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:from],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: formatted_phone_number,
      phone_number: phone_number
    }
  end

  def attach_files
    return if params[:media].blank?

    params[:media].each do |media_url|
      # we don't need to process this files since chatwoot doesn't support it
      next if media_url.end_with?('.smil', '.xml')

      download_media(media_url) do |io, filename, content_type|
        @message.attachments.new(
          account_id: @message.account_id,
          file_type: file_type(content_type),
          file: { io: io, filename: filename, content_type: content_type }
        )
      end
    end
  end

  # Provider media comes from a known host and is fetched directly with credentials.
  # Any other URL from the payload is fetched through SafeFetch so it cannot reach
  # internal addresses.
  def download_media(media_url)
    if provider_hosted?(media_url)
      file = Down.download(media_url, http_basic_authentication: provider_credentials, max_redirects: 0)
      yield file, file.original_filename, file.content_type
    else
      # SafeFetch closes its tempfile when the block returns, but the attachment is
      # uploaded later on save!, so stream the contents into a tempfile that survives.
      SafeFetch.fetch(media_url, validate_content_type: false) do |result|
        yield persisted_copy(result.tempfile), result.original_filename, result.content_type
      end
    end
    # Skip only unsafe/permanent failures; let transient errors (timeout, 5xx) raise
    # so the job retries, as before this change.
  rescue SafeFetch::UnsafeUrlError, SafeFetch::InvalidUrlError, SafeFetch::FileTooLargeError, SafeFetch::UnsupportedContentTypeError => e
    Rails.logger.warn("[SMS] skipping media download: #{e.class}")
  end

  def provider_credentials
    [channel.provider_config['api_key'], channel.provider_config['api_secret']]
  end

  # Copy the streamed download into a tempfile that outlives the SafeFetch block
  # (cleaned up on GC), without buffering the whole file in memory.
  def persisted_copy(source)
    tempfile = Tempfile.new('sms-media', binmode: true)
    IO.copy_stream(source, tempfile)
    tempfile.rewind
    tempfile
  end

  # Attach credentials only to the provider's exact configured endpoint: same
  # scheme, host and port, and no embedded userinfo. Anything else from the
  # payload is treated as untrusted and fetched without credentials.
  def provider_hosted?(media_url)
    uri = URI.parse(media_url)
    uri.userinfo.nil? && uri.scheme == provider_uri.scheme &&
      uri.port == provider_uri.port && provider_uri.host.casecmp?(uri.host.to_s)
  rescue URI::InvalidURIError
    false
  end

  def provider_uri
    @provider_uri ||= URI.parse(channel.api_base_path)
  end
end
