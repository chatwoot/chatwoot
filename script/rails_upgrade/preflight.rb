# frozen_string_literal: true

require 'json'

module RailsUpgrade
end

class RailsUpgrade::Preflight
  def initialize
    @failures = 0
  end

  def run
    Rails.application.eager_load!

    check_version
    check_framework_defaults
    check_background_job_dependencies
    check_migrations
    check_required_columns
    check_installation_configs
    check_encrypted_attributes
    check_active_storage
    check_selected_blob
    report('summary', @failures.zero?, failures: @failures)

    exit 1 unless @failures.zero?
  end

  private

  def check_version
    expected = ENV.fetch('EXPECTED_RAILS_VERSION')
    check('rails.version', expected: expected, actual: Rails.version) { Rails.version == expected }
  end

  def check_framework_defaults
    expected = ENV.fetch('EXPECTED_CONFIG_DEFAULTS', '7.0')
    actual = Rails.application.config.loaded_config_version.to_s
    check('rails.framework_defaults', expected: expected, actual: actual) { actual == expected }
  end

  def check_background_job_dependencies
    expected_sidekiq = ENV.fetch('EXPECTED_SIDEKIQ_VERSION', '7.3.10')
    connection_pool = Gem.loaded_specs.fetch('connection_pool').version

    check('sidekiq.version', expected: expected_sidekiq, actual: Sidekiq::VERSION) { expected_sidekiq == Sidekiq::VERSION }
    check('sidekiq.connection_pool', actual: connection_pool.to_s, constraint: '< 3') { connection_pool < Gem::Version.new('3') }
  end

  def check_migrations
    context = ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)
    check('database.pending_migrations') { !context.needs_migration? }
  end

  def check_required_columns
    required_columns = {
      'active_storage_blobs' => %w[service_name checksum],
      'active_storage_variant_records' => %w[blob_id variation_digest],
      'users' => %w[otp_secret otp_backup_codes]
    }

    missing = required_columns.flat_map do |table, columns|
      existing = ActiveRecord::Base.connection.columns(table).map(&:name)
      columns.reject { |column| existing.include?(column) }.map { |column| "#{table}.#{column}" }
    end

    check('database.required_columns', missing: missing) { missing.empty? }
  end

  def check_installation_configs
    scanned = 0
    failures = []

    InstallationConfig.unscoped.find_each do |configuration|
      configuration.serialized_value
      scanned += 1
    rescue StandardError => e
      failures << failure_reference(configuration, e)
    end

    check('data.installation_configs', scanned: scanned, failure_samples: failures.first(10)) { failures.empty? }
  end

  def check_encrypted_attributes
    max_rows = Integer(ENV.fetch('PREFLIGHT_MAX_ENCRYPTED_ROWS', '0'), 10)
    checks = encrypted_attribute_checks
    check_encryption_keys(checks)
    checks.each { |entry| check_encrypted_attribute(entry, max_rows) }
  end

  def check_encryption_keys(checks)
    encrypted_rows_exist = checks.any? { |entry| entry[:available].positive? }
    configured = Chatwoot.encryption_configured?

    check('encryption.keys', configured: configured, encrypted_rows_exist: encrypted_rows_exist) do
      !encrypted_rows_exist || configured
    end
  end

  def check_encrypted_attribute(entry, max_rows)
    model = entry.fetch(:model)
    attribute = entry.fetch(:attribute)
    failures = []
    scanned = scan_encrypted_attribute(model, attribute, max_rows, failures)

    check(
      "encryption.#{model.name}.#{attribute}",
      available: entry.fetch(:available),
      scanned: scanned,
      limited: max_rows.positive?,
      failure_samples: failures.first(10)
    ) { failures.empty? }
  end

  def scan_encrypted_attribute(model, attribute, max_rows, failures)
    relation = model.unscoped.where.not(attribute => nil)
    relation = relation.limit(max_rows) if max_rows.positive?
    scanned = 0

    relation.find_each(batch_size: 500) do |record|
      record.public_send(attribute)
      scanned += 1
    rescue StandardError => e
      failures << failure_reference(record, e)
    end

    scanned
  end

  def encrypted_attribute_checks
    checks = encrypted_models.flat_map do |model|
      model.encrypted_attributes.filter_map { |attribute| encrypted_attribute_entry(model, attribute) }
    end
    checks.sort_by { |entry| [entry.fetch(:model).name, entry.fetch(:attribute).to_s] }
  end

  def encrypted_models
    ActiveRecord::Base.descendants.select do |model|
      attributes = model.encrypted_attributes if model.respond_to?(:encrypted_attributes)
      !model.abstract_class? && model.base_class == model && attributes.present? && model.table_exists?
    rescue ActiveRecord::StatementInvalid
      false
    end
  end

  def encrypted_attribute_entry(model, attribute)
    return unless model.column_names.include?(attribute.to_s)

    { model: model, attribute: attribute, available: model.unscoped.where.not(attribute => nil).count }
  end

  def check_active_storage
    configurations = Rails.configuration.active_storage.service_configurations.deep_stringify_keys
    configured_names = configurations.keys
    blob_service_names = ActiveStorage::Blob.unscoped.distinct.pluck(:service_name).compact
    unknown_names = blob_service_names - configured_names
    expected_azure_service = ENV.fetch('EXPECTED_AZURE_SERVICE', 'AzureBlob')
    actual_azure_service = configurations.dig('microsoft', 'service')

    check(
      'active_storage.service_names',
      configured: configured_names.sort,
      persisted: blob_service_names.sort,
      unknown: unknown_names.sort
    ) { unknown_names.empty? }

    check(
      'active_storage.azure_adapter',
      expected: expected_azure_service,
      actual: actual_azure_service
    ) { actual_azure_service == expected_azure_service }
  end

  def check_selected_blob
    blob_id = ENV.fetch('ACTIVE_STORAGE_CHECK_BLOB_ID', nil)
    return report('active_storage.selected_blob', true, skipped: true) if blob_id.blank?

    blob = ActiveStorage::Blob.find(blob_id)
    check(
      'active_storage.selected_blob',
      blob_id: blob.id,
      service_name: blob.service_name
    ) { blob.service.exist?(blob.key) }
  rescue StandardError => e
    report('active_storage.selected_blob', false, error_class: e.class.name)
  end

  def failure_reference(record, error)
    { id: record.id, error_class: error.class.name }
  end

  def check(name, details = {})
    report(name, yield, details)
  rescue StandardError => e
    report(name, false, details.merge(error_class: e.class.name))
  end

  def report(name, passed, details = {})
    @failures += 1 unless passed
    puts({ check: name, status: passed ? 'PASS' : 'FAIL' }.merge(details).to_json)
  end
end

RailsUpgrade::Preflight.new.run
