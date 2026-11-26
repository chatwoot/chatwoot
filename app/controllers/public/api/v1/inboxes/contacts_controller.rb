class Public::Api::V1::Inboxes::ContactsController < Public::Api::V1::InboxesController
  before_action :contact_inbox, except: [:create]
  before_action :process_hmac

  def show; end

  def create
    source_id = params[:source_id] || SecureRandom.uuid
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: @inbox_channel.inbox,
      contact_attributes: permitted_params.except(:identifier_hash)
    ).perform
  end

  def update
    contact_identify_action = ContactIdentifyAction.new(
      contact: @contact_inbox.contact,
      params: permitted_params.to_h.deep_symbolize_keys.except(:identifier),
      contact_inbox: @contact_inbox
    )
    contact_identify_action.perform
    @contact_inbox.reload
  end

  private

  def contact_inbox
    @contact_inbox = @inbox_channel.inbox.contact_inboxes.find_by!(source_id: params[:id])
  end

  def process_hmac
    return if identity_proof.none? && !@inbox_channel.hmac_mandatory
    return render_unauthorized('HMAC failed: Invalid Identifier Hash Provided') unless valid_hmac?

    @contact_inbox.update(hmac_verified: true) if @contact_inbox.present?
  end

  def valid_hmac?
    expected_identifier = hmac_identifier
    return false if expected_identifier.blank?
    return false unless params[:identifier].to_s == expected_identifier

    identity_proof.verified?
  end

  def identity_proof
    @identity_proof ||= ContactIdentity::Verifier.new(channel: @inbox_channel, identifier: hmac_identifier, params: params).perform
  end

  def hmac_identifier
    return params[:identifier].to_s if @contact_inbox.blank?

    @contact_inbox.contact.identifier.to_s
  end

  def permitted_params
    params.permit(:identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, custom_attributes: {})
  end
end
