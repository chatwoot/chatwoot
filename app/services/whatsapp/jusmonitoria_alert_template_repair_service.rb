class Whatsapp::JusmonitoriaAlertTemplateRepairService
  def initialize(channel:, template_params:, template_id:, template_name:)
    @channel = channel
    @template_params = template_params
    @template_id = template_id
    @template_name = template_name
  end

  def call
    edit_result = edit_rejected_template
    return edit_result.merge(recreated_after_rejection: true) if edit_result[:success]

    delete_result = delete_template
    return delete_result unless delete_result[:success]

    create_fresh_template.merge(recreated_after_rejection: true)
  end

  private

  def create_fresh_template
    Whatsapp::TemplateCreatorService.new(@channel).create_template(@template_params)
  end

  def edit_rejected_template
    return { success: false, error: 'Template rejeitado sem ID na Meta' } if @template_id.blank?

    result = Whatsapp::TemplateCreatorService.new(@channel).update_template(@template_id, @template_params)
    Rails.logger.warn "JusMonitorIA WhatsApp rejected template edit failed: #{result[:error]}" unless result[:success]
    result
  end

  def delete_template
    meta_client.delete_template(name: @template_name).tap do |result|
      Rails.logger.error "JusMonitorIA WhatsApp template deletion failed: #{result[:error]}" unless result[:success]
    end
  end

  def meta_client
    @meta_client ||= Whatsapp::JusmonitoriaAlertTemplateMetaClient.new(@channel)
  end
end
