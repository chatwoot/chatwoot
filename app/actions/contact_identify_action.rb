class ContactIdentifyAction
  pattr_initialize [:contact!, :params!]

  def perform
    @identifier_params_to_be_updated = [:identifier, :name, :email, :phone]

    ActiveRecord::Base.transaction do
      merge_if_existing_identified_contact
      merge_if_existing_email_contact
      merge_if_existing_phone_number_contact
      update_contact
    end
    @contact
  end

  private

  def account
    @account ||= @contact.account
  end

  def merge_if_existing_identified_contact
    @contact = merge_contact(existing_identified_contact, @contact) if merge_contacts?(existing_identified_contact, :identifier)
  end

  def merge_if_existing_email_contact
    @contact = merge_contact(existing_email_contact, @contact) if merge_contacts?(existing_email_contact, :email)
  end

  def merge_if_existing_phone_number_contact
    @contact = merge_contact(existing_phone_number_contact, @contact) if merge_contacts?(existing_phone_number_contact, :phone_number)
  end

  def existing_identified_contact
    return if params[:identifier].blank?

    @existing_identified_contact ||= Contact.where(account_id: account.id).find_by(identifier: params[:identifier])
  end

  def existing_email_contact
    return if params[:email].blank?

    @existing_email_contact ||= Contact.where(account_id: account.id).find_by(email: params[:email])
  end

  def existing_phone_number_contact
    return if params[:phone_number].blank?

    @existing_phone_number_contact ||= Contact.where(account_id: account.id).find_by(phone_number: params[:phone_number])
  end

  def merge_contacts?(existing_contact, key)
    return false unless existing_contact

    if params[:identifier].present? && existing_contact.identifier == params[:identifier]
      @identifier_params_to_be_updated.delete(key)
      return false
    end

    if key == :phone_number && params[:email].present? && existing_contact.email != params[:email]
      @identifier_params_to_be_updated.delete(key)
      return false
    end

    true
  end

  def update_contact
    params_to_updated = params.slice(@identifier_params_to_be_updated).reject do |_k, v|
      v.blank?
    end.merge({ custom_attributes: custom_attributes, additional_attributes: additional_attributes })
    # blank identifier or email will throw unique index error
    # TODO: replace reject { |_k, v| v.blank? } with compact_blank when rails is upgraded
    @contact.update!(params_to_updated)
    ContactAvatarJob.perform_later(@contact, params[:avatar_url]) if params[:avatar_url].present?
  end

  def merge_contact(base_contact, merge_contact)
    return if base_contact.id == merge_contact.id

    ContactMergeAction.new(
      account: account,
      base_contact: base_contact,
      mergee_contact: merge_contact
    ).perform
  end

  def custom_attributes
    params[:custom_attributes] ? @contact.custom_attributes.deep_merge(params[:custom_attributes].stringify_keys) : @contact.custom_attributes
  end

  def additional_attributes
    if params[:additional_attributes]
      @contact.additional_attributes.deep_merge(params[:additional_attributes].stringify_keys)
    else
      @contact.additional_attributes
    end
  end
end
