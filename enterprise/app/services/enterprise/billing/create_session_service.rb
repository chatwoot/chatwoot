class Enterprise::Billing::CreateSessionService
  def create_session(customer_id, return_url = ENV.fetch('FRONTEND_URL'))
    # Stripe::BillingPortal::Session.create(
    #   {
    #     customer: customer_id,
    #     return_url: return_url
    #   }
    # )
    # Código relacionado ao Stripe removido
  end
end
