module Igaralead
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :authenticate_user!, raise: false

    def receive
      event_type = params[:event_type]
      payload = params[:payload]

      unless valid_signature?
        render json: { error: 'Invalid signature' }, status: :unauthorized
        return
      end

      case event_type
      when 'contact.created', 'contact.updated'
        handle_contact_event(payload)
      when 'user.added', 'user.updated'
        handle_user_event(payload)
      else
        Rails.logger.info("[Igaralead::Webhooks] Unhandled event: #{event_type}")
      end

      render json: { status: 'ok' }
    end

    private

    def handle_contact_event(payload)
      return unless payload.is_a?(Hash) && payload['id'].present?

      account = Account.find_by(hub_client_slug: payload['client_slug'])
      return unless account

      contact = Contact.find_by(hub_id: payload['id'], account_id: account.id)
      if contact
        contact.update(
          name: payload['name'],
          email: payload['email'],
          phone_number: payload['phone'],
          hub_synced_at: Time.current
        )
      else
        Contact.create(
          account: account,
          hub_id: payload['id'],
          name: payload['name'],
          email: payload['email'],
          phone_number: payload['phone'],
          hub_synced_at: Time.current
        )
      end
    end

    def handle_user_event(payload)
      return unless payload.is_a?(Hash) && payload['user_id'].present?

      user = User.find_by(hub_id: payload['user_id'])
      if user
        user.update(name: payload['name'], hub_synced_at: Time.current)
      end
    end

    def valid_signature?
      secret = ENV.fetch('HUB_WEBHOOK_SECRET', '')
      return true if secret.blank? # Skip validation in dev if not configured

      signature = request.headers['X-Hub-Signature']
      return false if signature.blank?

      body = request.body.read
      request.body.rewind
      expected = OpenSSL::HMAC.hexdigest('SHA256', secret, body)
      ActiveSupport::SecurityUtils.secure_compare(signature, expected)
    end
  end
end
