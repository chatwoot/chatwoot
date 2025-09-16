# Concern para verificar limites de plano em modelos
module BillingPlanLimitable
  extend ActiveSupport::Concern

  included do
    # Callback para verificar limites antes de criar
    before_create :check_billing_plan_limits
  end

  private

  def check_billing_plan_limits
    return unless account&.billing_plan

    billing_service = BillingPlanService.new(account)

    # Determinar o tipo de recurso baseado no modelo
    resource_type = determine_resource_type

    return if billing_service.can_add_resource?(resource_type)

    limit = billing_service.resource_limit(resource_type)
    current = billing_service.current_usage(resource_type)

    errors.add(:base, "Plano atual permite apenas #{limit} #{resource_type}. " \
                      "Atual: #{current}. Upgrade seu plano para adicionar mais.")

    throw(:abort)
  end

  def determine_resource_type
    case self.class.name
    when 'AccountUser'
      :agents
    when 'Inbox'
      :inboxes
    when 'Conversation'
      :conversations
    when 'Contact'
      :contacts
    else
      :unknown
    end
  end
end
