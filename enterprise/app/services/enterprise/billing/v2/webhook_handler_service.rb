class Enterprise::Billing::V2::WebhookHandlerService < Enterprise::Billing::V2::BaseService
  def process(event)
    case event.type
    when 'v2.billing.pricing_plan_subscription.servicing_activated'
      Rails.logger.info "Handling subscription servicing activated event: #{event.related_object.id}"
      Rails.logger.info "Related object: #{event.related_object.inspect}"
      handle_subscription_servicing_activated(event.related_object.id)
    else
      { success: true }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def handle_subscription_servicing_activated(subscription_id)
    Enterprise::Billing::V2::SubscriptionProvisioningService
      .new(account: account)
      .provision(subscription_id: subscription_id)
  end
end
