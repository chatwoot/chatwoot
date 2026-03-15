# frozen_string_literal: true

# REST API for cross-product integrations.
# Called by Amplex/Entity/Hub to interact with Nexus resources.
module Igaralead
  class IntegrationController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :authenticate_user!, raise: false
    before_action :authenticate_api_key!
    before_action :find_account!

    # POST /igaralead/api/conversations/find_or_create
    # Find or create a conversation for a contact (used by Amplex "Open conversation" button)
    # Body: { "phone": "+5511999999999", "email": "x@y.com", "name": "João", "inbox_id": 1 }
    def find_or_create_conversation
      contact = find_or_create_contact
      return render json: { error: 'Could not find or create contact' }, status: :unprocessable_entity unless contact

      inbox = @account.inboxes.find_by(id: params[:inbox_id]) || @account.inboxes.first
      return render json: { error: 'No inbox available' }, status: :unprocessable_entity unless inbox

      contact_inbox = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) do |ci|
        ci.source_id = contact.phone_number&.gsub('+', '')&.concat('@s.whatsapp.net')
      end

      conversation = contact_inbox.conversations.where(status: [:open, :pending]).order(last_activity_at: :desc).first
      conversation ||= Conversation.create!(
        account: @account,
        inbox: inbox,
        contact: contact,
        contact_inbox: contact_inbox
      )

      base_url = ENV.fetch('NEXUS_BASE_URL', 'http://localhost:3000')

      render json: {
        conversation_id: conversation.display_id,
        contact_id: contact.id,
        contact_name: contact.name,
        url: "#{base_url}/app/accounts/#{@account.id}/conversations/#{conversation.display_id}",
        status: conversation.status
      }, status: :ok
    end

    # POST /igaralead/api/messages
    # Send a message to a contact's conversation (used by Amplex stage-triggered WhatsApp)
    # Body: { "conversation_id": 123, "content": "Hello!", "message_type": "outgoing" }
    def send_message
      conversation = @account.conversations.find_by(display_id: params[:conversation_id])
      return render json: { error: 'Conversation not found' }, status: :not_found unless conversation

      message = conversation.messages.create!(
        account: @account,
        message_type: :outgoing,
        content: params[:content],
        inbox_id: conversation.inbox_id
      )

      render json: {
        message_id: message.id,
        content: message.content,
        status: message.status,
        conversation_id: conversation.display_id
      }, status: :created
    end

    # POST /igaralead/api/contacts/import
    # Bulk import contacts from Entity (CNPJ query results)
    # Body: { "contacts": [{ "name": "...", "phone": "...", "email": "...", "cnpj": "..." }], "labels": ["prospect"] }
    def import_contacts
      contacts_data = params[:contacts] || []
      labels = params[:labels] || []

      return render json: { error: 'No contacts provided' }, status: :bad_request if contacts_data.empty?

      created = []
      skipped = []

      contacts_data.each do |c|
        name = c[:name].presence
        next skipped.push({ reason: 'missing name', data: c }) unless name

        # Check duplicates by phone or email
        existing = nil
        existing = @account.contacts.find_by(phone_number: c[:phone]) if c[:phone].present?
        existing ||= @account.contacts.find_by(email: c[:email]) if c[:email].present?

        if existing
          skipped.push({ reason: 'already exists', id: existing.id, name: existing.name })
          next
        end

        contact = @account.contacts.create!(
          name: name,
          phone_number: c[:phone].presence,
          email: c[:email].presence,
          custom_attributes: { cnpj: c[:cnpj], source: 'entity_import' }.compact
        )

        # Apply labels
        labels.each { |label| contact.add_labels([label]) } if labels.any?
        created.push({ id: contact.id, name: contact.name })
      end

      render json: {
        created: created.size,
        skipped: skipped.size,
        details: { created: created, skipped: skipped }
      }, status: :created
    end

    # POST /igaralead/api/contacts/enrich
    # Enrich a contact with CNPJ data from Entity
    # Body: { "contact_id": 123, "cnpj_data": { "razao_social": "...", "telefone": "...", ... } }
    def enrich_contact
      contact = @account.contacts.find_by(id: params[:contact_id])
      return render json: { error: 'Contact not found' }, status: :not_found unless contact

      cnpj_data = params[:cnpj_data] || {}
      attrs = contact.custom_attributes || {}
      attrs.merge!(cnpj_data.to_unsafe_h)

      contact.update!(
        name: cnpj_data[:razao_social].presence || contact.name,
        phone_number: cnpj_data[:telefone].presence || contact.phone_number,
        email: cnpj_data[:email].presence || contact.email,
        custom_attributes: attrs
      )

      render json: { id: contact.id, name: contact.name, custom_attributes: contact.custom_attributes }
    end

    private

    def authenticate_api_key!
      api_key = request.headers['X-Api-Key']
      expected = ENV.fetch('HUB_API_KEY', '')

      return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(api_key.to_s, expected)

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    def find_account!
      slug = params[:client_slug]
      @account = if slug.present?
                   Account.find_by(hub_client_slug: slug)
                 else
                   Account.first # dev fallback
                 end
      render json: { error: 'Account not found' }, status: :not_found unless @account
    end

    def find_or_create_contact
      phone = params[:phone].presence
      email = params[:email].presence
      name = params[:name].presence || phone || email

      contact = nil
      contact = @account.contacts.find_by(phone_number: phone) if phone
      contact ||= @account.contacts.find_by(email: email) if email

      contact || @account.contacts.create(
        name: name,
        phone_number: phone,
        email: email,
        custom_attributes: { cnpj: params[:cnpj], source: 'amplex_integration' }.compact
      )
    end
  end
end
