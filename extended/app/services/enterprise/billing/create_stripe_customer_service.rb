class Enterprise::Billing::CreateStripeCustomerService
  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    Rails.logger.info 'Billing is disabled in this version of Chatwoot.'
  end

  private

  def prepare_customer_id; end
  def default_quantity; end
  def billing_email; end
  def default_plan; end
  def price_id; end
  def existing_subscription?; end
end
