class Autonomia::Prospecting::LeadEnricher
  class Error < StandardError; end

  AI_SCHEMA = {
    name: 'autonomia_prospecting_lead_enrichment',
    schema: {
      type: 'object',
      additionalProperties: false,
      properties: {
        decision_name: { type: %w[string null] },
        decision_role: { type: %w[string null] },
        decision_confidence: { type: 'number', minimum: 0, maximum: 1 },
        decision_source_url: { type: %w[string null] },
        decision_linkedin: { type: %w[string null] },
        decision_instagram: { type: %w[string null] },
        summary: { type: %w[string null] },
        signals: {
          type: 'array',
          items: { type: 'string' }
        }
      },
      required: [
        'decision_name',
        'decision_role',
        'decision_confidence',
        'decision_source_url',
        'decision_linkedin',
        'decision_instagram',
        'summary',
        'signals'
      ]
    }
  }.freeze

  def initialize(lead:, user:)
    @lead = lead
    @user = user
    @setting = Autonomia::Prospecting::Setting.for_account(lead.account)
  end

  def perform
    raise Error, 'prospecting.enrichment.disabled' unless @setting.enrichment_enabled?

    @lead.update!(
      enrichment_status: 'running',
      enrichment_requested_at: Time.current,
      enrichment_error: nil
    )

    scraped_data = scrape_website
    ai_data = enrich_with_ai(scraped_data)
    persist_result(scraped_data, ai_data)
    @lead.reload
  rescue Error => e
    mark_failed(e.message)
    raise
  rescue StandardError => e
    mark_failed(e.message)
    raise Error, e.message
  end

  private

  def scrape_website
    return {} if @lead.website.blank?

    Autonomia::Prospecting::WebsiteScraper.new(url: @lead.website).perform.data
  end

  def enrich_with_ai(scraped_data)
    credential = Crm::Ai::CredentialResolver.new(account: @lead.account).resolve
    return {} if credential.blank?

    raw = Crm::Ai::ResponsesClient.new(
      credential: credential,
      feature: 'prospecting_lead_enrichment',
      account: @lead.account
    ).create(
      model: Crm::Ai::Config::MODEL_SUMMARY,
      instructions: instructions,
      input: ai_input(scraped_data),
      schema: AI_SCHEMA,
      reasoning_effort: Crm::Ai::Config::SUMMARY_REASONING_EFFORT,
      tools: Crm::Ai::WebSearch.tools,
      timeout: 90
    )
    parsed = JSON.parse(raw[:text])
    parsed.is_a?(Hash) ? parsed : {}
  rescue Crm::Ai::ResponsesClient::Error, JSON::ParserError => e
    Rails.logger.warn(
      "[Autonomia::Prospecting] lead enrichment AI skipped lead_id=#{@lead.id} error=#{e.class.name}"
    )
    {}
  end

  def instructions
    <<~PROMPT
      Você enriquece leads B2B brasileiros para prospecção comercial.

      Regras:
      - Retorne somente JSON no schema solicitado.
      - Não invente nomes, cargos, redes sociais ou fontes.
      - Preencha decisor apenas se houver fonte explícita no site ou em busca web.
      - decision_confidence deve ser 0 quando não houver decisor.
      - Use decision_source_url apenas quando a fonte sustentar o decisor.
      - O resumo deve ser curto, objetivo e útil para abordagem comercial.
    PROMPT
  end

  def ai_input(scraped_data)
    {
      lead: {
        name: @lead.name,
        website: @lead.website,
        phone: @lead.phone,
        address: @lead.address,
        city: @lead.city,
        state: @lead.state,
        category: @lead.category,
        rating: @lead.rating,
        reviews_count: @lead.reviews_count
      },
      scraped_site_data: scraped_data.slice(
        'title',
        'description',
        'email',
        'phone',
        'whatsapp',
        'instagram',
        'facebook',
        'linkedin',
        'cnpj',
        'text_excerpt',
        'source_urls'
      )
    }.to_json
  end

  def persist_result(scraped_data, ai_data)
    data = scraped_data.merge('ai' => ai_data.compact)
    @lead.update!(
      enrichment_status: 'completed',
      enrichment_completed_at: Time.current,
      enrichment_source: ai_data.present? ? 'site_and_autonomia_ai' : 'site',
      enriched_data: data,
      enriched_email: scraped_data['email'],
      enriched_whatsapp: scraped_data['whatsapp'],
      enriched_instagram: scraped_data['instagram'],
      enriched_facebook: scraped_data['facebook'],
      enriched_linkedin: scraped_data['linkedin'],
      enriched_cnpj: scraped_data['cnpj'],
      decision_name: confident_decision?(ai_data) ? ai_data['decision_name'] : nil,
      decision_role: confident_decision?(ai_data) ? ai_data['decision_role'] : nil,
      decision_confidence: ai_data['decision_confidence'],
      decision_source_url: confident_decision?(ai_data) ? ai_data['decision_source_url'] : nil,
      decision_linkedin: ai_data['decision_linkedin'].presence || scraped_data['linkedin'],
      decision_instagram: ai_data['decision_instagram'].presence || scraped_data['instagram'],
      enrichment_summary: ai_data['summary'].presence || summary_from_scrape(scraped_data)
    )
  end

  def confident_decision?(ai_data)
    ai_data['decision_name'].present? && ai_data['decision_confidence'].to_f >= 0.6
  end

  def summary_from_scrape(scraped_data)
    return if scraped_data.blank? || scraped_data['error'].present?

    [scraped_data['title'], scraped_data['description']].compact_blank.join(' - ').presence
  end

  def mark_failed(message)
    @lead.update_columns(
      enrichment_status: 'failed',
      enrichment_completed_at: Time.current,
      enrichment_error: message.to_s.truncate(255),
      updated_at: Time.current
    )
  rescue StandardError
    nil
  end
end
