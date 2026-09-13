class Captain::Apropos::TableDisplay
  MAX_ROWS = 1_000
  MAX_COLUMNS = 20
  MAX_BYTES = 100_000
  CONTRACT = {
    arguments: 'rows: list of objects; columns: ordered list of field-name strings or {key, label?, type?, id_key?}. Keys must be unique.',
    cells: 'Types: text (default, scalar), number (finite), datetime (ISO8601 with timezone), status (open/resolved/pending/snoozed), ' \
           'tags (string list), conversation, contact. Null is allowed. Every row must contain each selected field. Empty rows are allowed.',
    links: 'conversation/contact require id_key naming a row field containing a positive integer or null. ' \
           'Use conversation display_id, NOT database id; contacts use database id. Null IDs render plain text. ' \
           'ID fields are retained but not shown unless selected. Links stay in the current account; no arbitrary URLs or HTML.',
    example: '(show-table rows (list (hash "key" "display_id" "label" "Conversation" "type" "conversation" "id_key" "display_id") ' \
             '(hash "key" "labels" "type" "tags")))',
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
    columns = normalize_columns(columns)
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

  def normalize_columns(columns)
    raise Captain::Apropos::Error, 'show-table requires 1 to 20 columns' unless columns.is_a?(Array) && columns.size.between?(1, MAX_COLUMNS)

    normalized = columns.map { |column| Captain::Apropos::TableColumn.normalize(column) }
    keys = normalized.pluck('key')
    raise Captain::Apropos::Error, 'show-table column keys must be unique' unless keys.uniq == keys

    normalized
  end

  def project_row(row, columns)
    unless row.is_a?(Hash) && columns.all? { |column| valid_column?(row, column) }
      raise Captain::Apropos::Error, 'show-table row is missing a field or has a value incompatible with its column type or link ID'
    end

    row.slice(*columns.flat_map { |column| column.values_at('key', 'id_key').compact })
  end

  def valid_column?(row, column)
    key = column.fetch('key')
    return false unless row.key?(key) && Captain::Apropos::TableColumn.valid_cell?(row[key], column.fetch('type'))
    return true unless column.key?('id_key')

    id_key = column.fetch('id_key')
    row.key?(id_key) && (row[id_key].nil? || (row[id_key].is_a?(Integer) && row[id_key].positive?))
  end
end
