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
      { content: resolved.dig('body', 'text'), content_attributes: attributes.merge('whatsapp_interactive' => resolved) }
    end

    private

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
      return if message_type == 'outgoing' && !private_message && params[:attachments].blank? && valid_content_type

      raise Whatsapp::InteractiveMessages::ValidationError,
            'whatsapp_interactive is only available for public outgoing text messages without attachments'
    end
  end

  def initialize(conversation:, payload:)
    @conversation = conversation
    @payload = payload
  end

  def perform
    Whatsapp::InteractiveMessages::Eligibility.new(@conversation).ensure_available!
    Whatsapp::InteractiveMessages::Registry.resolve(@payload)
  end
end
