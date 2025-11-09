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

  def initialize(products)
    @products = products
  end

  def export
    require 'write_xlsx'

    # Create a new workbook
    io = StringIO.new
    workbook = WriteXLSX.new(io)
    worksheet = workbook.add_worksheet('Products')

    # Write headers
    COLUMN_HEADERS.each_with_index do |header, col|
      worksheet.write(0, col, header)
    end

    # Write product data
    @products.each_with_index do |product, row_index|
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
    end

    workbook.close
    io.string
  end
end
