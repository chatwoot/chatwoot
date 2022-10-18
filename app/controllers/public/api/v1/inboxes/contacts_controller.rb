class Public::Api::V1::Inboxes::ContactsController < Public::Api::V1::InboxesController
  before_action :contact_inbox, except: [:create]
  before_action :process_hmac

  def create
    source_id = params[:source_id] || SecureRandom.uuid
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: @inbox_channel.inbox,
      contact_attributes: permitted_params.except(:identifier, :identifier_hash)
    ).perform
  end

  def show; end

  def update
    contact_identify_action = ContactIdentifyAction.new(
      contact: @contact_inbox.contact,
      params: permitted_params.to_h.deep_symbolize_keys.except(:identifier)
    )
    render json: contact_identify_action.perform
  end

  private

  def contact_inbox
    @contact_inbox = @inbox_channel.inbox.contact_inboxes.find_by!(source_id: params[:id])
  end

  def process_hmac
    return if params[:identifier_hash].blank? && !@inbox_channel.hmac_mandatory
    raise StandardError, 'HMAC failed: Invalid Identifier Hash Provided' unless valid_hmac?

    @contact_inbox.update(hmac_verified: true) if @contact_inbox.present?
  end

  def valid_hmac?
    params[:identifier_hash] == OpenSSL::HMAC.hexdigest(
      'sha256',
      @inbox_channel.hmac_token,
      params[:identifier].to_s
    )
  end

  def permitted_params
    params.permit(:identifier, :identifier_hash, :email, :name, :avatar_url, :phone_number, custom_attributes: {})
  end
end
