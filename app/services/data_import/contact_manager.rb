class DataImport::ContactManager
  def initialize(account)
    @account = account
  end

  def build_contact(params)
    contact = find_or_initialize_contact(params)
    update_contact_attributes(params, contact)
    contact
  end

  def find_or_initialize_contact(params)
    contact = find_existing_contact(params)
    contact_params = params.slice(:email, :identifier, :phone_number)
    contact_params[:phone_number] = format_phone_number(contact_params[:phone_number]) if contact_params[:phone_number].present?
    contact ||= @account.contacts.new(contact_params)
    contact
  end

  def find_existing_contact(params)
    contact = find_contact_by_identifier(params)
    contact ||= find_contact_by_email(params)
    contact ||= find_contact_by_phone_number(params)

    update_contact_with_merged_attributes(params, contact) if contact.present? && contact.valid?
    contact
  end

  def find_contact_by_identifier(params)
    return unless params[:identifier]

    @account.contacts.find_by(identifier: params[:identifier])
  end

  def find_contact_by_email(params)
    return unless params[:email]

    @account.contacts.from_email(params[:email])
  end

  def find_contact_by_phone_number(params)
    return unless params[:phone_number]

    @account.contacts.find_by(phone_number: format_phone_number(params[:phone_number]))
  end

  def format_phone_number(phone_number)
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def update_contact_with_merged_attributes(params, contact)
    contact.identifier = params[:identifier] if params[:identifier].present?
    contact.email = params[:email] if params[:email].present?
    contact.phone_number = format_phone_number(params[:phone_number]) if params[:phone_number].present?
    update_contact_attributes(params, contact)
    contact.save
  end

  private

  def update_contact_attributes(params, contact)
    contact.name = params[:name] if params[:name].present?
    contact.additional_attributes ||= {}
    company_name = params[:company_name].presence || params[:company].presence
    # Store with string keys so values match JSONB / UI expectations (see #14096).
    contact.additional_attributes['company_name'] = company_name if company_name.present?
    contact.additional_attributes['city'] = params[:city] if params[:city].present?
    merged_custom = strip_legacy_company_custom_keys(contact.custom_attributes).merge(
      params.except(:identifier, :email, :name, :phone_number, :company, :company_name)
    )
    contact.assign_attributes(custom_attributes: merged_custom)
  end

  # Pre-#14096 imports could persist `company` / `company_name` inside custom_attributes.
  # Drop them before merging new row data so re-imports do not keep stale duplicates.
  def strip_legacy_company_custom_keys(attrs)
    return {} if attrs.blank?

    attrs.reject { |key, _| %w[company company_name].include?(key.to_s) }
  end
end
