# Serviço para gerenciar planos de billing
class BillingPlanService
  def initialize(account)
    @account = account
  end

  # Criar ou atualizar plano para uma conta
  def assign_plan(plan_name, options = {})
    billing_plan = @account.billing_plan || @account.build_billing_plan

    billing_plan.assign_attributes(
      plan_name: plan_name,
      active: options[:active] != false,
      trial_ends_at: options[:trial_ends_at],
      stripe_customer_id: options[:stripe_customer_id],
      stripe_subscription_id: options[:stripe_subscription_id],
      payment_status: options[:payment_status] || 'active'
    )

    billing_plan.save!
    billing_plan
  end

  # Verificar se conta pode usar uma feature
  def can_use_feature?(feature)
    return true unless billing_plan # Se não tem plano, permite tudo (compatibilidade)

    billing_plan.has_feature?(feature)
  end

  # Verificar se conta pode adicionar um recurso
  def can_add_resource?(resource_type)
    return true unless billing_plan

    billing_plan.can_add?(resource_type)
  end

  # Obter limite de um recurso
  def resource_limit(resource_type)
    return -1 unless billing_plan # unlimited se não tem plano

    limit = billing_plan.plan_details.dig(:limits, resource_type)
    limit.nil? ? -1 : limit
  end

  # Obter uso atual de um recurso
  def current_usage(resource_type)
    return 0 unless billing_plan

    billing_plan.current_count(resource_type)
  end

  # Obter percentual de uso
  def usage_percentage(resource_type)
    return 0 unless billing_plan

    billing_plan.usage_percentage(resource_type)
  end

  # Verificar se está próximo do limite
  def near_limit?(resource_type, threshold = 80)
    return false unless billing_plan

    usage_percentage(resource_type) >= threshold
  end

  # Upgrade de plano
  def upgrade_plan(new_plan_name, options = {})
    return false unless billing_plan

    old_plan = billing_plan.plan_name
    success = billing_plan.upgrade_to!(new_plan_name)

    if success
      # Log da mudança
      Rails.logger.info "Account #{@account.id} upgraded from #{old_plan} to #{new_plan_name}"

      # Atualizar configurações adicionais se fornecidas
      billing_plan.update!(options) if options.any?
    end

    success
  end

  # Downgrade de plano
  def downgrade_plan(new_plan_name, _options = {})
    return false unless billing_plan

    # Verificar se o downgrade é válido
    return false unless can_downgrade_to?(new_plan_name)

    old_plan = billing_plan.plan_name
    success = billing_plan.upgrade_to!(new_plan_name)

    if success
      Rails.logger.info "Account #{@account.id} downgraded from #{old_plan} to #{new_plan_name}"

      # Verificar se precisa remover recursos excedentes
      enforce_plan_limits
    end

    success
  end

  # Verificar se pode fazer downgrade
  def can_downgrade_to?(new_plan_name)
    return false unless billing_plan

    new_plan = AccountBillingPlan::PLANS[new_plan_name]
    return false unless new_plan

    # Verificar se todos os recursos atuais cabem no novo plano
    new_plan[:limits].each do |resource, limit|
      next if limit == -1 # unlimited

      current_count = current_usage(resource)
      return false if current_count > limit
    end

    true
  end

  # Aplicar limites do plano (remover recursos excedentes)
  def enforce_plan_limits
    return unless billing_plan

    plan_details = billing_plan.plan_details

    # Verificar agentes
    agent_limit = plan_details.dig(:limits, :agents)
    if agent_limit != -1 && @account.account_users.count > agent_limit
      # Remover agentes excedentes (manter os mais antigos)
      excess_count = @account.account_users.count - agent_limit
      @account.account_users.order(:created_at).limit(excess_count).destroy_all
    end

    # Verificar inboxes
    inbox_limit = plan_details.dig(:limits, :inboxes)
    return unless inbox_limit != -1 && @account.inboxes.count > inbox_limit

    excess_count = @account.inboxes.count - inbox_limit
    @account.inboxes.order(:created_at).limit(excess_count).destroy_all
  end

  # Obter estatísticas do plano
  def plan_stats
    return {} unless billing_plan

    {
      plan_name: billing_plan.plan_name,
      plan_details: billing_plan.plan_details,
      usage: {
        agents: {
          current: current_usage(:agents),
          limit: resource_limit(:agents),
          percentage: usage_percentage(:agents)
        },
        inboxes: {
          current: current_usage(:inboxes),
          limit: resource_limit(:inboxes),
          percentage: usage_percentage(:inboxes)
        },
        conversations_per_month: {
          current: current_usage(:conversations_per_month),
          limit: resource_limit(:conversations_per_month),
          percentage: usage_percentage(:conversations_per_month)
        }
      }
    }
  end

  private

  def billing_plan
    @billing_plan ||= @account.billing_plan
  end
end
