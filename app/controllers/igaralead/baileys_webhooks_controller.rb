module Igaralead
  class BaileysWebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :authenticate_user!, raise: false
    before_action :authenticate_sidecar!

    def message
      channel = find_channel
      return render json: { error: 'Channel not found' }, status: :not_found unless channel

      Baileys::IncomingMessageService.new(inbox: channel.inbox, params: baileys_params).perform
      render json: { status: 'ok' }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[BaileysWebhook] Message processing failed: #{e.message}")
      render json: { status: 'skipped', reason: e.message }
    end

    def status_update
      channel = find_channel
      return render json: { error: 'Channel not found' }, status: :not_found unless channel

      handle_status_update(channel)
      render json: { status: 'ok' }
    end

    def qr_code
      channel = find_channel
      return render json: { error: 'Channel not found' }, status: :not_found unless channel

      channel.update!(session_status: 'qr_pending', provider_config: channel.provider_config.merge('qr_code' => params[:qr]))
      render json: { status: 'ok' }
    end

    def connection_update
      channel = find_channel
      return render json: { error: 'Channel not found' }, status: :not_found unless channel

      handle_connection_update(channel)
      render json: { status: 'ok' }
    end

    def contact_update
      channel = find_channel
      return render json: { error: 'Channel not found' }, status: :not_found unless channel

      handle_contact_update(channel)
      render json: { status: 'ok' }
    end

    def group_update
      channel = find_channel
      return render json: { error: 'Channel not found' }, status: :not_found unless channel

      handle_group_update(channel)
      render json: { status: 'ok' }
    end

    private

    def authenticate_sidecar!
      api_key = request.headers['X-Api-Key']
      expected = ENV.fetch('BAILEYS_SIDECAR_API_KEY', '')

      return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(api_key.to_s, expected)

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    def find_channel
      Channel::BaileysWhatsapp.find_by(session_id: params[:session_id])
    end

    def baileys_params
      params.permit!.to_h.deep_symbolize_keys
    end

    def handle_status_update(channel)
      source_id = params.dig(:key, :id)
      return unless source_id.present?

      status = params[:status]
      return unless %w[sent delivered read failed].include?(status)

      message = channel.inbox.messages.find_by(source_id: source_id)
      unless message
        Rails.logger.debug("[BaileysWebhook] Status update: message not found for source_id=#{source_id}")
        return
      end

      # Don't downgrade status (e.g. read → delivered due to out-of-order updates)
      status_order = { 'sent' => 0, 'delivered' => 1, 'read' => 2, 'failed' => 3 }
      current_rank = status_order[message.status] || -1
      new_rank = status_order[status] || -1
      return if new_rank <= current_rank && status != 'failed'

      message.update!(status: status)
    end

    def handle_connection_update(channel)
      case params[:connection]
      when 'open'
        phone = params[:phone_number] || channel.phone_number
        channel.mark_connected(phone)
      when 'close'
        channel.mark_disconnected
      end
    end

    def handle_contact_update(channel)
      phone_number = params[:phone_number]
      return if phone_number.blank?

      name = params[:name].presence || params[:notify].presence
      return if name.blank?

      waid = phone_number.to_s.gsub(/[^\d]/, '')
      contact = Contact.find_by(phone_number: "+#{waid}", account_id: channel.account_id)
      return unless contact

      # Update name if the contact still has a phone-number-style name
      contact.update!(name: name) if contact.name.start_with?('+')

      # Update avatar from WhatsApp profile picture
      update_contact_avatar(contact, params[:avatar_url])
    end

    def handle_group_update(channel)
      jid = params[:jid]
      return if jid.blank?

      name = params[:name].presence
      return if name.blank?

      # Find the contact_inbox for this group (source_id = group JID)
      contact_inbox = channel.inbox.contact_inboxes.find_by(source_id: jid)
      if contact_inbox
        contact = contact_inbox.contact
        # Update group name if it's still the default ID-based name
        contact.update!(name: name) if contact.name.start_with?('Group ')
        update_contact_avatar(contact, params[:avatar_url])
      end
    end

    def update_contact_avatar(contact, avatar_url)
      return if avatar_url.blank?
      return if contact.avatar.attached?

      ::Avatar::AvatarFromUrlJob.perform_later(contact, avatar_url)
    end
  end
end
