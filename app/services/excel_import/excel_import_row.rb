class ExcelImport::ExcelImportRow
  include Mongoid::Document

  field :excel_import_id, type: BSON::ObjectId # Links to parent import
  field :row_number, type: Integer # Row number in Excel (2, 3, 4...)
  field :row_data, type: Hash # Current data {"Name": "John", "Email": "john@..."}
  field :status, type: String, default: 'pending' # Row-level: pending/processed/failed
  field :validation_errors, type: Array, default: [] # Any errors for this specific row
  field :created_at, type: Time, default: -> { Time.current }
  field :updated_at, type: Time, default: -> { Time.current }

  belongs_to :excel_import, class_name: 'ExcelImport::ExcelImportService'

  validates :excel_import_id, presence: true
  validates :row_number, presence: true
  validates :row_data, presence: true

  index({ excel_import_id: 1, row_number: 1 })

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
