class Faq::ExcelTemplateService
  require 'write_xlsx'

  COLUMN_HEADERS = ['ID', 'Category', 'Subcategory', 'Language', 'Question', 'Answer', 'Visible', 'Position'].freeze
  REQUIRED_COLUMNS = [1, 3, 4, 5].freeze # Category, Language, Question, Answer (0-indexed)

  EXAMPLE_DATA = [
    ['FAQ001', 'Envíos', '', 'es', '¿Cuánto tarda mi pedido?', 'Los pedidos tardan de 3 a 5 días hábiles.', 'true', '1'],
    ['FAQ001', 'Envíos', '', 'en', 'How long does shipping take?', 'Orders take 3-5 business days.', 'true', '1'],
    ['FAQ002', 'Pagos', 'Métodos', 'es', '¿Qué métodos de pago aceptan?', 'Aceptamos tarjeta, transferencia y PayPal.', 'true', '1']
  ].freeze

  LANGUAGES = [
    { code: 'es', name: 'Español' },
    { code: 'en', name: 'English' }
  ].freeze

  def generate
    io = StringIO.new
    workbook = WriteXLSX.new(io)

    create_faqs_sheet(workbook)
    create_instructions_sheet(workbook)

    workbook.close
    io.string
  end

  private

  def create_faqs_sheet(workbook)
    worksheet = workbook.add_worksheet('FAQs')

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
      format = REQUIRED_COLUMNS.include?(col) ? required_format : header_format
      worksheet.write(0, col, header, format)
    end

    # Write example rows
    EXAMPLE_DATA.each_with_index do |row_data, row_index|
      row_data.each_with_index do |value, col|
        worksheet.write(row_index + 1, col, value, example_format)
      end
    end

    # Set column widths
    worksheet.set_column(0, 0, 15)  # ID
    worksheet.set_column(1, 1, 20)  # Category
    worksheet.set_column(2, 2, 20)  # Subcategory
    worksheet.set_column(3, 3, 10)  # Language
    worksheet.set_column(4, 4, 40)  # Question
    worksheet.set_column(5, 5, 60)  # Answer
    worksheet.set_column(6, 6, 10)  # Visible
    worksheet.set_column(7, 7, 10)  # Position
  end

  def create_instructions_sheet(workbook)
    worksheet = workbook.add_worksheet('Instructions')

    title_format = workbook.add_format(bold: 1, size: 14)
    section_format = workbook.add_format(bold: 1, size: 11)
    normal_format = workbook.add_format(text_wrap: 1)

    row = 0

    worksheet.write(row, 0, 'FAQ Import Template - Nauto', title_format)
    row += 2

    worksheet.write(row, 0, 'INSTRUCCIONES:', section_format)
    row += 1
    worksheet.write(row, 0, '1. Usa la hoja "FAQs" para agregar tus preguntas frecuentes', normal_format)
    row += 1
    worksheet.write(row, 0, '2. Las columnas en NARANJA son REQUERIDAS', normal_format)
    row += 1
    worksheet.write(row, 0, '3. Elimina las filas de ejemplo antes de subir el archivo', normal_format)
    row += 2

    worksheet.write(row, 0, 'COLUMNAS:', section_format)
    row += 1
    worksheet.write(row, 0, '• ID: Deja vacío para crear nuevo FAQ, o usa un ID existente para actualizar', normal_format)
    row += 1
    worksheet.write(row, 0, '• Category: Nombre de la categoría principal (se crea automáticamente si no existe)', normal_format)
    row += 1
    worksheet.write(row, 0, '• Subcategory: Nombre de subcategoría (opcional, máximo 2 niveles de profundidad)', normal_format)
    row += 1
    worksheet.write(row, 0, '• Language: Código del idioma (ver formatos disponibles abajo)', normal_format)
    row += 1
    worksheet.write(row, 0, '• Question: La pregunta (máximo 256 caracteres)', normal_format)
    row += 1
    worksheet.write(row, 0, '• Answer: La respuesta (máximo 2048 caracteres)', normal_format)
    row += 1
    worksheet.write(row, 0, '• Visible: true o false (default: true)', normal_format)
    row += 1
    worksheet.write(row, 0, '• Position: Número para ordenar dentro de la categoría', normal_format)
    row += 2

    worksheet.write(row, 0, 'IDIOMAS DISPONIBLES:', section_format)
    row += 1
    LANGUAGES.each do |lang|
      worksheet.write(row, 0, "• #{lang[:code]} - #{lang[:name]}", normal_format)
      row += 1
    end
    row += 1

    worksheet.write(row, 0, 'FORMATOS:', section_format)
    row += 1
    worksheet.write(row, 0, '• Language: Usar códigos en minúscula (es, en)', normal_format)
    row += 1
    worksheet.write(row, 0, '• Visible: true, false, 1, 0, yes, no', normal_format)
    row += 1
    worksheet.write(row, 0, '• Position: Número entero positivo', normal_format)
    row += 2

    worksheet.write(row, 0, 'MULTI-IDIOMA:', section_format)
    row += 1
    worksheet.write(row, 0, 'Para agregar traducciones, usa el mismo ID con diferentes valores en Language.', normal_format)
    row += 1
    worksheet.write(row, 0, 'Ejemplo:', normal_format)
    row += 1
    worksheet.write(row, 0, '  ID       | Language | Question', normal_format)
    row += 1
    worksheet.write(row, 0, '  FAQ001   | es       | ¿Cuál es el horario?', normal_format)
    row += 1
    worksheet.write(row, 0, '  FAQ001   | en       | What are the hours?', normal_format)
    row += 2

    worksheet.write(row, 0, 'LÍMITES:', section_format)
    row += 1
    worksheet.write(row, 0, '• Máximo 250 categorías por cuenta', normal_format)
    row += 1
    worksheet.write(row, 0, '• Máximo 200 FAQs por categoría', normal_format)
    row += 1
    worksheet.write(row, 0, '• Question: máximo 256 caracteres', normal_format)
    row += 1
    worksheet.write(row, 0, '• Answer: máximo 2048 caracteres', normal_format)

    worksheet.set_column(0, 0, 80)
  end
end
