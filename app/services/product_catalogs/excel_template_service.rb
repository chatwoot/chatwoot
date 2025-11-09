class ProductCatalogs::ExcelTemplateService
  require 'write_xlsx'

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

  EXAMPLE_DATA = [
    [
      'PROD001',
      'Technology',
      'Laptop Pro 15"',
      'Electronics',
      'Computers',
      '1299.99',
      'FINANCING;CREDIT;CASH',
      'High-performance laptop with 16GB RAM and 512GB SSD',
      'https://example.com/laptop-pro',
      'https://example.com/manual.pdf',
      'https://example.com/images/laptop1.jpg;https://example.com/images/laptop2.jpg',
      'https://example.com/videos/demo.mp4'
    ]
  ].freeze

  def generate
    io = StringIO.new
    workbook = WriteXLSX.new(io)
    worksheet = workbook.add_worksheet('Products')

    # Create formats
    header_format = workbook.add_format(
      bold: 1,
      bg_color: '#4F81BD',
      color: 'white',
      border: 1
    )

    required_format = workbook.add_format(
      bold: 1,
      bg_color: '#FFC000',
      color: 'black',
      border: 1
    )

    example_format = workbook.add_format(
      italic: 1,
      bg_color: '#E7E6E6',
      border: 1
    )

    # Write headers with formatting
    COLUMN_HEADERS.each_with_index do |header, col|
      # Required columns: Industry, Product Name, Type, Payment Options
      format = [1, 2, 3, 6].include?(col) ? required_format : header_format
      worksheet.write(0, col, header, format)
    end

    # Write example row
    EXAMPLE_DATA.first.each_with_index do |value, col|
      worksheet.write(1, col, value, example_format)
    end

    # Set column widths
    worksheet.set_column(0, 0, 15)   # ID
    worksheet.set_column(1, 1, 15)   # Industry
    worksheet.set_column(2, 2, 30)   # Product Name
    worksheet.set_column(3, 3, 15)   # Type
    worksheet.set_column(4, 4, 15)   # Subcategory
    worksheet.set_column(5, 5, 12)   # List Price
    worksheet.set_column(6, 6, 25)   # Payment Options
    worksheet.set_column(7, 7, 40)   # Description
    worksheet.set_column(8, 11, 30)  # URLs columns

    # Add instructions sheet
    instructions = workbook.add_worksheet('Instructions')

    instructions.write(0, 0, 'Product Catalog Import Template', workbook.add_format(bold: 1, size: 14))
    instructions.write(2, 0, 'Instructions:', workbook.add_format(bold: 1))
    instructions.write(3, 0, '1. Fill in the Products sheet with your product data')
    instructions.write(4, 0, '2. Columns in ORANGE are REQUIRED')
    instructions.write(5, 0, '3. ID column: Leave blank to auto-generate a UUID')
    instructions.write(6, 0, '4. Payment Options: Use semicolon-separated values (FINANCING;CREDIT;CASH)')
    instructions.write(7, 0, '5. URLs: Use semicolon-separated URLs for multiple items')
    instructions.write(8, 0, '6. Delete the example row before uploading')

    instructions.set_column(0, 0, 80)

    workbook.close
    io.string
  end
end
