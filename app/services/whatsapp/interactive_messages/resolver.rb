class Whatsapp::InteractiveMessages::Resolver
  class << self
    def message_params(conversation, params, content_attributes)
      attributes = content_attributes.deep_stringify_keys
      return {} unless attributes.key?('whatsapp_interactive')

      interactive = attributes['whatsapp_interactive']
      return {} if location_request?(interactive)

      validate_provenance!(params, attributes)
      validate_message_lane!(params)
      resolved = new(conversation: conversation, payload: interactive).perform
      validate_uploads!(params, resolved, conversation.account_id)
      { content: resolved.dig('body', 'text'), content_attributes: attributes.merge('whatsapp_interactive' => resolved) }
    end

    def persist!(message)
      return message.save! unless message.content_attributes.dig('whatsapp_interactive', 'type') == 'button'

      validate_attachment!(message)
      Message.transaction do
        message.save!
        finalize_attachment!(message)
      end
    end

    private

    def validate_attachment!(message)
      header = message.content_attributes.dig('whatsapp_interactive', 'header')
      return unless header && header['type'] != 'text'

      attachment = message.attachments.first
      return if Whatsapp::InteractiveMessages::Registry.matching_media?(header['type'], attachment)

      raise Whatsapp::InteractiveMessages::ValidationError, 'whatsapp_interactive header upload must match the selected media type'
    end

    def finalize_attachment!(message)
      header = message.content_attributes.dig('whatsapp_interactive', 'header')
      return unless header && header['type'] != 'text'

      header['attachment_id'] = message.attachments.first.id
      # The validated snapshot must be complete before create callbacks dispatch, without firing update callbacks.
      message.update_columns(content_attributes: message.content_attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    def location_request?(interactive)
      interactive.is_a?(Hash) && interactive['type'] == 'location_request_message'
    end

    def validate_provenance!(params, attributes)
      return if params[:template_params].blank? && attributes['automation_rule_id'].blank?

      raise Whatsapp::InteractiveMessages::ValidationError,
            'whatsapp_interactive cannot include template or automation provenance'
    end

    def validate_message_lane!(params)
      message_type = params[:message_type] || 'outgoing'
      private_message = ActiveModel::Type::Boolean.new.cast(params[:private])
      valid_content_type = params[:content_type].blank? || params[:content_type] == 'text'
      return if message_type == 'outgoing' && !private_message && valid_content_type

      raise Whatsapp::InteractiveMessages::ValidationError,
            'whatsapp_interactive is only available for public outgoing text messages'
    end

    def validate_uploads!(params, resolved, account_id)
      header_type = resolved.dig('header', 'type')
      media_header = %w[image video document].include?(header_type)
      uploads = params[:attachments] || []
      valid_count = uploads.is_a?(Array) && uploads.length == (media_header ? 1 : 0)
      unless valid_count
        raise Whatsapp::InteractiveMessages::ValidationError, 'whatsapp_interactive requires exactly one upload for media headers and none otherwise'
      end
      return unless media_header

      validate_upload!(uploads.first, account_id)
    end

    def validate_upload!(upload, account_id)
      return validate_blob_upload!(upload, account_id) if upload.is_a?(String)
      return if upload.respond_to?(:content_type) && upload.respond_to?(:original_filename) && upload.respond_to?(:tempfile)

      raise Whatsapp::InteractiveMessages::ValidationError, 'whatsapp_interactive header requires a message upload'
    end

    def validate_blob_upload!(upload, account_id)
      blob = ActiveStorage::Blob.find_signed(upload)
      return if blob&.attachments&.all? { |association| association.record.is_a?(Attachment) && association.record.account_id == account_id }

      raise Whatsapp::InteractiveMessages::ValidationError, 'whatsapp_interactive header upload is invalid or belongs to another account'
    end
  end

  def initialize(conversation:, payload:)
    @conversation = conversation
    @payload = payload
  end

  def perform
    resolved = Whatsapp::InteractiveMessages::Registry.resolve(@payload)
    Whatsapp::InteractiveMessages::Eligibility.new(@conversation).ensure_available!(resolved['type'])
    resolved
  end
end
