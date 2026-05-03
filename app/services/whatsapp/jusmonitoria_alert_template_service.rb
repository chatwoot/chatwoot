class Whatsapp::JusmonitoriaAlertTemplateService
  TemplateDefinition = Whatsapp::JusmonitoriaAlertTemplateDefinition

  def initialize(inbox, template_name: nil)
    @inbox = inbox
    @channel = inbox.channel
    @template_name = normalize_template_name(template_name)
  end

  def status
    return passive_template_status('not_whatsapp', nil) unless @inbox.whatsapp?
    return passive_template_status('not_required') if evolution_go_provider?
    return passive_template_status('unsupported_provider') unless whatsapp_cloud_provider?

    refresh_templates
    cloud_template_status
  end

  def create
    current_status = status
    return current_status.merge(created: false) unless current_status[:template_required]
    return current_status.merge(created: false) if %w[approved pending].include?(current_status[:template_status])

    result = create_template_after_optional_repair(current_status)
    return created_status(result, recreated_after_rejection: result[:recreated_after_rejection]) if result[:success]
    return status.merge(created: false, already_exists: true) if already_exists_error?(result)

    failed_create_status(current_status, result)
  end

  private

  def template_params
    definition = template_definition
    definition
      .slice(:category, :parameter_format, :body_text, :header_format, :header_media_url, :footer_text,
             :allow_category_change)
      .merge(name: @template_name, language: TemplateDefinition::LANGUAGE)
      .compact
  end

  def create_template_after_optional_repair(current_status)
    return create_fresh_template unless current_status[:template_status] == 'rejected'

    Whatsapp::JusmonitoriaAlertTemplateRepairService.new(
      channel: @channel,
      template_params: template_params,
      template_id: current_status[:template_id],
      template_name: @template_name
    ).call
  end

  def create_fresh_template
    Whatsapp::TemplateCreatorService.new(@channel).create_template(template_params)
  end

  def failed_create_status(current_status, result)
    current_status.merge(
      created: false,
      error: result[:error],
      response_code: result[:response_code],
      meta_error_code: result[:meta_error_code],
      meta_error_subcode: result[:meta_error_subcode],
      meta_error_title: result[:meta_error_title],
      meta_error_message: result[:meta_error_message],
      meta_error_user_msg: result[:meta_error_user_msg],
      meta_fbtrace_id: result[:meta_fbtrace_id],
      delivery_locked: true
    ).compact
  end

  def normalize_template_name(template_name)
    candidate = template_name.to_s.presence || TemplateDefinition::NAME
    return candidate if candidate.match?(TemplateDefinition::NAME_PATTERN)

    TemplateDefinition::NAME
  end

  def template_definition
    TemplateDefinition::DEFINITIONS[@template_name] ||
      TemplateDefinition::DEFINITIONS[TemplateDefinition::NAME]
  end

  def cloud_template_status
    template = template_with_review_details
    template_status = template ? template['status'].to_s.downcase : 'missing'

    base_status.merge(
      template_required: true,
      template_status: template_status,
      template_id: template&.dig('id'),
      rejected_reason: rejected_reason(template),
      available_templates: catalog.available_templates,
      delivery_locked: template_status != 'approved',
      service_error: @refresh_error || review_details.refresh_error
    ).merge(template_metadata(template)).compact
  end

  def created_status(result, recreated_after_rejection: false)
    base_status.merge(
      template_required: true,
      template_status: result[:status].to_s.downcase.presence || 'pending',
      template_id: result[:template_id],
      template_category: result[:category].presence,
      template_parameter_format: result[:parameter_format].presence ||
        TemplateDefinition::PARAMETER_FORMAT,
      template_body_text: template_definition[:body_text],
      template_header_format: template_definition[:header_format],
      template_header_media_url: template_definition[:header_media_url],
      template_footer_text: template_definition[:footer_text],
      available_templates: catalog.available_templates,
      delivery_locked: true,
      created: true,
      recreated_after_rejection: recreated_after_rejection
    ).compact
  end

  def base_status
    {
      provider: provider,
      template_name: @template_name,
      category: TemplateDefinition::CATEGORY,
      requested_category: TemplateDefinition::CATEGORY,
      language: TemplateDefinition::LANGUAGE
    }
  end

  def passive_template_status(template_status, provider_value = provider)
    base_status.merge(
      provider: provider_value,
      template_required: false,
      template_status: template_status,
      delivery_locked: false
    )
  end

  def find_template
    Array(@channel.message_templates).find do |template|
      template['name'] == @template_name &&
        template['language'].to_s.casecmp(TemplateDefinition::LANGUAGE).zero?
    end
  end

  def template_with_review_details
    template = find_template
    review_details.enrich(template)
  end

  def rejected_reason(template)
    template&.dig('rejected_reason').presence || template&.dig('rejection_reason').presence
  end

  def template_metadata(template)
    {
      template_category: catalog.template_category(template) || template_definition[:category],
      template_parameter_format: catalog.template_parameter_format(template) || template_definition[:parameter_format],
      template_body_text: catalog.template_body_text(template) || template_definition[:body_text],
      template_header_format: catalog.template_header_format(template, name: @template_name),
      template_header_media_url: catalog.template_header_media_url(template, name: @template_name),
      template_footer_text: catalog.template_footer_text(template, name: @template_name)
    }
  end

  def refresh_templates
    @refresh_error = nil
    @channel.sync_templates
    @channel.reload
  rescue StandardError => e
    @refresh_error = e.message
  end

  def provider
    @channel.respond_to?(:provider) ? @channel.provider : nil
  end

  def review_details
    @review_details ||= Whatsapp::JusmonitoriaAlertTemplateReviewDetails.new(
      channel: @channel,
      template_name: @template_name,
      template_language: TemplateDefinition::LANGUAGE
    )
  end

  def catalog
    @catalog ||= Whatsapp::JusmonitoriaAlertTemplateCatalog.new(channel: @channel,
                                                                definitions: TemplateDefinition::DEFINITIONS,
                                                                prefix: TemplateDefinition::PREFIX,
                                                                pattern: TemplateDefinition::NAME_PATTERN,
                                                                language: TemplateDefinition::LANGUAGE)
  end

  def whatsapp_cloud_provider?
    provider == 'whatsapp_cloud'
  end

  def evolution_go_provider?
    provider == 'evolution_go'
  end

  def already_exists_error?(result)
    result[:error].to_s.downcase.include?('already exists') ||
      result[:error].to_s.downcase.include?('duplicate')
  end
end
