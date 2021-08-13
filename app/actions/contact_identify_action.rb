class ContactIdentifyAction
  pattr_initialize [:contact!, :params!]

  def perform
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
    @contact = merge_contact(existing_identified_contact, @contact) if merge_contacts?(existing_identified_contact, @contact)
  end

  def merge_if_existing_email_contact
    @contact = merge_contact(existing_email_contact, @contact) if merge_contacts?(existing_email_contact, @contact)
  end

  def merge_if_existing_phone_number_contact
    @contact = merge_contact(existing_phone_number_contact, @contact) if merge_contacts?(existing_phone_number_contact, @contact)
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

  def merge_contacts?(existing_contact, _contact)
    existing_contact && existing_contact.id != @contact.id
  end

  def update_contact
    custom_attributes = params[:custom_attributes] ? @contact.custom_attributes.merge(params[:custom_attributes]) : @contact.custom_attributes
    # blank identifier or email will throw unique index error
    # TODO: replace reject { |_k, v| v.blank? } with compact_blank when rails is upgraded
    @contact.update!(params.slice(:name, :email, :identifier, :phone_number).reject do |_k, v|
                       v.blank?
                     end.merge({ custom_attributes: custom_attributes }))
    ContactAvatarJob.perform_later(@contact, params[:avatar_url]) if params[:avatar_url].present?
  end

  def merge_contact(base_contact, merge_contact)
    ContactMergeAction.new(
      account: account,
      base_contact: base_contact,
      mergee_contact: merge_contact
    ).perform
  end
end
