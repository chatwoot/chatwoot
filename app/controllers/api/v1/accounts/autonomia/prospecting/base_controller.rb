class Api::V1::Accounts::Autonomia::Prospecting::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled
  before_action :ensure_account_administrator

  private

  def ensure_feature_enabled
    render json: { error: 'autonomia.prospecting.disabled' }, status: :not_found unless ::Autonomia::Prospecting::Config.enabled?(Current.account)
  end

  def ensure_account_administrator
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end

  def searches_scope
    ::Autonomia::Prospecting::Search.where(account: Current.account)
  end

  def leads_scope
    ::Autonomia::Prospecting::Lead.where(account: Current.account)
  end

  def lists_scope
    ::Autonomia::Prospecting::List.where(account: Current.account)
  end

  def setting
    ::Autonomia::Prospecting::Setting.for_account(Current.account)
  end

  def whatsapp_payload(lead)
    verification = lead.metadata.to_h['whatsapp_verification'].to_h
    status = verification['status']
    phone = verification['phone'].presence || normalized_lead_phone(lead)

    {
      whatsapp_verification_status: status,
      whatsapp_verified: status == 'verified',
      whatsapp_phone: phone,
      whatsapp_url: status == 'verified' && phone.present? ? "https://wa.me/#{phone.gsub(/\D/, '')}" : nil
    }
  end

  def normalized_lead_phone(lead)
    digits = lead.phone.to_s.gsub(/\D/, '')
    return if digits.blank?

    phone = if lead.phone.to_s.strip.start_with?('+')
              "+#{digits}"
            elsif digits.start_with?('55')
              "+#{digits}"
            elsif digits.length.in?([10, 11])
              "+55#{digits}"
            else
              "+#{digits}"
            end

    phone.match?(/\A\+[1-9]\d{7,14}\z/) ? phone : nil
  end
end
