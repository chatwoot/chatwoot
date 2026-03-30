class Faq::ExcelProcessorService
  require 'roo'

  COLUMN_MAPPING = {
    0 => 'id',
    1 => 'category',
    2 => 'subcategory',
    3 => 'language',
    4 => 'question',
    5 => 'answer',
    6 => 'visible',
    7 => 'position'
  }.freeze

  REQUIRED_FIELDS = %w[category language question answer].freeze
  VALID_LANGUAGES = %w[es en].freeze
  BATCH_SIZE = 1000

  def initialize(file_path:, account:, user:)
    @file_path = file_path
    @account = account
    @user = user
    @errors = []
    @faq_rows = {} # Group rows by ID for multi-language support
    @created_count = 0
    @updated_count = 0
    @created_items = []
    @updated_items = []
  end

  def process
    Rails.logger.info("[FaqExcelProcessor] Starting to process Excel file...")

    # Parse Excel file and group rows by ID
    parse_excel_file

    # Process grouped FAQs
    process_grouped_faqs

    # Dispatch bulk event
    dispatch_bulk_event

    Rails.logger.info("[FaqExcelProcessor] Completed. Created: #{@created_count}, Updated: #{@updated_count}, Errors: #{@errors.size}")

    {
      success: @errors.empty? || (@created_count + @updated_count) > 0,
      created: @created_count,
      updated: @updated_count,
      errors: @errors
    }
  rescue Zip::Error => e
    handle_error("Invalid Excel file: The file appears to be corrupted or is not a valid .xlsx file.", e)
  rescue Roo::Error => e
    handle_error("Invalid Excel file: #{e.message}", e)
  rescue StandardError => e
    handle_error("Excel processing failed: #{e.message}", e)
  end

  private

  def handle_error(message, original_error)
    Rails.logger.error("[FaqExcelProcessor] #{message}")
    Rails.logger.error(original_error.backtrace.join("\n"))
    {
      success: false,
      created: @created_count,
      updated: @updated_count,
      errors: [{ row: 0, error: message }]
    }
  end

  def parse_excel_file
    xlsx = Roo::Excelx.new(@file_path)
    @roo_temp_dir = xlsx.instance_variable_get(:@tmpdir)

    row_index = 0

    xlsx.each_row_streaming(pad_cells: true) do |row|
      # Skip header row
      if row_index == 0
        row_index += 1
        next
      end

      row_data = extract_row_data(row)

      # Validate required fields
      validation_error = validate_row(row_data, row_index)
      if validation_error
        @errors << validation_error
        row_index += 1
        next
      end

      # Group by ID (or generate temporary ID for new FAQs)
      faq_id = row_data['id'].presence || "new_#{row_index}"
      @faq_rows[faq_id] ||= { rows: [], meta: {} }
      @faq_rows[faq_id][:rows] << row_data
      @faq_rows[faq_id][:meta][:row_number] ||= row_index

      row_index += 1
    end
  ensure
    cleanup_roo_temp_dir
  end

  def extract_row_data(row)
    data = {}
    COLUMN_MAPPING.each do |index, col_name|
      cell = row[index]
      value = cell.respond_to?(:value) ? cell.value : cell
      data[col_name] = value.present? ? value.to_s.strip : nil
    end
    data
  end

  def validate_row(row_data, row_index)
    missing = REQUIRED_FIELDS.select { |field| row_data[field].blank? }
    if missing.any?
      return {
        row: row_index,
        error: "Missing required fields: #{missing.join(', ')}"
      }
    end

    # Validate language code
    language = row_data['language']&.downcase
    unless VALID_LANGUAGES.include?(language)
      return {
        row: row_index,
        error: "Invalid language code '#{row_data['language']}'. Valid codes: #{VALID_LANGUAGES.join(', ')}"
      }
    end

    # Validate question length
    question = row_data['question'].to_s
    if question.length > FaqItem::MAX_QUESTION_LENGTH
      return {
        row: row_index,
        error: "Question exceeds #{FaqItem::MAX_QUESTION_LENGTH} characters (#{question.length} chars)"
      }
    end

    # Validate answer length
    answer = row_data['answer'].to_s
    if answer.length > FaqItem::MAX_ANSWER_LENGTH
      return {
        row: row_index,
        error: "Answer exceeds #{FaqItem::MAX_ANSWER_LENGTH} characters (#{answer.length} chars)"
      }
    end

    nil
  end

  def process_grouped_faqs
    @faq_rows.each do |faq_id, data|
      process_faq_group(faq_id, data[:rows], data[:meta][:row_number])
    rescue StandardError => e
      @errors << {
        row: data[:meta][:row_number],
        faq_id: faq_id,
        error: e.message
      }
    end
  end

  def process_faq_group(faq_id, rows, row_number)
    # Use first row for category, position, visibility info
    first_row = rows.first

    # Find or create category
    category = find_or_create_category(first_row['category'], first_row['subcategory'])
    return unless category

    # Build translations from all rows
    translations = build_translations(rows)

    # Parse visibility and position
    is_visible = parse_visibility(first_row['visible'])
    position = first_row['position'].present? ? first_row['position'].to_i : nil

    # Determine the external_id to use (user-provided or nil)
    external_id = faq_id.start_with?('new_') ? nil : faq_id

    # Find existing FAQ by external_id, database id, or content
    existing_faq = find_existing_faq(external_id, category, translations)

    if existing_faq
      upsert_faq(existing_faq, category, translations, is_visible, position, external_id)
    else
      create_faq(category, translations, is_visible, position, external_id)
    end
  end

  def find_existing_faq(external_id, category, translations)
    # First try to find by external_id
    if external_id.present?
      faq = @account.faq_items.find_by(external_id: external_id)
      return faq if faq

      # Also try to find by database id (for backwards compatibility)
      faq = @account.faq_items.find_by(id: external_id) if external_id.match?(/\A\d+\z/)
      return faq if faq
    end

    # Fall back to finding by category + question content
    find_existing_faq_by_content(category, translations)
  end

  def find_existing_faq_by_content(category, translations)
    # Try to find an existing FAQ with matching category and question in any language
    translations.each do |lang, content|
      question = content['question']
      next if question.blank?

      # Search for FAQ with same category and question
      existing = @account.faq_items
        .where(faq_category_id: category.id)
        .where("translations -> ? ->> 'question' = ?", lang, question)
        .first

      return existing if existing
    end

    nil
  end

  def find_or_create_category(category_name, subcategory_name)
    return nil if category_name.blank?

    # Find or create parent category
    parent = @account.faq_categories.find_or_create_by!(
      name: category_name,
      parent_id: nil
    ) do |c|
      c.created_by = @user
    end

    return parent if subcategory_name.blank?

    # Find or create subcategory
    @account.faq_categories.find_or_create_by!(
      name: subcategory_name,
      parent_id: parent.id
    ) do |c|
      c.created_by = @user
    end
  rescue ActiveRecord::RecordInvalid => e
    # Handle category limit errors gracefully
    @errors << { row: 0, error: "Category error for '#{category_name}': #{e.message}" }
    nil
  end

  def build_translations(rows)
    rows.each_with_object({}) do |row, translations|
      lang = row['language'].downcase
      translations[lang] = {
        'question' => row['question']&.truncate(FaqItem::MAX_QUESTION_LENGTH, omission: ''),
        'answer' => row['answer']&.truncate(FaqItem::MAX_ANSWER_LENGTH, omission: '')
      }
    end
  end

  def parse_visibility(value)
    return true if value.blank?

    case value.to_s.downcase
    when 'true', '1', 'yes', 'si', 'sí'
      true
    when 'false', '0', 'no'
      false
    else
      true
    end
  end

  def create_faq(category, translations, is_visible, position, external_id = nil)
    faq = @account.faq_items.new(
      faq_category: category,
      translations: translations,
      is_visible: is_visible,
      position: position || next_position_for_category(category.id),
      external_id: external_id,
      created_by: @user,
      skip_catalog_callbacks: true
    )

    if faq.save
      @created_count += 1
      @created_items << { id: faq.id, faq_category_id: faq.faq_category_id }
    else
      @errors << { row: 0, error: "Failed to create FAQ: #{faq.errors.full_messages.join(', ')}" }
    end
  end

  def upsert_faq(faq, category, translations, is_visible, position, external_id = nil)
    # Update existing - merge translations
    merged_translations = (faq.translations || {}).merge(translations)
    faq.assign_attributes(
      faq_category: category,
      translations: merged_translations,
      is_visible: is_visible,
      position: position || faq.position,
      external_id: external_id || faq.external_id,
      updated_by: @user,
      skip_catalog_callbacks: true
    )

    if faq.save
      @updated_count += 1
      @updated_items << { id: faq.id, faq_category_id: faq.faq_category_id }
    else
      @errors << { faq_id: faq.id, error: "Failed to update FAQ: #{faq.errors.full_messages.join(', ')}" }
    end
  end

  def next_position_for_category(category_id)
    max_position = @account.faq_items.where(faq_category_id: category_id).maximum(:position)
    (max_position || 0) + 1
  end

  def dispatch_bulk_event
    return if @created_count.zero? && @updated_count.zero?

    Rails.configuration.dispatcher.dispatch(
      Events::Types::FAQ_CATALOG_UPDATED,
      Time.zone.now,
      account: @account,
      added_count: @created_count,
      updated_count: @updated_count,
      deleted_count: 0,
      added_faq_items: @created_items,
      updated_faq_items: @updated_items,
      deleted_faq_items: []
    )
  end

  def cleanup_roo_temp_dir
    return unless defined?(@roo_temp_dir) && @roo_temp_dir.present?

    if Dir.exist?(@roo_temp_dir)
      FileUtils.rm_rf(@roo_temp_dir)
      Rails.logger.info("[FaqExcelProcessor] Cleaned up Roo temp dir: #{@roo_temp_dir}")
    end
  rescue StandardError => e
    Rails.logger.warn("[FaqExcelProcessor] Failed to cleanup Roo temp dir: #{e.message}")
  end
end
