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

  CHUNK_SIZE = 500

  def initialize(products, total_count: nil)
    @products = products
    @total_count = total_count || products.count
  end

  def export(&progress_callback)
    require 'write_xlsx'

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

      worksheet.write(row, 0, product.product_id)
      worksheet.write(row, 1, product.industry)
      worksheet.write(row, 2, product.productName)
      worksheet.write(row, 3, product.type)
      worksheet.write(row, 4, product.subcategory)
      worksheet.write(row, 5, product.listPrice)
      worksheet.write(row, 6, product.payment_options)
      worksheet.write(row, 7, product.description)
      worksheet.write(row, 8, product.link)
      worksheet.write(row, 9, product.pdfLinks)
      worksheet.write(row, 10, product.photoLinks)
      worksheet.write(row, 11, product.videoLinks)

      row_index += 1

      # Report progress every chunk
      if progress_callback && (row_index % CHUNK_SIZE).zero?
        progress_callback.call(row_index, @total_count)
      end
    end

    # Final progress update
    progress_callback&.call(row_index, @total_count)

    workbook.close
    io.string
  end
end
