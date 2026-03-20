class Api::V1::Accounts::Contacts::GroupAdminController < Api::V1::Accounts::Contacts::BaseController
  VALID_PROPERTIES = %w[announce restrict join_approval_mode member_add_mode].freeze

  def leave
    authorize @contact, :update?
    channel.group_leave(@contact.identifier)
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    authorize @contact, :update?
    property = property_params[:property]
    enabled = ActiveModel::Type::Boolean.new.cast(property_params[:enabled])
    return render json: { error: 'invalid_property' }, status: :unprocessable_entity unless property.in?(VALID_PROPERTIES)

    apply_property_change(property, enabled)
    update_contact_attribute(property, enabled)
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def apply_property_change(property, enabled)
    case property
    when 'announce', 'restrict'
      channel.group_setting_update(@contact.identifier, property, enabled)
    when 'join_approval_mode'
      channel.group_join_approval_mode(@contact.identifier, enabled ? 'on' : 'off')
    when 'member_add_mode'
      channel.group_member_add_mode(@contact.identifier, enabled ? 'all_member_add' : 'admin_add')
    end
  end

  def property_params
    params.permit(:property, :enabled)
  end

  def channel
    @channel ||= @contact.group_channel
  end

  def resolve_group_conversations
    Current.account.conversations
           .where(contact_id: @contact.id, group_type: :group, status: %i[open pending])
           .find_each { |c| c.update!(status: :resolved) }
  end

  def update_contact_attribute(key, value)
    new_attrs = (@contact.additional_attributes || {}).merge(key => value)
    @contact.update!(additional_attributes: new_attrs)
  end
end
