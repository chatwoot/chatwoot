class ExcelImport::ExcelImportService
  include Mongoid::Document
  include Mongoid::Timestamps

  field :account_id, type: Integer   # Who owns this import
  field :file_name, type: String, default: 'data_import' # Import name/identifier
  field :description, type: String # Optional description for the import
  field :status, type: String, default: 'pending' # overall: pending/completed/failed
  field :total_rows, type: Integer # Total number of rows in the data
  field :processed_rows, type: Integer, default: 0 # Number of rows processed
  field :error_count, type: Integer, default: 0 # Number of errors encountered
  field :metadata, type: Hash, default: {} # Headers and other metadata

  has_many :excel_import_rows, class_name: 'ExcelImport::ExcelImportRow', dependent: :destroy

  validates :account_id, presence: true

  def initialize(account_id:, data_array:, store_id:, file_name: nil, description: nil)
    self.class.store_by_external_id(store_id)
    super()
    @data_array = data_array
    self.account_id = account_id
    self.file_name = file_name || 'data_import'
    self.description = description
    self.status = 'pending'
  end

  # Set collection name based on external_id
  def self.store_by_external_id(external_id)
    coll_name = external_id.to_s.downcase.gsub(/[^a-z0-9_]/, '_').squeeze('_')
    store_in collection: coll_name
    ExcelImport::ExcelImportRow.store_in collection: coll_name
  end

  # Main entry point to process the data array sent from frontend:
  # 1. Validates the data array
  # 2. Saves each row as a separate ExcelImportRow document
  # 3. Updates the import status
  # Returns a hash with the result of the import process
  def process_data_import
    # Validate and process the data array
    parsed_data = process_data_array(@data_array)

    # Save parsed data as JSON rows
    save_parsed_rows(parsed_data)

    # Update status
    update_status('completed')

    {
      success: true,
      import_id: id.to_s,
      total_rows: total_rows,
      message: 'Data processed successfully'
    }
  rescue StandardError => e
    update_status('failed')
    Rails.logger.error "Data import failed: #{e.message}"
    {
      success: false,
      error: e.message
    }
  end

  # Returns a summary of the import status and metadata for the frontend or API
  def import_status
    {
      id: id.to_s,
      status: status,
      total_rows: total_rows,
      processed_rows: processed_rows,
      error_count: error_count,
      file_name: file_name,
      description: description,
      created_at: created_at,
      metadata: metadata
    }
  end

  # Returns all data for this import (for download)
  def all_data
    excel_import_rows.map(&:header_data)
  end

  private

  # Process and validate data array from frontend
  def process_data_array(data_array)
    return [] if data_array.blank?

    # Convert ActionController::Parameters to Hash if needed
    first_item = data_array.first
    first_item = convert_to_hash(first_item) if first_item

    # Extract headers from first object
    headers = first_item.keys if first_item.respond_to?(:keys)

    # Create dynamic fields in ExcelImportRow based on headers
    ExcelImport::ExcelImportRow.create_fields_from_headers(headers) if headers

    # Store metadata
    self.metadata = {
      headers: headers || [],
      total_objects: data_array.size
    }

    # Process each data object
    rows_data = []
    data_array.each_with_index do |row_data, index|
      # Convert to hash and validate
      hash_data = convert_to_hash(row_data)
      next unless hash_data.respond_to?(:keys) && hash_data.respond_to?(:[])

      rows_data << {
        row_number: index + 1, # Start from 1
        data: sanitize_row_data(hash_data)
      }
    end

    self.total_rows = rows_data.count
    save!

    rows_data
  end

  # Saves each parsed row as an ExcelImportRow document
  # Increments processed_rows or error_count as appropriate
  def save_parsed_rows(parsed_data)
    parsed_data.each do |row_info|
      excel_import_row = ExcelImport::ExcelImportRow.new(
        excel_import_id: id,
        row_number: row_info[:row_number]
      )

      # Set the dynamic header fields with data
      excel_import_row.header_data = row_info[:data]

      if excel_import_row.save
        excel_import_row.mark_as_processed
        self.processed_rows += 1
      else
        excel_import_row.mark_as_failed(excel_import_row.errors.full_messages)
        self.error_count += 1
        Rails.logger.error "Failed to save row #{row_info[:row_number]}: #{excel_import_row.errors.full_messages}"
      end
    end

    save!
  end

  # Sanitizes and normalizes row data from frontend
  def sanitize_row_data(row_data)
    sanitized = {}
    row_data.each do |key, value|
      sanitized_key = key.to_s.strip
      sanitized_value = sanitize_cell_value(value)
      sanitized[sanitized_key] = sanitized_value
    end
    sanitized
  end

  # Converts ActionController::Parameters or other objects to Hash
  # Safely extracts only the data we need from parameters
  def convert_to_hash(data)
    case data
    when ActionController::Parameters
      # Safer approach: manually extract the hash without bypassing security
      hash = {}
      data.each { |key, value| hash[key] = value }
      hash
    when Hash
      data
    else
      data.respond_to?(:to_h) ? data.to_h : data
    end
  end

  # Normalizes cell values for consistent storage
  def sanitize_cell_value(value)
    case value
    when String
      value.strip
    when NilClass
      nil
    else
      value
    end
  end

  # Updates the status field and updated_at timestamp for this import
  def update_status(new_status)
    self.status = new_status
    self.updated_at = Time.current
    save!
  end
end
