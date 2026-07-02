class Public::Api::V1::Autonomia::ProductInvitationsController < PublicController
  INVITATION_TTL = 6.hours

  def validate
    token = params[:token].to_s
    invitation = pending_invitation_for(token)

    if token.blank? || invitation.blank?
      render json: { valid: false, reason: 'invalid' }, status: :not_found
      return
    end

    created_at = parse_created_at(invitation)
    if created_at.blank?
      render json: { valid: false, reason: 'invalid' }, status: :not_found
      return
    end

    expires_at = created_at + INVITATION_TTL

    if expires_at.past?
      render json: { valid: false, reason: 'expired', expires_in_hours: 6 }, status: :gone
      return
    end

    render json: { valid: true, expires_in_hours: 6, expires_at: expires_at.iso8601 }
  rescue ArgumentError
    render json: { valid: false, reason: 'invalid' }, status: :not_found
  end

  private

  def pending_invitation_for(token)
    Account.where("custom_attributes -> 'autonomia_pending_agent_invitations' IS NOT NULL").find_each do |account|
      invitation = pending_invitations(account).values.find do |candidate|
        invitation_token(candidate['invitation_url']) == token
      end
      return invitation if invitation.present?
    end

    nil
  end

  def pending_invitations(account)
    (account.custom_attributes || {}).fetch('autonomia_pending_agent_invitations', {})
  end

  def invitation_token(url)
    uri = URI.parse(url.to_s)
    Rack::Utils.parse_nested_query(uri.query)['token']
  rescue URI::InvalidURIError
    nil
  end

  def parse_created_at(invitation)
    Time.zone.parse(invitation['created_at'].to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
