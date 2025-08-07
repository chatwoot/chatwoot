class ExcelImport::ExcelImportRow
  include Mongoid::Document
  include Mongoid::Timestamps

  field :excel_import_id, type: BSON::ObjectId # Links to parent import
  field :row_number, type: Integer # Row number in Excel (2, 3, 4...)
  field :status, type: String, default: 'pending' # Row-level: pending/processed/failed
  field :validation_errors, type: Array, default: [] # Any errors for this specific row

  belongs_to :excel_import, class_name: 'ExcelImport::ExcelImportService'

  validates :excel_import_id, presence: true
  validates :row_number, presence: true

  index({ excel_import_id: 1, row_number: 1 })
  # Dynamic field creation based on Excel headers
  def self.create_fields_from_headers(headers)
    headers.each do |header|
      field_name = header.to_s.downcase.gsub(/[^a-z0-9_]/, '_').squeeze('_')
      field field_name.to_sym, type: String
    end
  end

  # Set data for all header fields
  def header_data=(data_hash)
    data_hash.each do |key, value|
      field_name = key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').squeeze('_')
      send("#{field_name}=", value) if respond_to?("#{field_name}=")
    end
  end

  EXCLUDED_FIELDS = %w[_id excel_import_id row_number status validation_errors created_at updated_at].freeze

  def header_data
    headers = self.class.fields.keys.reject { |f| EXCLUDED_FIELDS.include?(f) }
    headers.index_with { |field| send(field) }
  end

  # Mark this row as successfully processed/completed
  def mark_as_processed
    self.status = 'processed'
    self.updated_at = Time.current
    save!
  end

  # Mark this row as failed with optional error messages
  # @param errors [Array] Array of error messages explaining what went wrong
  def mark_as_failed(errors = [])
    self.status = 'failed'
    self.validation_errors = errors
    self.updated_at = Time.current
    save!
  end
end
