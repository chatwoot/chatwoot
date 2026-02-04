class ProductCatalogs::ExcelExporterService
  require 'roo'

  COLUMN_HEADERS = [
    'ID',
    'Industry',
    'Product Name',
    'Type',
    'Subcategory',
    'List Price',
    'Payment Options',
    'Description',
    'External Links',
    'PDF URLs',
    'Photo URLs',
    'Video URLs'
  ].freeze

  # Columns that contain URLs - write as plain text to avoid Excel's 65,530 hyperlink limit
  URL_COLUMNS = [8, 9, 10, 11].freeze

  CHUNK_SIZE = 500
  MAX_PRODUCTS_PER_FILE = 50_000

  def initialize(products, total_count: nil, logger: nil)
    @products = products
    @total_count = total_count || products.count
    @logger = logger || Rails.logger
  end

  # Original export method for small exports (selected products)
  def export(&progress_callback)
    require 'write_xlsx'

    @logger.info "[ExcelExporter] Starting export of #{@total_count} products (single file mode)"

    # Create a new workbook
    io = StringIO.new
    workbook = WriteXLSX.new(io)
    worksheet = workbook.add_worksheet('Products')

    # Write headers
    COLUMN_HEADERS.each_with_index do |header, col|
      worksheet.write(0, col, header)
    end

    # Write product data in chunks
    row_index = 0
    @products.find_each(batch_size: CHUNK_SIZE) do |product|
      row = row_index + 1
      write_product_row(worksheet, row, product)
      row_index += 1

      # Report progress every chunk
      if progress_callback && (row_index % CHUNK_SIZE).zero?
        progress_callback.call(row_index, @total_count)
      end
    end

    # Final progress update
    progress_callback&.call(row_index, @total_count)

    workbook.close
    @logger.info "[ExcelExporter] Export completed: #{row_index} products written"
    io.string
  end

  # Export method that yields multiple files for large exports
  # Each file contains max MAX_PRODUCTS_PER_FILE products
  #
  # on_file_complete: block called when a file is ready
  #   Yields: |file_data, file_number, total_processed, progress_info|
  #
  # on_progress: optional block called periodically during export
  #   Yields: |total_processed, total_count, progress_percent, status_message|
  #
  def export_in_chunks(on_progress: nil, &on_file_complete)
    require 'write_xlsx'

    @logger.info "=" * 60
    @logger.info "[ExcelExporter] STARTING FULL EXPORT"
    @logger.info "[ExcelExporter] Total products to export: #{@total_count}"
    @logger.info "[ExcelExporter] Max products per file: #{MAX_PRODUCTS_PER_FILE}"
    @logger.info "[ExcelExporter] Estimated files: #{(@total_count.to_f / MAX_PRODUCTS_PER_FILE).ceil}"
    @logger.info "=" * 60

    file_number = 1
    row_index_in_file = 0
    total_processed = 0
    workbook = nil
    worksheet = nil
    io = nil
    file_start_time = nil
    export_start_time = Time.current
    last_progress_report = 0

    # Report initial progress
    report_progress(on_progress, 0, @total_count, 0, "Starting export...")

    @products.find_each(batch_size: CHUNK_SIZE) do |product|
      # Start a new file if needed
      if workbook.nil? || row_index_in_file >= MAX_PRODUCTS_PER_FILE
        # Close and yield previous file if exists
        if workbook
          workbook.close
          file_duration = Time.current - file_start_time
          file_size_kb = (io.string.bytesize / 1024.0).round(2)

          @logger.info "-" * 40
          @logger.info "[ExcelExporter] FILE #{file_number} COMPLETED"
          @logger.info "[ExcelExporter]   Products in file: #{row_index_in_file}"
          @logger.info "[ExcelExporter]   File size: #{file_size_kb} KB"
          @logger.info "[ExcelExporter]   Time taken: #{file_duration.round(2)}s"
          @logger.info "[ExcelExporter]   Total progress: #{total_processed}/#{@total_count} (#{(total_processed.to_f / @total_count * 100).round(2)}%)"
          @logger.info "-" * 40

          progress_info = {
            file_number: file_number,
            products_in_file: row_index_in_file,
            file_size_kb: file_size_kb,
            duration_seconds: file_duration.round(2),
            total_processed: total_processed,
            total_count: @total_count
          }

          # Report progress - file completed
          progress = (total_processed.to_f / @total_count * 100).round(2)
          report_progress(on_progress, total_processed, @total_count, progress,
                          "File #{file_number} completed (#{file_size_kb} KB). Saving...")

          on_file_complete.call(io.string, file_number, total_processed, progress_info)
          file_number += 1
        end

        # Create new workbook
        @logger.info "[ExcelExporter] Creating file #{file_number}..."
        report_progress(on_progress, total_processed, @total_count,
                        (total_processed.to_f / @total_count * 100).round(2),
                        "Creating file #{file_number}...")

        file_start_time = Time.current
        io = StringIO.new
        workbook = WriteXLSX.new(io)
        worksheet = workbook.add_worksheet('Products')

        # Write headers
        COLUMN_HEADERS.each_with_index do |header, col|
          worksheet.write(0, col, header)
        end

        row_index_in_file = 0
      end

      # Write product data
      row = row_index_in_file + 1
      write_product_row(worksheet, row, product)

      row_index_in_file += 1
      total_processed += 1

      # Report progress every 2,000 products (more frequent updates)
      if total_processed - last_progress_report >= 2000
        elapsed = Time.current - export_start_time
        rate = total_processed / elapsed
        eta_seconds = (@total_count - total_processed) / rate
        eta_min = (eta_seconds / 60).round(1)
        progress = (total_processed.to_f / @total_count * 100).round(2)

        status_msg = "Exportando producto #{total_processed} de #{@total_count} " \
                     "(#{rate.round(0)}/seg, ETA: #{eta_min} min)"

        @logger.info "[ExcelExporter] Progress: #{total_processed}/#{@total_count} (#{progress}%) | Rate: #{rate.round(0)}/s | ETA: #{eta_min} min"

        report_progress(on_progress, total_processed, @total_count, progress, status_msg)
        last_progress_report = total_processed
      end
    end

    # Close and yield the last file
    if workbook
      workbook.close
      file_duration = Time.current - file_start_time
      file_size_kb = (io.string.bytesize / 1024.0).round(2)

      @logger.info "-" * 40
      @logger.info "[ExcelExporter] FILE #{file_number} COMPLETED (FINAL)"
      @logger.info "[ExcelExporter]   Products in file: #{row_index_in_file}"
      @logger.info "[ExcelExporter]   File size: #{file_size_kb} KB"
      @logger.info "[ExcelExporter]   Time taken: #{file_duration.round(2)}s"
      @logger.info "-" * 40

      progress_info = {
        file_number: file_number,
        products_in_file: row_index_in_file,
        file_size_kb: file_size_kb,
        duration_seconds: file_duration.round(2),
        total_processed: total_processed,
        total_count: @total_count
      }

      report_progress(on_progress, total_processed, @total_count, 100,
                      "Archivo final #{file_number} completado. Finalizando...")

      on_file_complete.call(io.string, file_number, total_processed, progress_info)
    end

    total_duration = Time.current - export_start_time
    @logger.info "=" * 60
    @logger.info "[ExcelExporter] EXPORT COMPLETED"
    @logger.info "[ExcelExporter] Total products: #{total_processed}"
    @logger.info "[ExcelExporter] Total files: #{file_number}"
    @logger.info "[ExcelExporter] Total time: #{(total_duration / 60).round(2)} minutes"
    @logger.info "[ExcelExporter] Average rate: #{(total_processed / total_duration).round(0)} products/second"
    @logger.info "=" * 60

    total_processed
  end

  private

  # Report progress to the callback if provided
  def report_progress(callback, processed, total, percent, message)
    return unless callback

    callback.call(processed, total, percent, message)
  end

  # Write a product row to the worksheet
  # Uses write_string for URL columns to avoid Excel's hyperlink limit (65,530 per sheet)
  def write_product_row(worksheet, row, product)
    worksheet.write(row, 0, product.product_id)
    worksheet.write(row, 1, product.industry)
    worksheet.write(row, 2, product.productName)
    worksheet.write(row, 3, product.type)
    worksheet.write(row, 4, product.subcategory)
    worksheet.write(row, 5, product.listPrice)
    worksheet.write(row, 6, product.payment_options)
    worksheet.write(row, 7, product.description)

    # Write URL columns as plain text strings to avoid hyperlink limit
    # Excel has a limit of 65,530 hyperlinks per worksheet
    worksheet.write_string(row, 8, product.link.to_s)
    worksheet.write_string(row, 9, product.pdfLinks.to_s)
    worksheet.write_string(row, 10, product.photoLinks.to_s)
    worksheet.write_string(row, 11, product.videoLinks.to_s)
  end
end
