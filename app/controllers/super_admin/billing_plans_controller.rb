# Controller para gerenciar planos de billing (Super Admin)
class SuperAdmin::BillingPlansController < SuperAdmin::ApplicationController
  helper BillingPlansHelper
  before_action :set_account, except: [:index]

  def index
    @accounts = Account.includes(:billing_plan).limit(50)
  end

  def show
    @billing_service = BillingPlanService.new(@account)
    @plan_stats = @billing_service.plan_stats
    @available_plans = AccountBillingPlan::PLANS
  end

  def update
    @billing_service = BillingPlanService.new(@account)

    if @billing_service.upgrade_plan(plan_params[:plan_name], plan_params.except(:plan_name))
      redirect_to super_admin_account_billing_plan_path(@account), notice: I18n.t('super_admin.billing_plans.update.success')
    else
      @plan_stats = @billing_service.plan_stats
      @available_plans = AccountBillingPlan::PLANS
      flash.now[:alert] = I18n.t('super_admin.billing_plans.update.failure')
      render :show
    end
  end

  def usage
    @billing_service = BillingPlanService.new(@account)
    @plan_stats = @billing_service.plan_stats

    render json: @plan_stats
  end

  def pause
    @billing_service = BillingPlanService.new(@account)

    if @billing_service.pause_plan
      redirect_to super_admin_accounts_path, notice: I18n.t('super_admin.billing_plans.pause.success')
    else
      redirect_to super_admin_accounts_path, alert: I18n.t('super_admin.billing_plans.pause.failure')
    end
  end

  def resume
    @billing_service = BillingPlanService.new(@account)

    if @billing_service.resume_plan
      redirect_to super_admin_accounts_path, notice: I18n.t('super_admin.billing_plans.resume.success')
    else
      redirect_to super_admin_accounts_path, alert: I18n.t('super_admin.billing_plans.resume.failure')
    end
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def plan_params
    params.require(:billing_plan).permit(:plan_name, :trial_ends_at, :stripe_customer_id, :stripe_subscription_id, :payment_status)
  end
end
