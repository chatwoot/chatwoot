class Crm::SetupJob < ApplicationJob
  queue_as :default

  def perform(hook_id)
    hook = Integrations::Hook.find_by(id: hook_id)

    return if hook.blank? || hook.disabled?

    begin
      setup_service = create_setup_service(hook)
      return if setup_service.nil?

      setup_service.setup
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: hook.account).capture_exception
      Rails.logger.error "Error in CRM setup for hook ##{hook_id} (#{hook.app_id}): #{e.message}"
    end
  end

  private

  def create_setup_service(hook)
    case hook.app_id
    when 'leadsquared'
      Crm::Leadsquared::SetupService.new(hook)
    # Add cases for future CRMs here
    # when 'hubspot'
    #   Crm::Hubspot::SetupService.new(hook)
    # when 'zoho'
    #   Crm::Zoho::SetupService.new(hook)
    else
      Rails.logger.error "Unsupported CRM app_id: #{hook.app_id}"
      nil
    end
  end
end
