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

    # fix: Use :company_name instead of :company to match Chatwoot's attribute schema.
    # logic: Prioritize :company_name from params, fallback to :company if available.
    company_value = params[:company_name].presence || params[:company]
    contact.additional_attributes[:company_name] = company_value if company_value.present?

    contact.additional_attributes[:city] = params[:city] if params[:city].present?

    # polish: Add :company and :company_name to the exclusion list.
    # this prevents these fields from being duplicated into 'custom_attributes'.
    excluded_keys = [:identifier, :email, :name, :phone_number, :company, :company_name, :city]
    contact.assign_attributes(custom_attributes: contact.custom_attributes.merge(params.except(*excluded_keys)))
  end
end
