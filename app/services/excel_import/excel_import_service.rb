class ExcelImport::ExcelImportService
  include Mongoid::Document

  field :account_id, type: Integer   # Who owns this import
  field :file_name, type: String # Original filename
  field :gridfs_file_id, type: BSON::ObjectId # GridFS file ID
  field :file_content_type, type: String # MIME type
  field :file_size, type: Integer # File size in bytes
  field :status, type: String, default: 'pending' # overall: pending/completed/failed
  field :total_rows, type: Integer # Total number of rows in the Excel file
  field :processed_rows, type: Integer, default: 0 # Number of rows processed
  field :error_count, type: Integer, default: 0 # Number of errors encountered
  field :metadata, type: Hash, default: {} # Headers, sheets info, file size
  field :created_at, type: Time, default: -> { Time.current }
  field :updated_at, type: Time, default: -> { Time.current }

  has_many :excel_import_rows, class_name: 'ExcelImport::ExcelImportRow', dependent: :destroy

  validates :account_id, presence: true
  validates :file_name, presence: true

  # Cleanup GridFS file when document is destroyed
  before_destroy :cleanup_gridfs_file

  def initialize(account_id:, file_data:, file_name:, content_type:)
    super()
    @file_data = file_data
    @content_type = content_type
    self.account_id = account_id
    self.file_name = file_name
    self.file_content_type = content_type
    self.file_size = file_data.bytesize
    self.status = 'pending'
  end

  # Main entry point to process the uploaded Excel file:
  # 1. Parses the Excel data from the uploaded file
  # 2. Saves each row as a separate ExcelImportRow document
  # 3. Stores the original file in GridFS
  # 4. Updates the import status
  # Returns a hash with the result of the import process
  def process_excel_import
    # Parse the Excel data FIRST (from original file data)
    parsed_data = parse_excel_data

    # Save parsed data as JSON rows
    save_parsed_rows(parsed_data)

    # Save the Excel file to GridFS AFTER successful parsing
    save_excel_file

    # Update status
    update_status('completed')

    {
      success: true,
      import_id: id.to_s,
      total_rows: total_rows,
      message: 'Excel file processed successfully'
    }
  rescue StandardError => e
    update_status('failed')
    Rails.logger.error "Excel import failed: #{e.message}"
    {
      success: false,
      error: e.message
    }
  end

  # Returns a summary of the import status and metadata for the frontend or API
  def get_import_status
    {
      id: id.to_s,
      status: status,
      total_rows: total_rows,
      processed_rows: processed_rows,
      error_count: error_count,
      file_name: file_name,
      created_at: created_at,
      metadata: metadata
    }
  end

  # Returns paginated parsed row data for this import
  # Each row is returned as the row_data hash only (not the full document)
  # Used for previewing imported data in the UI
  def get_parsed_data(page: 1, per_page: 100)
    offset = (page - 1) * per_page
    rows = excel_import_rows.skip(offset).limit(per_page)

    {
      data: rows.map(&:row_data),
      pagination: {
        current_page: page,
        per_page: per_page,
        total_rows: total_rows,
        total_pages: (total_rows.to_f / per_page).ceil
      }
    }
  end

  # Retrieves the original uploaded file from GridFS
  # Returns file metadata and binary data, or nil if not found
  def get_file_data
    return nil unless gridfs_file_id

    begin
      grid_file = Mongoid.default_client.database.fs.find_one(_id: gridfs_file_id)
      return nil unless grid_file

      {
        file_name: file_name,
        content_type: file_content_type,
        file_data: grid_file.data,
        file_size: file_size
      }
    rescue StandardError => e
      Rails.logger.error "Failed to retrieve file from GridFS: #{e.message}"
      nil
    end
  end

  private

  # Saves the uploaded Excel file to MongoDB GridFS for long-term storage
  # Sets the gridfs_file_id field on this import
  def save_excel_file
    # Save file to GridFS
    grid_fs = Mongoid.default_client.database.fs

    file_io = StringIO.new(@file_data)
    grid_file = grid_fs.upload_from_stream(
      @file_name,
      file_io,
      {
        content_type: @content_type,
        metadata: {
          account_id: @account_id,
          uploaded_at: Time.current,
          original_filename: @file_name
        }
      }
    )

    self.gridfs_file_id = grid_file
    save!
  end

  # Parses the uploaded Excel file using Roo
  # Extracts headers and all row data from the first sheet
  # Returns an array of hashes, each representing a row (with row_number and data)
  def parse_excel_data
    require 'roo'

    # Create temporary file from ORIGINAL file data (not from GridFS)
    temp_file = Tempfile.new(['excel_import', File.extname(@file_name)])
    begin
      temp_file.binmode
      temp_file.write(@file_data) # Use original data from frontend
      temp_file.rewind

      spreadsheet = Roo::Spreadsheet.open(temp_file.path)

      # Get the first sheet
      sheet = spreadsheet.sheet(0)

      # Get headers from first row
      headers = sheet.row(1).map(&:to_s).map(&:strip)

      # Store metadata
      self.metadata = {
        headers: headers,
        sheet_count: spreadsheet.sheets.count,
        sheet_names: spreadsheet.sheets,
        file_size: file_size
      }

      # Parse all rows (excluding header)
      rows_data = []
      (2..sheet.last_row).each do |row_num|
        row_data = {}
        sheet.row(row_num).each_with_index do |cell_value, index|
          header = headers[index] || "column_#{index + 1}"
          row_data[header] = parse_cell_value(cell_value)
        end

        rows_data << {
          row_number: row_num,
          data: row_data
        }
      end

      self.total_rows = rows_data.count
      save!

      rows_data
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  # Saves each parsed row as an ExcelImportRow document
  # Increments processed_rows or error_count as appropriate
  def save_parsed_rows(parsed_data)
    parsed_data.each do |row_info|
      excel_import_row = ExcelImport::ExcelImportRow.new(
        excel_import_id: id,
        row_number: row_info[:row_number],
        row_data: row_info[:data]
      )

      if excel_import_row.save
        excel_import_row.mark_as_processed
        self.processed_rows += 1
      else
        excel_import_row.mark_as_failed(excel_import_row.errors.full_messages)
        self.error_count += 1
        Rails.logger.error "Failed to save row \\#{row_info[:row_number]}: \\#{excel_import_row.errors.full_messages}"
      end
    end

    save!
  end

  # Normalizes cell values from Excel for consistent storage
  # Converts dates/times to string, strips strings, passes through numbers and nil
  def parse_cell_value(value)
    case value
    when Date, DateTime, Time
      value.to_s
    when Numeric
      value
    when String
      value.strip
    when NilClass
      nil
    else
      value.to_s.strip
    end
  end

  # Updates the status field and updated_at timestamp for this import
  def update_status(new_status)
    self.status = new_status
    self.updated_at = Time.current
    save!
  end

  # Deletes the associated file from GridFS when this import is destroyed
  def cleanup_gridfs_file
    return unless gridfs_file_id

    begin
      grid_fs = Mongoid.default_client.database.fs
      grid_fs.delete(gridfs_file_id)
    rescue StandardError => e
      Rails.logger.error "Failed to delete GridFS file #{gridfs_file_id}: #{e.message}"
    end
  end
end
