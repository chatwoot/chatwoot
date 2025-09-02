class TrialExpiryCheckJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting trial expiry check job"
    
    expired_trials = Weave::Core::AccountPlan.expired_trials.includes(:account)
    
    expired_trials.find_each do |account_plan|
      Rails.logger.info "Processing expired trial for account #{account_plan.account.id}"
      
      begin
        suspend_account_access(account_plan)
        send_trial_expiry_notification(account_plan.account)
        
        Rails.logger.info "Successfully suspended account #{account_plan.account.id} due to trial expiry"
      rescue StandardError => e
        Rails.logger.error "Failed to process expired trial for account #{account_plan.account.id}: #{e.message}"
        raise e
      end
    end
    
    Rails.logger.info "Completed trial expiry check job. Processed #{expired_trials.count} expired trials"
  end

  private

  def suspend_account_access(account_plan)
    account = account_plan.account
    
    # Suspend the account plan
    account_plan.suspend!
    
    # Disable premium features
    disable_premium_features(account)
    
    # Cancel any active subscriptions
    cancel_active_subscriptions(account)
  end

  def disable_premium_features(account)
    startup_features = Enterprise::Billing::HandleStripeEventService::STARTUP_PLAN_FEATURES
    business_features = Enterprise::Billing::HandleStripeEventService::BUSINESS_PLAN_FEATURES  
    enterprise_features = Enterprise::Billing::HandleStripeEventService::ENTERPRISE_PLAN_FEATURES

    account.disable_features(*(startup_features + business_features + enterprise_features))
    account.save!
  end

  def cancel_active_subscriptions(account)
    account.subscriptions.where(status: ['active', 'trial', 'trialing']).find_each do |subscription|
      subscription.update!(status: 'canceled')
    end
  end

  def send_trial_expiry_notification(account)
    # Send notification to account administrators
    account.administrators.find_each do |admin|
      TrialExpiryMailer.trial_expired(admin, account).deliver_now
    rescue StandardError => e
      Rails.logger.error "Failed to send trial expiry notification to #{admin.email}: #{e.message}"
    end
  end
end