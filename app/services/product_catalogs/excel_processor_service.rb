class ProductCatalogs::ExcelProcessorService
  require 'creek'
  require 'csv'

  # Column mapping: Excel column index => DB column name
  COLUMN_MAPPING = {
    0 => 'product_id',      # Column A: product_id
    1 => 'industry',        # Column B: Industry
    2 => 'productName',     # Column C: Product Name (camelCase to match DB)
    3 => 'type',            # Column D: Type
    4 => 'subcategory',     # Column E: Subcategory
    5 => 'listPrice',       # Column F: List Price (camelCase to match DB)
    6 => 'payment_options', # Column G: Payment Options
    7 => 'description',     # Column H: Description
    8 => 'link',            # Column I: External Links
    9 => 'pdfLinks',        # Column J: PDF URLs (camelCase to match DB)
    10 => 'photoLinks',     # Column K: Photo URLs (camelCase to match DB)
    11 => 'videoLinks'      # Column L: Video URLs (camelCase to match DB)
  }.freeze

  REQUIRED_FIELDS = %w[industry productName type payment_options].freeze

  BATCH_SIZE = 50_000 # 50k rows per batch for COPY (5x faster)

  def initialize(file_path:, account:, user:, bulk_request:)
    @file_path = file_path
    @account = account
    @user = user
    @bulk_request = bulk_request
    @errors = []
  end

  def process
    Rails.logger.info("ExcelProcessor: Starting to process Excel file with COPY streaming...")

    # Get raw PostgreSQL connection for COPY
    conn = ActiveRecord::Base.connection.raw_connection

    # Initialize tracking
    @bulk_request.update!(total_records: 0)

    # Process Excel file with streaming + COPY
    total_rows = process_with_copy_streaming(conn)

    Rails.logger.info("ExcelProcessor: Completed processing #{total_rows} rows")

    {
      success: @errors.empty?,
      total_rows: total_rows,
      errors: @errors
    }
  rescue Zip::Error => e
    # Invalid or corrupted Excel file (not a valid zip/xlsx)
    error_msg = "Invalid Excel file: The file appears to be corrupted or is not a valid .xlsx file. #{e.message}"
    handle_processing_error(error_msg, e)
  rescue Roo::Error => e
    # Roo-specific errors (wrong format, can't read file, etc.)
    error_msg = "Invalid Excel file: #{e.message}"
    handle_processing_error(error_msg, e)
  rescue Errno::ENOENT => e
    # File not found
    error_msg = "File not found: The uploaded file could not be located. Please try uploading again."
    handle_processing_error(error_msg, e)
  rescue PG::Error => e
    # PostgreSQL errors (constraint violations, connection issues, etc.)
    error_msg = "Database error while importing products: #{extract_pg_error_message(e)}"
    handle_processing_error(error_msg, e)
  rescue StandardError => e
    # Generic error with full message
    error_msg = "Excel processing failed: #{e.message}"
    handle_processing_error(error_msg, e)
  end

  private

  def handle_processing_error(error_msg, original_error)
    Rails.logger.error("Excel processing error: #{error_msg}")
    Rails.logger.error("Original error: #{original_error.message}")
    Rails.logger.error(original_error.backtrace.join("\n"))
    { success: false, error: error_msg, errors: @errors }
  end

  def extract_pg_error_message(pg_error)
    # Extract a more user-friendly message from PostgreSQL errors
    message = pg_error.message
    if message.include?('duplicate key')
      'A product with the same ID already exists'
    elsif message.include?('violates check constraint')
      'One or more values violate database constraints'
    elsif message.include?('null value in column')
      match = message.match(/null value in column "([^"]+)"/)
      column = match ? match[1] : 'unknown'
      "Required field '#{column}' is missing"
    elsif message.include?('value too long')
      'One or more field values exceed the maximum allowed length'
    else
      message.split("\n").first # Return first line of error
    end
  end

  def process_with_copy_streaming(conn)
    Rails.logger.info("ExcelProcessor: Opening Excel file with Roo streaming...")

    # Use Roo::Excelx for streaming (much faster than Creek)
    xlsx = Roo::Excelx.new(@file_path)
    @roo_temp_dir = xlsx.instance_variable_get(:@tmpdir) # Store temp dir path for cleanup

    Rails.logger.info("ExcelProcessor: Excel opened, starting row iteration...")
    Rails.logger.info("ExcelProcessor: Roo temp dir: #{@roo_temp_dir}")

    row_index = 0
    buffer = []
    last_update_time = Time.current
    last_log_time = Time.current

    # Optimize PostgreSQL for bulk loading (session-level settings only)
    Rails.logger.info("ExcelProcessor: Applying PostgreSQL bulk load optimizations...")
    conn.exec("SET synchronous_commit TO OFF")       # Don't wait for WAL sync
    conn.exec("SET maintenance_work_mem TO '256MB'") # More memory for index building
    conn.exec("SET work_mem TO '64MB'")             # More memory for sorting/hashing

    xlsx.each_row_streaming do |row|
      # Skip header row
      if row_index == 0
        row_index += 1
        next
      end

      # Log progress every 50000 rows (less I/O)
      if row_index % 50_000 == 0 && Time.current - last_log_time > 5.seconds
        Rails.logger.info("ExcelProcessor: Read #{row_index} rows so far...")
        last_log_time = Time.current
      end

      # Check for cancellation every 10000 rows (less DB queries)
      if row_index % 10_000 == 0 && row_index > 0
        @bulk_request.reload
        current_status = @bulk_request.status.upcase
        unless ['PENDING', 'PROCESSING'].include?(current_status)
          Rails.logger.warn("Stopping - bulk request #{@bulk_request.id} status is #{current_status}")
          break
        end
      end

      # Extract and validate row data
      row_data = extract_row_data_roo(row)
      missing_fields = validate_required_fields(row_data)

      if missing_fields.any?
        @errors << {
          row: row_index,
          product_id: row_data['product_id'],
          product_name: row_data['productName'],
          error: "Missing required fields: #{missing_fields.join(', ')}"
        }
        @bulk_request.increment!(:failed_records)
        row_index += 1
        next
      end

      # Add validated row to buffer
      buffer << prepare_row_for_copy(row_data)
      row_index += 1

      # Process batch when full
      if buffer.size >= BATCH_SIZE
        Rails.logger.info("ExcelProcessor: Processing batch at row #{row_index} (#{buffer.size} rows)")
        copy_batch_to_db(conn, buffer)
        @bulk_request.increment!(:processed_records, buffer.size)
        buffer.clear

        # Update progress less frequently (only on batch completion)
        @bulk_request.update!(
          total_records: row_index - 1,
          progress: ((row_index - 1).to_f / [row_index - 1, 1].max * 50).round(2),
          updated_at: Time.current
        )
        last_update_time = Time.current
        Rails.logger.info("ExcelProcessor: Batch done. Total: #{row_index - 1}, Progress: #{@bulk_request.progress}%")
      elsif Time.current - last_update_time > 30.seconds
        # Touch updated_at less frequently (every 30s instead of 10s)
        @bulk_request.update_column(:updated_at, Time.current)
        last_update_time = Time.current
      end
    end

    # Process remaining rows
    if buffer.any?
      copy_batch_to_db(conn, buffer)
      @bulk_request.increment!(:processed_records, buffer.size)
    end

    # Final update
    total = row_index - 1
    @bulk_request.update!(total_records: total)

    total
  ensure
    # Always cleanup Roo temp directory to prevent disk space issues
    cleanup_roo_temp_dir
  end

  # Cleanup Roo's temporary directory (safe for parallel processes - each has unique dir)
  def cleanup_roo_temp_dir
    return unless defined?(@roo_temp_dir) && @roo_temp_dir.present?

    if Dir.exist?(@roo_temp_dir)
      FileUtils.rm_rf(@roo_temp_dir)
      Rails.logger.info("ExcelProcessor: Cleaned up Roo temp dir: #{@roo_temp_dir}")
    end
  rescue StandardError => e
    Rails.logger.warn("ExcelProcessor: Failed to cleanup Roo temp dir: #{e.message}")
  end

  def normalize_value(value)
    case value
    when String
      s = value.strip
      s.empty? ? nil : s
    when Float, Integer
      value
    when Date, Time, DateTime
      value.iso8601
    else
      value.presence
    end
  end

  def prepare_row_for_copy(row_data)
    payment_options = parse_payment_options(row_data['payment_options'])
    list_price = parse_decimal(row_data['listPrice'])
    product_id = row_data['product_id'].presence || SecureRandom.uuid

    [
      @account.id,                    # account_id
      product_id,                     # product_id
      row_data['industry'],           # industry
      row_data['productName'],        # productName
      row_data['type'],               # type
      row_data['subcategory'],        # subcategory
      list_price,                     # listPrice
      row_data['description'],        # description
      payment_options,                # payment_options
      row_data['link'],               # link
      row_data['pdfLinks'],           # pdfLinks
      row_data['photoLinks'],         # photoLinks
      row_data['videoLinks'],         # videoLinks
      @bulk_request.id,               # bulk_processing_request_id
      @user.id,                       # user_id (who created the product)
      @user.id,                       # last_updated_by_id (who last updated)
      Time.current,                   # created_at
      Time.current                    # updated_at
    ]
  end

  def copy_batch_to_db(conn, rows)
    return if rows.empty?

    # Column list for COPY (must match prepare_row_for_copy order)
    columns = %w[
      account_id product_id industry productName type subcategory
      listPrice description payment_options link pdfLinks photoLinks
      videoLinks bulk_processing_request_id user_id last_updated_by_id
      created_at updated_at
    ]

    column_list = columns.map { |c| %("#{c}") }.join(', ')
    temp_table = "temp_products_#{SecureRandom.hex(8)}"

    begin
      # Create temporary table with same structure (no ON COMMIT DROP)
      conn.exec("CREATE TEMP TABLE #{temp_table} (LIKE product_catalogs INCLUDING DEFAULTS)")

      # COPY data into temporary table
      conn.copy_data("COPY #{temp_table} (#{column_list}) FROM STDIN WITH (FORMAT csv)") do
        rows.each do |tuple|
          conn.put_copy_data(CSV.generate_line(tuple, force_quotes: true))
        end
      end

      # Upsert from temp table to real table
      # ON CONFLICT: update all fields except id, account_id, product_id, user_id (creator), created_at
      # Note: user_id is NOT updated on conflict (keeps original creator)
      # last_updated_by_id IS updated on conflict (tracks who made this update)
      update_columns = %w[
        industry productName type subcategory listPrice description
        payment_options link pdfLinks photoLinks videoLinks
        bulk_processing_request_id last_updated_by_id updated_at
      ]
      update_set = update_columns.map { |c| %("#{c}" = EXCLUDED."#{c}") }.join(', ')

      conn.exec(<<~SQL)
        INSERT INTO product_catalogs (#{column_list})
        SELECT #{column_list} FROM #{temp_table}
        ON CONFLICT (account_id, product_id)
        DO UPDATE SET #{update_set}
      SQL
    ensure
      # Always drop the temp table
      conn.exec("DROP TABLE IF EXISTS #{temp_table}")
    end
  end

  def convert_to_csv(excel_path)
    # Create temporary CSV file
    csv_path = "#{excel_path}.csv"

    # Use Roo to convert to CSV (one-time operation)
    xlsx = Roo::Spreadsheet.open(excel_path)
    xlsx.to_csv(csv_path)

    csv_path
  end

  def process_csv_streaming(csv_path)
    row_index = 0
    batch = []
    batch_size = 5000
    last_update_time = Time.current
    last_log_time = Time.current

    Rails.logger.info("ExcelProcessor: Starting to iterate through CSV rows...")

    CSV.foreach(csv_path, headers: false) do |row|
      # Skip header row
      if row_index == 0
        row_index += 1
        next
      end

      # Log progress every 1000 rows
      if row_index % 1000 == 0 && Time.current - last_log_time > 5.seconds
        Rails.logger.info("ExcelProcessor: Read #{row_index} rows so far...")
        last_log_time = Time.current
      end

      # Check status every 1000 rows for faster cancellation detection
      if row_index % 1000 == 0 && row_index > 0
        @bulk_request.reload
        current_status = @bulk_request.status.upcase
        unless ['PENDING', 'PROCESSING'].include?(current_status)
          Rails.logger.warn("Stopping Excel processing - bulk request #{@bulk_request.id} status is #{current_status}")
          break
        end
      end

      # Collect rows in batch
      row_data = extract_row_data_csv(row)
      batch << { row_data: row_data, row_num: row_index }

      row_index += 1

      # Process batch when full
      if batch.size >= batch_size
        Rails.logger.info("ExcelProcessor: Processing batch at row #{row_index} (#{batch.size} rows)")
        process_batch(batch)
        batch = []

        # Update progress, total_records, and updated_at every batch
        @bulk_request.update!(
          total_records: row_index - 1,
          progress: ((row_index - 1).to_f / [row_index - 1, 1].max * 50).round(2),
          updated_at: Time.current
        )
        last_update_time = Time.current
        Rails.logger.info("ExcelProcessor: Batch processed. Total rows: #{row_index - 1}, Progress: #{@bulk_request.progress}%")
      elsif Time.current - last_update_time > 10.seconds
        # Update timestamp every 10 seconds even if batch isn't full
        @bulk_request.update_column(:updated_at, Time.current)
        last_update_time = Time.current
      end
    end

    # Process remaining rows
    process_batch(batch) if batch.any?

    # Final update
    total = row_index - 1
    @bulk_request.update!(total_records: total)

    total
  end

  def process_rows_streaming_roo(xlsx)
    row_index = 0
    batch = []
    batch_size = 5000 # Increased batch size for better performance
    last_update_time = Time.current
    last_log_time = Time.current

    Rails.logger.info("ExcelProcessor: Starting to iterate through rows...")

    # Roo provides each_row_streaming for memory-efficient iteration
    xlsx.each_row_streaming(pad_cells: true) do |row|
      # Skip header row
      if row_index == 0
        row_index += 1
        next
      end

      # Log progress every 1000 rows to see if we're making progress
      if row_index % 1000 == 0 && Time.current - last_log_time > 5.seconds
        Rails.logger.info("ExcelProcessor: Read #{row_index} rows so far...")
        last_log_time = Time.current
      end

      # Check status every 1000 rows for faster cancellation detection
      if row_index % 1000 == 0 && row_index > 0
        @bulk_request.reload
        current_status = @bulk_request.status.upcase
        unless ['PENDING', 'PROCESSING'].include?(current_status)
          Rails.logger.warn("Stopping Excel processing - bulk request #{@bulk_request.id} status is #{current_status}")
          break
        end
      end

      # Collect rows in batch
      row_data = extract_row_data_roo(row)
      batch << { row_data: row_data, row_num: row_index }

      row_index += 1

      # Process batch when full
      if batch.size >= batch_size
        Rails.logger.info("ExcelProcessor: Processing batch at row #{row_index} (#{batch.size} rows)")
        process_batch(batch)
        batch = []

        # Update progress, total_records, and updated_at every batch
        # This keeps updated_at fresh so cleanup job doesn't mark as timed out
        @bulk_request.update!(
          total_records: row_index - 1, # -1 because we're counting header
          progress: ((row_index - 1).to_f / [row_index - 1, 1].max * 50).round(2),
          updated_at: Time.current
        )
        last_update_time = Time.current
        Rails.logger.info("ExcelProcessor: Batch processed. Total rows: #{row_index - 1}, Progress: #{@bulk_request.progress}%")
      elsif Time.current - last_update_time > 10.seconds
        # Update timestamp every 10 seconds even if batch isn't full
        # This prevents timeout detection
        @bulk_request.update_column(:updated_at, Time.current)
        last_update_time = Time.current
      end
    end

    # Process remaining rows
    process_batch(batch) if batch.any?

    # Final update
    total = row_index - 1 # -1 for header
    @bulk_request.update!(total_records: total)

    total
  end

  def process_batch(batch)
    products_to_import = []

    batch.each do |item|
      row_data = item[:row_data]
      row_num = item[:row_num]

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
        next
      end

      # Prepare product for bulk insert
      begin
        payment_options = parse_payment_options(row_data[:payment_options])
        listPrice = parse_decimal(row_data[:listPrice])
        product_id = row_data[:product_id].presence || SecureRandom.uuid

        # Find or initialize product
        product = @account.product_catalogs.find_or_initialize_by(product_id: product_id)
        product.assign_attributes(
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
        )
        products_to_import << product
      rescue StandardError => e
        error_detail = {
          row: row_num,
          product_id: row_data[:product_id],
          product_name: row_data[:productName],
          error: e.message
        }
        @errors << error_detail
        @bulk_request.increment!(:failed_records)

        current_errors = @bulk_request.error_details || []
        @bulk_request.update!(error_details: current_errors + [error_detail])
      end
    end

    # Bulk import products
    if products_to_import.any?
      ProductCatalog.import(products_to_import, on_duplicate_key_update: {
        conflict_target: [:account_id, :product_id],
        columns: [:industry, :productName, :type, :subcategory, :listPrice, :description,
                  :payment_options, :link, :pdfLinks, :photoLinks, :videoLinks,
                  :bulk_processing_request_id, :updated_at]
      })
      @bulk_request.increment!(:processed_records, products_to_import.size)
    end
  end

  def process_row_streaming(row, row_num)
    row_data = extract_row_data_streaming(row)

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

  def extract_row_data_roo(row)
    # Roo returns rows as an array of Cell objects with each_row_streaming
    data = {}
    COLUMN_MAPPING.each do |index, col_name|
      cell = row[index]
      # cell is a Roo::Excelx::Cell object, extract value
      value = cell.respond_to?(:value) ? cell.value : cell
      data[col_name] = value.present? ? value.to_s.strip : nil
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

    # Convert to string first (Roo may return numbers)
    options_str = options_string.to_s.strip
    return nil if options_str.empty?

    # Split by semicolon and validate each option
    options = options_str.split(';').map(&:strip).map(&:upcase)
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
