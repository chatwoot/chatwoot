class Whatsapp::JusmonitoriaAlertTemplateService
  TEMPLATE_NAME = 'alerta_movimentacao_processual_v1'.freeze
  TEMPLATE_CATEGORY = 'UTILITY'.freeze
  TEMPLATE_LANGUAGE = 'pt_BR'.freeze
  TEMPLATE_BODY = <<~BODY.strip.freeze
    ⚖️ Atualização processual

    O JusMonitorIA identificou novas movimentações nos processos que você acompanha:

    {{lista_processos}}
  BODY

  def initialize(inbox)
    @inbox = inbox
    @channel = inbox.channel
  end

  def status
    return non_whatsapp_status unless @inbox.whatsapp?
    return evolution_go_status if evolution_go_provider?
    return unsupported_whatsapp_status unless whatsapp_cloud_provider?

    refresh_templates
    cloud_template_status
  end

  def create
    current_status = status
    return current_status.merge(created: false) unless current_status[:template_required]
    return current_status.merge(created: false) if %w[approved pending].include?(current_status[:template_status])

    result = Whatsapp::TemplateCreatorService.new(@channel).create_template(template_params)
    return created_status(result) if result[:success]
    return status.merge(created: false, already_exists: true) if already_exists_error?(result)

    current_status.merge(
      created: false,
      error: result[:error],
      response_code: result[:response_code],
      delivery_locked: true
    )
  end

  private

  def template_params
    {
      name: TEMPLATE_NAME,
      category: TEMPLATE_CATEGORY,
      language: TEMPLATE_LANGUAGE,
      body_text: TEMPLATE_BODY
    }
  end

  def cloud_template_status
    template = find_template
    template_status = template ? template['status'].to_s.downcase : 'missing'

    base_status.merge(
      template_required: true,
      template_status: template_status,
      template_id: template&.dig('id'),
      template_category: template_category(template),
      delivery_locked: template_status != 'approved',
      service_error: @refresh_error
    ).compact
  end

  def created_status(result)
    base_status.merge(
      template_required: true,
      template_status: result[:status].to_s.downcase.presence || 'pending',
      template_id: result[:template_id],
      template_category: result[:category].presence,
      delivery_locked: true,
      created: true
    ).compact
  end

  def base_status
    {
      provider: provider,
      template_name: TEMPLATE_NAME,
      category: TEMPLATE_CATEGORY,
      requested_category: TEMPLATE_CATEGORY,
      language: TEMPLATE_LANGUAGE
    }
  end

  def evolution_go_status
    base_status.merge(
      template_required: false,
      template_status: 'not_required',
      delivery_locked: false
    )
  end

  def unsupported_whatsapp_status
    base_status.merge(
      template_required: false,
      template_status: 'unsupported_provider',
      delivery_locked: false
    )
  end

  def non_whatsapp_status
    base_status.merge(
      provider: nil,
      template_required: false,
      template_status: 'not_whatsapp',
      delivery_locked: false
    )
  end

  def find_template
    Array(@channel.message_templates).find do |template|
      template['name'] == TEMPLATE_NAME && template['language'].to_s.casecmp(TEMPLATE_LANGUAGE).zero?
    end
  end

  def template_category(template)
    template&.dig('category').presence || template&.dig('template_category').presence
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
