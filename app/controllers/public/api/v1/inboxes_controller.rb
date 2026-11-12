class Public::Api::V1::InboxesController < PublicController
  before_action :set_inbox_channel
  before_action :set_contact_inbox
  before_action :ensure_hmac_verified
  before_action :set_conversation

  def show
    @inbox_channel = ::Channel::Api.find_by!(identifier: params[:id])
  end

  private

  def set_inbox_channel
    return if params[:inbox_id].blank?

    @inbox_channel = ::Channel::Api.find_by!(identifier: params[:inbox_id])
  end

  def set_contact_inbox
    return if params[:contact_id].blank?

    @contact_inbox = @inbox_channel.inbox.contact_inboxes.find_by!(source_id: params[:contact_id])
  end

  def ensure_hmac_verified
    return if @contact_inbox.blank? || !@inbox_channel.hmac_mandatory
    return if valid_contact_identifier_hash?

    render_unauthorized('HMAC failed: Invalid Identifier Hash Provided')
  end

  def valid_contact_identifier_hash?
    identifier = @contact_inbox.contact.identifier
    return false if identifier.blank?

    expected_hash = OpenSSL::HMAC.hexdigest('sha256', @inbox_channel.hmac_token, identifier)
    ActiveSupport::SecurityUtils.secure_compare(params[:identifier_hash].to_s, expected_hash)
  end

  def set_conversation
    return if params[:conversation_id].blank?

    @conversation = if @contact_inbox.hmac_verified?
                      @contact_inbox.contact.conversations.find_by!(display_id: params[:conversation_id])
                    else
                      @contact_inbox.conversations.find_by!(display_id: params[:conversation_id])
                    end
  end
end
