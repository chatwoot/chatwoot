class DataImports::Csv::ContactWriter
  STANDARD_FIELDS = %w[name email identifier phone_number].freeze
  DIAGNOSTIC_FIELDS = %w[errors row_number].freeze

  def initialize(account, fields)
    @account = account
    @fields = fields.except(*DIAGNOSTIC_FIELDS).dup
    @fields['email'] = @fields['email'].strip.downcase if @fields['email'].present?
    phone = @fields['phone_number']&.strip&.delete_prefix("'")
    @fields['phone_number'] = phone.start_with?('+') ? phone : "+#{phone}" if phone.present?
  end

  def perform
    labels = validated_labels
    contact = matched_contact || @account.contacts.new
    outcome = contact.new_record? ? 'created' : 'updated'
    assign_fields(contact)
    raise ActiveRecord::RecordInvalid, contact unless contact.valid?

    Contacts::SyncAttributes.new(contact).perform
    contact = persist(contact)
    apply_labels(contact, labels)
    [contact, outcome]
  end

  private

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
    contact.additional_attributes = contact.additional_attributes.to_h.merge(@fields.slice('company_name', 'city').compact_blank)
    contact.custom_attributes = contact.custom_attributes.to_h.merge(@fields.except(*STANDARD_FIELDS, 'labels'))
    contact.updated_at = Time.current
    contact.created_at ||= Time.current
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
    unknown = labels - @account.labels.pluck(:title).map(&:downcase)
    raise CustomExceptions::DataImport::InvalidCsvError, "Unknown labels: #{unknown.join(', ')}" if unknown.any?

    labels
  end

  def apply_labels(contact, labels)
    return if labels.empty?

    tags = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(labels)
    taggings = tags.map { |tag| { tag_id: tag.id, taggable_type: 'Contact', taggable_id: contact.id, context: 'labels', created_at: Time.current } }
    ActsAsTaggableOn::Tagging.insert_all(taggings) # rubocop:disable Rails/SkipsModelValidations
  end
end
