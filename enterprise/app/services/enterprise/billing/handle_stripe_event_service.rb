class Enterprise::Billing::HandleStripeEventService
  include BillingPlans

  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  def perform(event:)
    @event = event

    case @event.type
    when 'customer.subscription.updated'
      process_subscription_updated
    when 'customer.subscription.deleted'
      process_subscription_deleted
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end
  end

  private

  def process_subscription_updated
    return if account.blank?

    Rails.logger.info "Processing subscription update for account #{account.id}"

    # Log cancellation details if present
    if subscription['cancel_at_period_end']
      Rails.logger.info "Subscription cancellation detected: cancel_at_period_end=#{subscription['cancel_at_period_end']}, canceled_at=#{subscription['canceled_at']}, cancel_at=#{subscription['cancel_at']}"
    end

    # For cloud installations, try to find the plan in cloud config
    cloud_plan = find_cloud_plan(subscription['plan']['product']) if subscription['plan'].present?

    if cloud_plan.present?
      # Cloud installation path
      Rails.logger.info "Processing cloud subscription update with plan: #{cloud_plan['name']}"
      update_account_attributes_from_cloud_plan(subscription, cloud_plan)
      sync_account_features_from_cloud_plan(cloud_plan)
    else
      # Self-hosted installation path - use billing_plans.yml
      plan_name = extract_plan_name_from_subscription(subscription)
      Rails.logger.info "Processing self-hosted subscription update with plan: #{plan_name}"

      if plan_name.present?
        update_account_attributes_from_self_hosted_plan(subscription, plan_name)
        sync_account_features_from_self_hosted_plan(plan_name)
      else
        Rails.logger.warn 'Could not determine plan name for subscription update'
      end
    end

    Rails.logger.info "Subscription update completed for account #{account.id}"
  end

  def process_cloud_subscription_updated(cloud_plan)
    update_account_attributes_from_cloud_plan(subscription, cloud_plan)
    update_plan_features
    reset_captain_usage
  end

  def process_self_hosted_subscription_updated
    # Extract plan information from Stripe subscription metadata or product/price mapping
    plan_name = extract_plan_name_from_subscription
    return if plan_name.blank?

    update_account_attributes_from_self_hosted_plan(subscription, plan_name)
    update_plan_features
    reset_captain_usage
  end

  def process_subscription_deleted
    return if account.blank?

    Rails.logger.info "Processing subscription deletion for account #{account.id}"

    # Update account attributes to reflect cancellation
    update_account_attributes_for_cancellation

    # Downgrade account to community plan
    downgrade_to_community_plan

    Rails.logger.info "Account #{account.id} downgraded to community plan due to subscription deletion"
  end

  def update_account_attributes_from_cloud_plan(subscription, cloud_plan)
    # Cloud-specific attribute updates using cloud plan configuration
    attributes_to_merge = {
      stripe_customer_id: subscription.customer,
      stripe_price_id: subscription['plan']['id'],
      stripe_product_id: subscription['plan']['product'],
      plan_name: cloud_plan['name'],
      subscribed_quantity: subscription['quantity'],
      subscription_status: subscription['status'],
      current_period_end: subscription['current_period_end'],
      subscription_ends_on: Time.zone.at(subscription['current_period_end']).strftime('%Y-%m-%d'),
      cancel_at_period_end: subscription['cancel_at_period_end'] || false,
      canceled_at: subscription['canceled_at'],
      ended_at: subscription['ended_at']
    }

    # If subscription is being cancelled, update the subscription_ends_on to the cancel_at date
    if subscription['cancel_at_period_end'] && subscription['cancel_at']
      attributes_to_merge[:subscription_ends_on] = Time.zone.at(subscription['cancel_at']).strftime('%Y-%m-%d')
    end

    account.update(
      custom_attributes: account.custom_attributes.merge(attributes_to_merge)
    )
  end

  def update_account_attributes_from_self_hosted_plan(subscription, plan_name)
    # Self-hosted attribute updates using billing_plans.yml
    attributes_to_merge = {
      stripe_customer_id: subscription.customer,
      stripe_price_id: subscription['plan']['id'],
      stripe_product_id: subscription['plan']['product'],
      plan_name: plan_name,
      subscribed_quantity: subscription['quantity'],
      subscription_status: subscription['status'],
      current_period_end: subscription['current_period_end'],
      subscription_ends_on: Time.zone.at(subscription['current_period_end']).strftime('%Y-%m-%d'),
      cancel_at_period_end: subscription['cancel_at_period_end'] || false,
      canceled_at: subscription['canceled_at'],
      ended_at: subscription['ended_at']
    }

    # If subscription is being cancelled, update the subscription_ends_on to the cancel_at date
    if subscription['cancel_at_period_end'] && subscription['cancel_at']
      attributes_to_merge[:subscription_ends_on] = Time.zone.at(subscription['cancel_at']).strftime('%Y-%m-%d')
    end

    account.update(
      custom_attributes: account.custom_attributes.merge(attributes_to_merge)
    )
  end

  def update_account_attributes_for_cancellation
    # Determine if this was an immediate cancellation
    was_immediate_cancellation = subscription['ended_at'].present?

    Rails.logger.info "Processing cancellation for account #{account.id}. Immediate: #{was_immediate_cancellation}"
    Rails.logger.info "Subscription cancellation data: cancel_at_period_end=#{subscription['cancel_at_period_end']}, canceled_at=#{subscription['canceled_at']}, ended_at=#{subscription['ended_at']}"

    # Set the appropriate subscription status
    new_status = was_immediate_cancellation ? 'inactive' : 'cancelled'

    # Use the subscription's cancellation timestamp, fallback to current time if not available
    cancellation_time = if subscription['ended_at'].present?
                          Time.zone.at(subscription['ended_at'])
                        elsif subscription['canceled_at'].present?
                          Time.zone.at(subscription['canceled_at'])
                        else
                          Time.current
                        end

    account.update(
      custom_attributes: account.custom_attributes.merge({
                                                           subscription_status: new_status,
                                                           subscription_ends_on: cancellation_time.strftime('%Y-%m-%d'),
                                                           current_period_end: cancellation_time.to_i,
                                                           cancel_at_period_end: subscription['cancel_at_period_end'] || false,
                                                           canceled_at: subscription['canceled_at'],
                                                           ended_at: subscription['ended_at']
                                                         })
    )

    Rails.logger.info "Set subscription_status to '#{new_status}' for account #{account.id}"
    Rails.logger.info "Updated cancellation attributes: canceled_at=#{subscription['canceled_at']}, ended_at=#{subscription['ended_at']}, cancel_at_period_end=#{subscription['cancel_at_period_end']}"
  end

  def downgrade_to_community_plan
    # Get the current plan name to determine which features to disable
    current_plan_name = account.custom_attributes['plan_name']

    Rails.logger.info "Downgrading account #{account.id} from #{current_plan_name} to community plan"

    # Update plan name to community
    account.update(
      custom_attributes: account.custom_attributes.merge({
                                                           'plan_name' => 'community'
                                                         })
    )

    # Disable all premium features (all tiers except community)
    disable_all_premium_features

    # Enable only community plan features (if any are defined)
    enable_community_plan_features

    # Enable any manually managed features
    enable_account_manually_managed_features

    account.save!
  end

  def update_plan_features
    current_plan_name = account.custom_attributes['plan_name']

    if is_community_or_free_plan?(current_plan_name)
      disable_all_premium_features
      enable_community_plan_features
    else
      enable_features_for_current_plan
    end

    # Enable any manually managed features (authorized by a super admin) configured in internal_attributes
    enable_account_manually_managed_features

    account.save!
  end

  def disable_all_premium_features
    # Disable all premium features (starter, professional, enterprise tiers)
    premium_features = self.class.premium_features
    Rails.logger.info "Disabling premium features: #{premium_features}"
    account.disable_features(*premium_features) if premium_features.any?
  end

  def enable_community_plan_features
    # Enable features that are available in the community tier (if any)
    community_features = self.class.plan_features('community')
    Rails.logger.info "Enabling community plan features: #{community_features}"
    account.enable_features(*community_features) if community_features.any?
  end

  def enable_features_for_current_plan
    # First disable all premium features to handle downgrades
    disable_all_premium_features

    # Then enable features based on the current plan
    enable_plan_specific_features
  end

  def reset_captain_usage
    account.reset_response_usage if account.respond_to?(:reset_response_usage)
  end

  def enable_plan_specific_features
    plan_name = account.custom_attributes['plan_name']
    return if plan_name.blank?

    # For cloud installations, map cloud plan names to billing plan names
    billing_plan_name = if cloud_installation?
                          map_cloud_plan_to_billing_plan(plan_name)
                        else
                          plan_name
                        end

    return if billing_plan_name.blank?

    # Get features for the plan using our tier-based system
    plan_features = self.class.plan_features(billing_plan_name)
    Rails.logger.info "Enabling features for plan #{billing_plan_name}: #{plan_features}"
    account.enable_features(*plan_features) if plan_features.any?
  end

  def extract_plan_name_from_subscription
    # Try to extract plan name from subscription metadata first
    plan_name = subscription.dig('metadata', 'plan_name')
    return plan_name if plan_name.present?

    # If not in metadata, try to map from product/price ID using billing_plans.yml
    product_id = subscription['plan']['product']
    price_id = subscription['plan']['id']

    # Look up the plan by price_id in billing_plans.yml
    self.class.available_plans.each do |plan_name, plan_config|
      return plan_name if plan_config['price_id'] == price_id
    end

    # If no exact match, try to extract from product name or description
    # This is a fallback for cases where the mapping isn't explicit
    return unless product_id.present?

    case product_id.downcase
    when /starter/
      'starter'
    when /professional/, /business/
      'professional'
    when /enterprise/
      'enterprise'
    else
      'starter' # Default fallback
    end
  end

  def map_cloud_plan_to_billing_plan(cloud_plan_name)
    # Map Stripe cloud plan names to our internal billing plan names
    # Use lowercase and substring matching to handle names like "Starter Plan"
    normalized_name = cloud_plan_name.to_s.downcase

    case normalized_name
    when /free/
      'free'
    when /starter/, /hacker/
      'starter'
    when /professional/, /business/
      'professional'
    when /enterprise/
      'enterprise'
    else
      Rails.logger.warn "Unknown cloud plan name: #{cloud_plan_name}, defaulting to starter"
      'starter'
    end
  end

  def is_community_or_free_plan?(plan_name)
    plan_name.blank? || plan_name.downcase == 'free' || plan_name.downcase == 'community'
  end

  def cloud_installation?
    InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG).present?
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?", subscription.customer).first
  end

  def find_cloud_plan(plan_id)
    cloud_plans = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
    cloud_plans.find { |config| config['product_id'].include?(plan_id) }
  end

  def default_plan?
    cloud_plans = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
    default_plan = cloud_plans.first || {}
    account.custom_attributes['plan_name'] == default_plan['name']
  end

  def enable_account_manually_managed_features
    # Get manually managed features from internal attributes using the service
    service = Internal::Accounts::InternalAttributesService.new(account)
    features = service.manually_managed_features

    # Enable each feature
    Rails.logger.info "Enabling manually managed features: #{features}"
    account.enable_features(*features) if features.present?
  end
end
