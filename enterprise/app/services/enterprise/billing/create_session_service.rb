class Enterprise::Billing::CreateSessionService
  PORTAL_CONFIGURATION_ID = 'bpc_1SI88PF3O6TPVU2azyI0ek2W'.freeze

  def create_session(customer_id, return_url = ENV.fetch('FRONTEND_URL'))
    Stripe::BillingPortal::Session.create(
      {
        customer: customer_id,
        return_url: return_url,
        configuration: PORTAL_CONFIGURATION_ID
      }
    )
  end
end
