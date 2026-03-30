class Faq::ExcelExporterService
  require 'write_xlsx'

  COLUMN_HEADERS = ['ID', 'Category', 'Subcategory', 'Language', 'Question', 'Answer', 'Visible', 'Position'].freeze

  def initialize(faq_items, logger: nil)
    @faq_items = faq_items
    @logger = logger || Rails.logger
  end

  def export
    @logger.info("[FaqExcelExporter] Starting export...")

    io = StringIO.new
    workbook = WriteXLSX.new(io)
    worksheet = workbook.add_worksheet('FAQs')

    # Create header format
    header_format = workbook.add_format(
      bold: 1,
      bg_color: '#4F81BD',
      color: 'white',
      border: 1
    )

    # Write headers
    COLUMN_HEADERS.each_with_index do |header, col|
      worksheet.write(0, col, header, header_format)
    end

    # Set column widths
    worksheet.set_column(0, 0, 40)  # ID (UUID)
    worksheet.set_column(1, 1, 20)  # Category
    worksheet.set_column(2, 2, 20)  # Subcategory
    worksheet.set_column(3, 3, 10)  # Language
    worksheet.set_column(4, 4, 40)  # Question
    worksheet.set_column(5, 5, 60)  # Answer
    worksheet.set_column(6, 6, 10)  # Visible
    worksheet.set_column(7, 7, 10)  # Position

    # Write FAQ rows
    row_index = 1
    row_count = 0

    @faq_items.includes(:faq_category).find_each do |faq|
      category = faq.faq_category
      category_name = resolve_category_name(category)
      subcategory_name = resolve_subcategory_name(category)

      # Write one row per language
      translations = faq.translations || {}

      if translations.empty?
        # FAQ with no translations - write a single row
        write_faq_row(worksheet, row_index, faq, category_name, subcategory_name, '', '', '')
        row_index += 1
        row_count += 1
      else
        translations.each do |lang, content|
          question = content['question'].to_s
          answer = content['answer'].to_s

          write_faq_row(worksheet, row_index, faq, category_name, subcategory_name, lang, question, answer)
          row_index += 1
          row_count += 1
        end
      end
    end

    workbook.close

    @logger.info("[FaqExcelExporter] Export completed: #{row_count} rows written")
    io.string
  end

  private

  def resolve_category_name(category)
    return nil unless category

    if category.parent
      category.parent.name
    else
      category.name
    end
  end

  def resolve_subcategory_name(category)
    return nil unless category
    return category.name if category.parent

    nil
  end

  def write_faq_row(worksheet, row, faq, category_name, subcategory_name, language, question, answer)
    # Use external_id if available, otherwise use database id
    faq_id = faq.respond_to?(:external_id) && faq.external_id.present? ? faq.external_id : faq.id.to_s
    worksheet.write_string(row, 0, faq_id)
    worksheet.write(row, 1, category_name)
    worksheet.write(row, 2, subcategory_name)
    worksheet.write(row, 3, language)
    worksheet.write_string(row, 4, question)
    worksheet.write_string(row, 5, answer)
    worksheet.write(row, 6, faq.is_visible.to_s)
    worksheet.write(row, 7, faq.position)
  end
end
