class Enterprise::Billing::CreateSessionService
  def create_session(_customer_id, _return_url = ENV.fetch('FRONTEND_URL'))
    Rails.logger.info 'Billing is disabled in this version of Chatwoot.'
    nil
  end
end
