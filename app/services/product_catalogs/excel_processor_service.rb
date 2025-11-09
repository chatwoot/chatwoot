class ProductCatalogs::ExcelProcessorService
  require 'roo'

  COLUMN_MAPPING = {
    product_id: 'A',   # External product ID (e.g., PROD001)
    industry: 'B',
    productName: 'C',  # Maps to productService in Excel
    type: 'D',
    subcategory: 'E',
    listPrice: 'F',
    payment_options: 'G',
    description: 'H',
    link: 'I',
    pdfLinks: 'J',
    photoLinks: 'K',
    videoLinks: 'L'
  }.freeze

  REQUIRED_FIELDS = %i[industry productName type payment_options].freeze  # description is not always required

  def initialize(file_path:, account:, user:, bulk_request:)
    @file_path = file_path
    @account = account
    @user = user
    @bulk_request = bulk_request
    @errors = []
  end

  def process
    xlsx = Roo::Excelx.new(@file_path)
    sheet = xlsx.sheet(0)

    total_rows = sheet.last_row - 1 # Exclude header
    @bulk_request.update!(total_records: total_rows)

    process_rows(sheet)

    {
      success: @errors.empty?,
      total_rows: total_rows,
      errors: @errors
    }
  rescue StandardError => e
    Rails.logger.error("Excel processing error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    @bulk_request.update!(
      status: 'FAILED',
      error_message: e.message
    )
    { success: false, error: e.message }
  end

  private

  def process_rows(sheet)
    (2..sheet.last_row).each_with_index do |row_num, index|
      process_row(sheet, row_num, index + 1)

      # Update progress every 10 rows
      update_progress(index + 1) if (index + 1) % 10 == 0
    end

    # Final progress update
    update_progress(@bulk_request.total_records)
  end

  def process_row(sheet, row_num, index)
    row_data = extract_row_data(sheet, row_num)

    # Validate required fields
    missing_fields = validate_required_fields(row_data)
    if missing_fields.any?
      error_detail = {
        row: row_num,
        product_id: row_data[:product_id],
        product_name: row_data[:productName],
        error: "Missing required fields: #{missing_fields.join(', ')}"
      }
      @errors << error_detail
      @bulk_request.increment!(:failed_records)

      # Update error_details in bulk_request
      current_errors = @bulk_request.error_details || []
      @bulk_request.update!(error_details: current_errors + [error_detail])
      return
    end

    # Create product catalog entry
    create_product_catalog(row_data, row_num)
  rescue StandardError => e
    error_detail = {
      row: row_num,
      product_id: row_data[:product_id],
      product_name: row_data[:productName],
      error: e.message
    }
    @errors << error_detail
    @bulk_request.increment!(:failed_records)

    # Update error_details in bulk_request
    current_errors = @bulk_request.error_details || []
    @bulk_request.update!(error_details: current_errors + [error_detail])
  end

  def extract_row_data(sheet, row_num)
    data = {}
    COLUMN_MAPPING.each do |field, column|
      value = sheet.cell(row_num, column)
      data[field] = value.present? ? value.to_s.strip : nil
    end
    data
  end

  def validate_required_fields(row_data)
    missing = []
    REQUIRED_FIELDS.each do |field|
      missing << field if row_data[field].blank?
    end
    missing
  end

  def create_product_catalog(row_data, row_num)
    # Parse payment options (semicolon-separated)
    payment_options = parse_payment_options(row_data[:payment_options])

    # Convert numeric fields
    listPrice = parse_decimal(row_data[:listPrice])

    # Generate UUID if product_id is blank
    product_id = row_data[:product_id].presence || SecureRandom.uuid

    # Prepare attributes
    attributes = {
      product_id: product_id,
      industry: row_data[:industry],
      productName: row_data[:productName],
      type: row_data[:type],
      subcategory: row_data[:subcategory],
      listPrice: listPrice,
      description: row_data[:description],
      payment_options: payment_options,
      link: row_data[:link],
      pdfLinks: row_data[:pdfLinks],
      photoLinks: row_data[:photoLinks],
      videoLinks: row_data[:videoLinks],
      bulk_processing_request: @bulk_request
    }

    # Upsert: find by product_id and update, or create new
    product = @account.product_catalogs.find_or_initialize_by(product_id: product_id)
    product.assign_attributes(attributes)
    product.save!

    @bulk_request.increment!(:processed_records)
    product
  end

  def parse_payment_options(options_string)
    return nil if options_string.blank?

    # Split by semicolon and validate each option
    options = options_string.split(';').map(&:strip).map(&:upcase)
    valid_options = %w[FINANCING CREDIT CASH]

    invalid = options - valid_options
    raise "Invalid payment options: #{invalid.join(', ')}" if invalid.any?

    options.join(';')
  end

  def parse_decimal(value)
    return nil if value.blank?

    value.to_s.gsub(/[^0-9.]/, '').to_f
  end

  def update_progress(processed_count)
    progress = (processed_count.to_f / @bulk_request.total_records * 50).round(2)
    @bulk_request.update!(progress: progress)
  end
end
