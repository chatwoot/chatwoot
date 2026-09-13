class Captain::Apropos::TableDisplay
  MAX_ROWS = 1_000
  MAX_COLUMNS = 20
  MAX_BYTES = 100_000
  CONTRACT = {
    arguments: 'rows: list of objects; columns: ordered list of unique, nonblank field-name strings. Every row must contain each selected field.',
    cells: 'Selected values must be strings, finite numbers, booleans, or null. Other fields are ignored. Empty rows are allowed.',
    limits: 'At most 1000 rows, 20 columns, and 100000 JSON bytes per table. Oversized input fails without displaying anything. Never truncates.',
    effects: 'Displays a table to the user as part of the current answer, retained when the chat is reopened. No Chatwoot records are changed. ' \
             'No need to repeat the displayed rows in prose. Calls from workers also display in the parent answer.',
    returns: 'Display receipt {displayed: true, table_id, row_count}. Rows are not returned to model context.',
    retry: 'Each successful call creates a new table. Later execution errors do not remove displayed tables; do not repeat successful calls.'
  }.freeze

  def initialize(record:)
    @record = record
  end

  def call(rows, columns)
    validate_columns!(columns)
    raise Captain::Apropos::Error, 'show-table rows must be a list of at most 1000 objects' unless rows.is_a?(Array) && rows.size <= MAX_ROWS

    projected = rows.map { |row| project_row(row, columns) }
    table = { 'table_id' => SecureRandom.uuid, 'columns' => columns, 'rows' => projected }
    if JSON.generate(table).bytesize > MAX_BYTES
      raise Captain::Apropos::Error, 'show-table exceeds 100000 JSON bytes; select fewer rows or smaller fields'
    end

    @record.call('table', table.deep_dup)
    { 'displayed' => true, 'table_id' => table.fetch('table_id'), 'row_count' => projected.size }
  end

  private

  def validate_columns!(columns)
    unless columns.is_a?(Array) && columns.size.between?(1, MAX_COLUMNS) && columns.uniq == columns &&
           columns.all? { |column| column.is_a?(String) && column.strip.present? }
      raise Captain::Apropos::Error, 'show-table columns must contain 1 to 20 unique nonblank field-name strings'
    end
  end

  def project_row(row, columns)
    unless row.is_a?(Hash) && columns.all? { |column| row.key?(column) && scalar?(row[column]) }
      raise Captain::Apropos::Error, 'show-table every row must contain all selected columns with scalar or null values'
    end

    row.slice(*columns)
  end

  def scalar?(value)
    value.nil? || value.is_a?(String) || value.is_a?(Integer) || value == true || value == false || (value.is_a?(Float) && value.finite?)
  end
end
