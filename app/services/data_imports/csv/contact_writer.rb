require 'uri'

class DataImports::Csv::ContactWriter
  STANDARD_FIELDS = %w[name email identifier phone_number].freeze
  COMPANY_FIELDS = %w[company_name company_domain].freeze
  DIAGNOSTIC_FIELDS = %w[errors].freeze

  def initialize(account)
    @account = account
  end

  def perform(fields)
    @fields = normalize_fields(fields)
    labels = validated_labels
    contact = matched_contact || @account.contacts.new
    outcome = contact.new_record? ? 'created' : 'updated'
    assign_fields(contact)
    raise ActiveRecord::RecordInvalid, contact unless contact.valid?

    Contacts::SyncAttributes.new(contact).perform
    apply_company_fields(contact)
    company_change = contact.company_id_change_to_be_saved
    contact = persist(contact)
    update_company_counts(*company_change) if company_change
    apply_labels(contact, labels)
    [contact, outcome]
  end

  private

  def normalize_fields(fields)
    fields = fields.except(*DIAGNOSTIC_FIELDS)
    fields['email'] = fields['email'].strip.downcase if fields['email'].present?
    phone = fields['phone_number']&.strip&.delete_prefix("'")
    fields['phone_number'] = phone.start_with?('+') ? phone : "+#{phone}" if phone.present?
    fields
  end

  def matched_contact
    contacts = %w[identifier email phone_number].filter_map do |field|
      next if @fields[field].blank?

      @account.contacts.lock.find_by(field => @fields[field])
    end.uniq(&:id)
    raise CustomExceptions::DataImport::InvalidCsvError, 'The identifiers match different contacts.' if contacts.size > 1

    contacts.first
  end

  def assign_fields(contact)
    contact.assign_attributes(@fields.slice(*STANDARD_FIELDS).compact_blank)
    contact.additional_attributes = contact.additional_attributes.to_h.merge(@fields.slice('city').compact_blank)
    contact.custom_attributes = contact.custom_attributes.to_h.merge(custom_fields)
    contact.updated_at = Time.current
    contact.created_at ||= Time.current
  end

  def custom_fields
    fields = @fields.except(*STANDARD_FIELDS, *COMPANY_FIELDS, 'labels').compact_blank
    fields['company_domain'] = @fields['company_domain'] if @fields['company_domain'].present? && preserve_company_domain?
    fields
  end

  def preserve_company_domain?
    return @preserve_company_domain if defined?(@preserve_company_domain)

    @preserve_company_domain = !@account.feature_enabled?('companies') &&
                               @account.custom_attribute_definitions.contact_attribute.exists?(attribute_key: 'company_domain')
  end

  def apply_company_fields(contact)
    fields = @fields.slice(*COMPANY_FIELDS).compact_blank
    return if fields.empty?
    return contact.additional_attributes.merge!(fields) unless @account.feature_enabled?('companies')

    company = Contacts::CompanyAssociationService.new.find_or_create_by_name_or_domain(
      @account, name: fields['company_name'], domain: company_domain(fields['company_domain'])
    )
    return unless company

    contact.company = company
    contact.additional_attributes['company_name'] = company.name
  end

  def company_domain(value)
    domain = value&.strip
    return domain unless domain&.match?(%r{\Ahttps?://}i)

    URI.parse(domain).host.presence || domain
  rescue URI::InvalidURIError
    domain
  end

  def update_company_counts(previous_company_id, company_id)
    # Mirror the atomic counter-cache updates skipped by the silent contact write.
    # rubocop:disable Rails/SkipsModelValidations
    Company.increment_counter(:contacts_count, company_id) if company_id
    Company.decrement_counter(:contacts_count, previous_company_id) if previous_company_id
    # rubocop:enable Rails/SkipsModelValidations
  end

  def persist(contact)
    # Validation and normalization happen above; suppress normal contact callbacks during imports.
    # rubocop:disable Rails/SkipsModelValidations
    if contact.new_record?
      result = Contact.insert_all!([contact.attributes.slice(*Contact.column_names).except('id')], returning: %w[id])
      @account.contacts.find(result.rows.first.first)
    else
      contact.update_columns(contact.changes.slice(*Contact.column_names).transform_values(&:last))
      contact
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  def validated_labels
    labels = @fields['labels'].to_s.split(',').map { |label| label.strip.downcase }.reject(&:blank?).uniq
    unknown = labels - @account.labels.where(title: labels).pluck(:title)
    raise CustomExceptions::DataImport::InvalidCsvError, "Unknown labels: #{unknown.join(', ')}" if unknown.any?

    labels
  end

  def apply_labels(contact, labels)
    return if labels.empty?

    tags = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(labels)
    tag_ids = tags.map(&:id) - contact.taggings.where(context: 'labels').pluck(:tag_id)
    taggings = tag_ids.map do |tag_id|
      { tag_id: tag_id, taggable_type: 'Contact', taggable_id: contact.id, context: 'labels', created_at: Time.current }
    end
    ActsAsTaggableOn::Tagging.insert_all(taggings) # rubocop:disable Rails/SkipsModelValidations
  end
end
