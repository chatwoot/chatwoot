# frozen_string_literal: true

require 'cgi'

class Autonomia::ProductInvitations::AgentInviter
  class Error < StandardError; end

  Result = Struct.new(
    :email,
    :name,
    :role,
    :invitation_url,
    :email_delivery_failed,
    :manual_share_required,
    :email_delivery_error,
    keyword_init: true
  )

  pattr_initialize [:account!, :inviter!, :agent_params!]

  def perform
    authorization_token = Autonomia::Sso::TokenStore.authorization_token_for(inviter)
    user_link = Autonomia::UserLink.find_by(user: inviter)

    raise Error, 'Sua sessao do Auth expirou. Saia e entre novamente para convidar agentes.' if authorization_token.blank? || user_link.blank?
    raise Error, 'Este usuario ja faz parte da conta.' if account.users.exists?(email: email)
    validate_inbox_assignment!

    response = Autonomia::ProductInvitations::Client.new.create!(
      authorization_token: authorization_token,
      payload: invitation_payload(user_link)
    )
    store_pending_invitation!(response)
    Result.new(
      email: email,
      name: name,
      role: role,
      invitation_url: invitation_url(response),
      email_delivery_failed: email_delivery_failed?(response),
      manual_share_required: manual_share_required?(response),
      email_delivery_error: response['emailDeliveryError'] || response['email_delivery_error']
    )
  rescue Autonomia::ProductInvitations::Client::Error => e
    raise Error, e.message
  end

  private

  def invitation_payload(user_link)
    {
      email: email,
      fullName: name,
      clientId: client_id,
      invitedByUserId: user_link.identity_user_id,
      productBaseUrl: product_base_url
    }
  end

  def store_pending_invitation!(response)
    invitations = pending_invitations.merge(
      email => {
        'email' => email,
        'name' => name,
        'role' => role,
        'custom_role_id' => custom_role_id,
        'invited_by_user_id' => inviter.id,
        'auth_invitation_id' => response.dig('invitation', 'id') || response['id'],
        'invitation_url' => invitation_url(response),
        'email_delivery_failed' => email_delivery_failed?(response),
        'inbox_ids' => inbox_ids,
        'create_whatsapp_api_inbox' => create_whatsapp_api_inbox?,
        'whatsapp_api_phone' => whatsapp_api_phone,
        'created_at' => Time.current.iso8601
      }
    )

    account.update!(
      custom_attributes: (account.custom_attributes || {}).merge(
        'autonomia_pending_agent_invitations' => invitations
      )
    )
  end

  def pending_invitations
    (account.custom_attributes || {}).fetch('autonomia_pending_agent_invitations', {})
  end

  def invitation_url(response)
    response.dig('invitation', 'invitationUrl') ||
      response.dig('invitation', 'invitation_url') ||
      response['invitationUrl'] ||
      response['invitation_url'] ||
      invitation_url_from_token(response)
  end

  def invitation_url_from_token(response)
    token = response['token'] || response.dig('invitation', 'token')
    return if token.blank?

    "#{product_base_url}/accept-invitation?client_id=#{CGI.escape(client_id)}&token=#{CGI.escape(token)}"
  end

  def email_delivery_failed?(response)
    truthy?(response['emailDeliveryFailed'] || response['email_delivery_failed'])
  end

  def manual_share_required?(response)
    email_delivery_failed?(response) || truthy?(response['manualShareRequired'] || response['manual_share_required'])
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def email
    @email ||= agent_params.fetch('email').to_s.downcase
  end

  def name
    agent_params['name'].presence || email.split('@').first
  end

  def role
    value = agent_params['role'].presence || 'agent'
    AccountUser.roles.key?(value) ? value : 'agent'
  end

  def custom_role_id
    agent_params['custom_role_id'].presence
  end

  def validate_inbox_assignment!
    invalid_ids = inbox_ids - account.inboxes.where(id: inbox_ids).pluck(:id)
    raise Error, 'Uma ou mais caixas de entrada selecionadas nao pertencem a esta conta.' if invalid_ids.any?

    return unless create_whatsapp_api_inbox?

    if whatsapp_api_phone.blank?
      raise Error, 'Informe o telefone da nova caixa no formato 55 + DDD + numero, por exemplo 5511999999999.'
    end

    unless whatsapp_api_phone.match?(Waha::InboxProvisioner::PHONE_RE)
      raise Error, 'Telefone invalido. Use o formato 55 + DDD + numero, por exemplo 5511999999999.'
    end
  end

  def inbox_ids
    @inbox_ids ||= Array(agent_params['inbox_ids']).filter_map do |value|
      value.to_i if value.to_s.match?(/\A\d+\z/)
    end.uniq
  end

  def create_whatsapp_api_inbox?
    ActiveModel::Type::Boolean.new.cast(agent_params['create_whatsapp_api_inbox'])
  end

  def whatsapp_api_phone
    @whatsapp_api_phone ||= agent_params['whatsapp_api_phone'].to_s.gsub(/\D/, '')
  end

  def client_id
    ENV.fetch('AUTONOMIA_AUTH_CLIENT_ID', 'talkai')
  end

  def product_base_url
    ENV.fetch('FRONTEND_URL', 'https://agents.autonomia.site')
  end
end
