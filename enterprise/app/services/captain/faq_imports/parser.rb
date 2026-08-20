class Captain::FaqImports::Parser
  MAX_ROWS = 1000
  MAX_QUESTION_LENGTH = 255
  REQUIRED_HEADERS = %w[question answer].freeze

  class InvalidCsvError < StandardError; end

  def initialize(assistant:, content:)
    @assistant = assistant
    @content = content
  end

  def perform
    table = CSV.parse(utf8_content.delete_prefix("\uFEFF"), headers: false)
    headers = table.shift
    validate_headers!(headers)
    raise InvalidCsvError, "CSV files can contain at most #{MAX_ROWS} rows." if table.length > MAX_ROWS

    rows = build_rows(table, headers)
    mark_csv_duplicates!(rows)
    mark_existing_faqs!(rows)
    rows
  rescue CSV::MalformedCSVError => e
    raise InvalidCsvError, "The CSV could not be read: #{e.message}"
  end

  def self.normalize(value)
    value.to_s.strip.gsub(/[[:space:]]+/, ' ').downcase
  end

  private

  def utf8_content
    content = @content.to_s.dup.force_encoding(Encoding::UTF_8)
    return content if content.valid_encoding?

    raise InvalidCsvError, 'The CSV must use UTF-8 encoding.'
  end

  def validate_headers!(headers)
    normalized_headers = Array(headers).map { |header| self.class.normalize(header) }
    return if normalized_headers.length == 2 && normalized_headers.sort == REQUIRED_HEADERS.sort

    raise InvalidCsvError, 'The CSV must have exactly two columns named question and answer.'
  end

  def build_rows(table, headers)
    normalized_headers = headers.map { |header| self.class.normalize(header) }
    question_index = normalized_headers.index('question')
    answer_index = normalized_headers.index('answer')

    table.each_with_index.map do |values, index|
      build_row(values, index + 2, question_index, answer_index)
    end
  end

  def build_row(values, row_number, question_index, answer_index)
    question = values[question_index].to_s.strip if values.length == 2
    answer = values[answer_index].to_s.strip if values.length == 2
    error = row_error(values, question, answer)

    {
      'row_number' => row_number,
      'question' => question.to_s,
      'answer' => answer.to_s,
      'normalized_question' => self.class.normalize(question),
      'normalized_answer' => self.class.normalize(answer),
      'state' => error.present? ? Captain::FaqImport::ROW_STATES[:invalid] : Captain::FaqImport::ROW_STATES[:valid],
      'error' => error
    }
  end

  def row_error(values, question, answer)
    return 'Expected two columns.' unless values.length == 2
    return 'Question is required.' if question.blank?
    return 'Answer is required.' if answer.blank?
    return "Question must be #{MAX_QUESTION_LENGTH} characters or fewer." if question.length > MAX_QUESTION_LENGTH

    nil
  end

  def mark_csv_duplicates!(rows)
    valid_rows(rows).group_by { |row| row['normalized_question'] }.each_value do |group|
      mark_duplicate_group!(group)
    end
  end

  def mark_duplicate_group!(group)
    if group.pluck('normalized_answer').uniq.many?
      group.each do |row|
        row['state'] = Captain::FaqImport::ROW_STATES[:invalid]
        row['error'] = 'The CSV has different answers for this question. ' \
                       'All matching rows will be skipped.'
      end
    else
      group.drop(1).each do |row|
        row['state'] = Captain::FaqImport::ROW_STATES[:duplicate]
        row['error'] = 'Repeated row.'
      end
    end
  end

  def mark_existing_faqs!(rows)
    existing_faqs = existing_faqs_by_question

    valid_rows(rows).each do |row|
      existing = existing_faqs[row['normalized_question']]
      next if existing.blank?

      row['state'] = Captain::FaqImport::ROW_STATES[:existing]
      row['existing_id'] = existing.id
      row['existing_answer'] = existing.answer
      row['resolution'] = Captain::FaqImport::RESOLUTIONS[:skip]
    end
  end

  def existing_faqs_by_question
    @assistant.responses.select(:id, :question, :answer).order(:id).each_with_object({}) do |faq, result|
      result[self.class.normalize(faq.question)] ||= faq
    end
  end

  def valid_rows(rows)
    rows.select { |row| row['state'] == Captain::FaqImport::ROW_STATES[:valid] }
  end
end
