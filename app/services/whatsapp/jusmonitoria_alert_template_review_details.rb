class Whatsapp::JusmonitoriaAlertTemplateReviewDetails
  TEMPLATE_STATUS_FIELDS = 'id,name,status,category,language,rejected_reason,components,parameter_format,quality_score'.freeze

  attr_reader :refresh_error

  def initialize(channel:, template_name:, template_language:)
    @channel = channel
    @template_name = template_name
    @template_language = template_language
  end

  def enrich(template)
    return template unless template_needs_review_details?(template)

    fetch_template_details || template
  end

  private

  def template_needs_review_details?(template)
    return false if template.blank?
    return true if template_parameter_format(template).blank?

    template['status'].to_s.casecmp('REJECTED').zero? && rejected_reason(template).blank?
  end

  def fetch_template_details
    result = meta_client.fetch_template_details(
      name: @template_name,
      language: @template_language,
      fields: TEMPLATE_STATUS_FIELDS
    )
    @refresh_error = result[:error] unless result[:success]
    result[:template]
  end

  def template_parameter_format(template)
    template&.dig('parameter_format').presence || template&.dig('template_parameter_format').presence
  end

  def rejected_reason(template)
    template&.dig('rejected_reason').presence || template&.dig('rejection_reason').presence
  end

  def meta_client
    @meta_client ||= Whatsapp::JusmonitoriaAlertTemplateMetaClient.new(@channel)
  end
end
