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

    title_format = workbook.add_format(bold: 1, size: 14)
    section_format = workbook.add_format(bold: 1, size: 12)
    bold_format = workbook.add_format(bold: 1)

    instructions.write(0, 0, 'Product Catalog Import Template', title_format)

    instructions.write(2, 0, 'Fixed Columns (A-L):', section_format)
    instructions.write(3, 0, '1. Fill in the Products sheet with your product data')
    instructions.write(4, 0, '2. Columns in ORANGE are REQUIRED: Industry, Product Name, Type, Payment Options')
    instructions.write(5, 0, '3. ID column: Leave blank to auto-generate a UUID. Keep a local copy with IDs for future updates.')
    instructions.write(6, 0, '4. Payment Options: Use semicolon-separated values. Only valid: FINANCING, CREDIT, CASH')
    instructions.write(7, 0, '5. URLs: Use semicolon-separated URLs for multiple items')
    instructions.write(8, 0, '6. Delete the example row before uploading')

    instructions.write(10, 0, 'Additional Columns (M-T) - Metadata:', section_format)
    instructions.write(11, 0, '7. You can add up to 8 additional columns after Video URLs (columns M through T)')
    instructions.write(12, 0, '8. These columns will be stored as metadata in JSON format')
    instructions.write(13, 0, '9. Column headers become keys (converted to lowercase snake_case, max 50 characters)')
    instructions.write(14, 0, '10. Each value is limited to 255 characters (for AI processing efficiency)')
    instructions.write(15, 0, '11. Accented characters in headers are converted to ASCII (Año -> ano, Número -> numero)')
    instructions.write(16, 0, '12. Columns beyond T (column 20) will be ignored')

    instructions.write(18, 0, 'Example metadata columns:', bold_format)
    instructions.write(19, 0, '   | M: Periodicidad | N: Color | O: Garantía Meses |')
    instructions.write(20, 0, '   | mensual         | rojo     | 12                |')
    instructions.write(21, 0, '   Result: {"periodicidad": "mensual", "color": "rojo", "garantia_meses": "12"}')
    instructions.write(23, 0, 'Limits: 8 columns, 50 chars per header, 255 chars per value', bold_format)

    instructions.set_column(0, 0, 100)

    workbook.close
    io.string
  end
end
