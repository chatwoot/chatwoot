class SuperAdmin::SaasPlansController < SuperAdmin::ApplicationController
  def resource_class
    Saas::Plan
  end

  def resource_name
    'saas_plan'
  end

  def find_resource(param)
    Saas::Plan.find(param)
  end

  private

  def dashboard
    @dashboard ||= SaasPlanDashboard.new
  end

  def resource_params
    params.require(:saas_plan).permit(
      :name, :stripe_product_id, :stripe_price_id,
      :price_cents, :interval, :agent_limit, :inbox_limit,
      :ai_tokens_monthly, :active
    )
  end
end
