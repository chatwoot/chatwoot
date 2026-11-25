class Api::V1::Accounts::Contacts::GroupMetadataController < Api::V1::Accounts::Contacts::BaseController
  include GroupChannelResolver

  def update
    authorize @contact, :update?
    # Before deciding there is nothing to do, and not after. Resolving only when a field was sent
    # meant an empty request was never refused: an agent on none of this group's inboxes, or one
    # naming an inbox they are not on, got a 200 for a request that would have been refused the
    # moment it carried a single field. Whether the answer is 404 or 200 is not the caller's to
    # decide by leaving the body out.
    channel
    refuse_description_removal!
    update_subject if metadata_params[:subject].present?
    update_description if metadata_params[:description].present?
    update_picture if metadata_params[:avatar].present?
    render json: { id: @contact.id, name: @contact.name, additional_attributes: @contact.additional_attributes }
  rescue Whatsapp::Session::Errors::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def metadata_params
    params.permit(:subject, :description, :avatar)
  end

  # An emptied description is the one field where "absent" and "cleared" are different
  # requests, and until now they were the same silence: `present?` skipped the update, the
  # response came back 200 with the old text still in it, and the operator was told the
  # save worked.
  #
  # Saying no is the honest answer rather than a limitation of this controller. Measured on
  # 10/09/2026 against both providers: uazapi refuses it at its own API
  # (`400 Description cannot be empty`), and the native connector sends a stanza WhatsApp
  # never answers, which costs 75 seconds of the session's executor with every other
  # command for that account queued behind it. WhatsApp's own protocol has a separate shape
  # for a removal that neither path produces, which is fazer-ai/chatwoot#546.
  #
  # Only when the key was sent: a request that never mentions the description is not asking
  # for anything.
  def refuse_description_removal!
    return unless metadata_params.key?(:description)
    return if metadata_params[:description].present?

    raise Whatsapp::Session::Errors::NotSupported, I18n.t('errors.whatsapp.group_description_cannot_be_removed')
  end

  def update_subject
    channel.update_group_subject(@contact.identifier, metadata_params[:subject])
    @contact.update!(name: metadata_params[:subject])
  end

  def update_description
    channel.update_group_description(@contact.identifier, metadata_params[:description])
    attrs = @contact.additional_attributes.merge('description' => metadata_params[:description])
    @contact.update!(additional_attributes: attrs)
  end

  def update_picture
    avatar = metadata_params[:avatar]
    image_base64 = Base64.strict_encode64(avatar.read)
    channel.update_group_picture(@contact.identifier, image_base64)
    @contact.avatar.attach(avatar)
  end
end
