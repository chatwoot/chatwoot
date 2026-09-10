class Crm::Cpfcnpj::ProcessorService < Crm::BaseProcessorService
  # Optional custom attribute definitions written to the contact when the hook
  # enables write_custom_attributes. Each entry maps to a key in the payload
  # produced by the contact mapper.
  CUSTOM_ATTRIBUTE_DEFINITIONS = {
    'cpfcnpj_name' => { display_name: 'CPF/CNPJ Name', display_type: 'text', source: 'name' },
    'cpfcnpj_status' => { display_name: 'CPF/CNPJ Status', display_type: 'text', source: 'status' },
    'cpfcnpj_document' => { display_name: 'CPF/CNPJ Document', display_type: 'text', source: 'document' },
    'cpfcnpj_type' => { display_name: 'CPF/CNPJ Type', display_type: 'text', source: 'type' },
    'cpfcnpj_looked_up_at' => { display_name: 'CPF/CNPJ Looked Up At', display_type: 'date', source: 'looked_up_at' }
  }.freeze

  # Error codes that describe the document itself (malformed, not found in the
  # registry, not available for the package). Retrying them on every contact
  # update would only repeat the same paid lookup, so the outcome is stored on
  # the contact until the document changes. Account level errors (token, credits,
  # rate limit, provider offline) are not stored and are retried on the next event.
  DOCUMENT_ERROR_CODES = [100, 101, 102, 103, 200, 201, 202, 1005].freeze

  def self.crm_name
    'cpfcnpj'
  end

  def initialize(hook)
    super(hook)
    settings = hook.settings || {}
    @token = settings['token']
    @document_attribute_key = settings['document_attribute_key'].presence || 'cpf_cnpj'
    @cnpj_package = settings['cnpj_package'].presence || 6
    @cpf_package = settings['cpf_package'].presence || 1
    @enrich_cpf = settings.key?('enrich_cpf') ? settings['enrich_cpf'] : true
    @write_custom_attributes = settings['write_custom_attributes'] || false
  end

  # Entry point used by HookJob for contact.created and contact.updated.
  def handle_contact(contact)
    contact.reload
    document = Crm::Cpfcnpj::Document.extract_from(contact, @document_attribute_key)
    return if document.blank?

    enrich_contact(contact, document)
  rescue Crm::Cpfcnpj::Api::BaseClient::ApiError => e
    log_expected_failure(contact, "api error #{e.code}")
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    log_expected_failure(contact, e.class.name)
  rescue StandardError => e
    track_error(e, contact)
  end

  private

  def enrich_contact(contact, document)
    type = Crm::Cpfcnpj::Document.type(document)
    return if type == :cpf && !@enrich_cpf
    return if already_enriched?(contact, document)

    response = client.lookup(document, package_for(type))
    mapped = Crm::Cpfcnpj::Mappers::ContactMapper.map(document, type, response)
    Crm::Cpfcnpj::Mappers::ContactMapper.apply(contact, mapped)
    write_custom_attributes(contact, mapped) if @write_custom_attributes
    contact.save!
    { success: true }
  rescue Crm::Cpfcnpj::Api::BaseClient::ApiError => e
    store_document_error(contact, document, type, e) if DOCUMENT_ERROR_CODES.include?(e.code)
    raise
  end

  def client
    @client ||= Crm::Cpfcnpj::Api::BaseClient.new(token: @token)
  end

  def package_for(type)
    type == :cnpj ? @cnpj_package : @cpf_package
  end

  # Anti-loop guard: a contact already processed for the same document must not
  # trigger another lookup when the resulting update fires contact.updated again.
  # A stored document error counts as processed until the document changes.
  def already_enriched?(contact, document)
    contact.additional_attributes.to_h.dig('cpfcnpj', 'document') == document
  end

  def store_document_error(contact, document, type, error)
    contact.additional_attributes = contact.additional_attributes.to_h.merge(
      'cpfcnpj' => {
        'document' => document,
        'type' => type.to_s,
        'error_code' => error.code,
        'looked_up_at' => Time.current.iso8601,
        'package' => package_for(type)
      }
    )
    contact.save!
  end

  def write_custom_attributes(contact, mapped)
    ensure_custom_attribute_definitions
    values = CUSTOM_ATTRIBUTE_DEFINITIONS.transform_values { |config| mapped[config[:source]] }.compact
    values['cpfcnpj_looked_up_at'] = Time.zone.parse(values['cpfcnpj_looked_up_at']).to_date.iso8601 if values['cpfcnpj_looked_up_at']
    contact.custom_attributes = contact.custom_attributes.to_h.merge(values)
  end

  # Definitions are shared by every contact of the account, while HookJob locks
  # per contact, so two jobs can race on the first creation. The unique index
  # rejects the loser; a second lookup then finds the row created by the winner.
  def ensure_custom_attribute_definitions
    CUSTOM_ATTRIBUTE_DEFINITIONS.each do |key, config|
      attempts = 0
      begin
        attempts += 1
        find_or_create_definition(key, config)
      rescue ActiveRecord::RecordNotUnique
        retry if attempts < 2
        raise
      end
    end
  end

  def find_or_create_definition(key, config)
    @account.custom_attribute_definitions.find_or_create_by!(
      attribute_key: key,
      attribute_model: :contact_attribute
    ) do |definition|
      definition.attribute_display_name = config[:display_name]
      definition.attribute_display_type = config[:display_type]
    end
  end

  # Rejected documents and slow lookups are routine outcomes, not defects:
  # they are logged and never sent to the exception tracker.
  def log_expected_failure(contact, reason)
    Rails.logger.warn("cpfcnpj: lookup skipped for contact ##{contact.id}: #{reason}")
    { success: false, error: reason }
  end

  def track_error(error, contact)
    ChatwootExceptionTracker.new(error, account: @account).capture_exception
    Rails.logger.error("cpfcnpj: failed to enrich contact ##{contact.id}: #{error.message}")
    { success: false, error: error.message }
  end
end
