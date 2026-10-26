# A resource for each table in enterprise/config/copilot_tables.yml that has no class of its own, so listing a table
# makes it readable. BaseResource gives the dates, filters and links from the listed columns; this class adds the
# scope, the groups and the display. Only administrators read these tables, as most of them are settings pages.
class Captain::Copilot::Resources::Table < Captain::Copilot::Resources::BaseResource
  ROW_VALUES = 10
  EXCERPT_LENGTH = 120
  # Long enough for settings such as a macro's actions; a longer value says where it was cut.
  JSON_EXCERPT_LENGTH = 4000
  # Settings shown whole, such as an automation rule's actions, drop keys with these names as a last check.
  SECRET_KEY = /(\A|_)(token|secret|password|key|credential|otp|salt|digest|certificate)s?(_|\z)/
  # Rows the dashboard shows only to some administrators.
  VISIBLE = {
    # The macros page lists the global macros and the user's own personal ones.
    'macros' => ->(macros, user) { macros.global.or(macros.personal.where(created_by_id: user.id)) }
  }.freeze

  # One resource per listed table that no other resource class covers.
  def self.generated(written)
    # Development loads models on first use, so they are loaded to find each listed table's model.
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models').to_s)
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('enterprise/app/models').to_s)
    tables = Captain::Copilot::Resources::Columns::TABLES.keys - written.map { |resource| resource::MODEL.table_name }
    tables.sort.map { |table_name| build(model_for(table_name), Captain::Copilot::Resources::Columns::TABLES[table_name]['through']) }
  end

  def self.model_for(table_name)
    model = ApplicationRecord.descendants.find { |candidate| candidate.table_name == table_name && candidate.base_class == candidate }
    model || raise(ArgumentError, "copilot_tables.yml lists #{table_name}, which has no model")
  end

  def self.build(model, through)
    Class.new(self) do
      const_set(:MODEL, model)
      const_set(:THROUGH, through && model.reflect_on_association(through.to_sym))
      const_set(:NAME, model.table_name)
      const_set(:DATE_FIELDS, Captain::Copilot::Resources::Columns.dates(model))
      const_set(:FILTERS, {})
      const_set(:SOURCES, {})
      define_display(model)
    end
  end

  # JSON columns are shown too, so the model can read values such as an automation rule's conditions. A row that belongs
  # to a record with a time zone, such as an inbox's working hours, shows that zone, so the model never supplies one.
  def self.define_display(model)
    shown = shown_columns(model)
    zones = zone_links(model, shown)
    const_set(:SHOWN, shown)
    const_set(:ZONES, zones)
    const_set(:COLUMNS, shown.map(&:humanize) + zones.map { |link| "#{link.name.to_s.humanize} time zone" })
    const_set(:PRELOAD, zones.map(&:name))
  end

  # The name or title is the row's label and long text is left out, so the row shows the short columns and JSON.
  def self.shown_columns(model)
    columns = Captain::Copilot::Resources::Columns.readable(model)
    short = columns.reject { |column| column.type == :text || %w[id name title].include?(column.name) }.map(&:name)
    (short + Captain::Copilot::Resources::Columns.json(model)).first(ROW_VALUES)
  end

  def self.zone_links(model, shown)
    model.reflect_on_all_associations(:belongs_to).select do |link|
      !link.polymorphic? && shown.include?(link.foreign_key.to_s) && link.klass.column_names.include?('timezone')
    end
  end

  def self.help_name
    "#{self::NAME} (administrators)"
  end

  def readable?
    @account.account_users.find_by(user_id: @user.id)&.administrator? || false
  end

  def scope
    raise ArgumentError, "Only administrators can read #{self.class::NAME}" unless readable?

    rows = account_rows
    VISIBLE.key?(self.class::NAME) ? VISIBLE[self.class::NAME].call(rows, @user) : rows
  end

  # The label carries the record's ID, so the model never takes another ID column, such as channel_id, for it.
  def row(record)
    title = record.try(:name).presence || record.try(:title).presence || self.class::NAME.singularize.humanize
    { label: "#{title} (ID #{record.id})", url: nil,
      values: self.class::SHOWN.map { |name| display_value(record.public_send(name)) } +
        self.class::ZONES.map { |link| record.public_send(link.name)&.timezone } }
  end

  private

  # A row belongs to the account through its own account_id, or through the record it belongs to, such as an inbox
  # member through its inbox.
  def account_rows
    model = self.class::MODEL
    through = self.class::THROUGH
    return model.where(account_id: @account.id) unless through

    model.where(through.foreign_key => through.klass.where(account_id: @account.id).select(:id))
  end

  def display_value(value)
    return value.to_s.squish.first(EXCERPT_LENGTH) unless value.is_a?(Hash) || value.is_a?(Array)

    json = without_secrets(value).to_json
    json.length > JSON_EXCERPT_LENGTH ? "#{json.first(JSON_EXCERPT_LENGTH)} [cut at #{JSON_EXCERPT_LENGTH} of #{json.length} characters]" : json
  end

  def without_secrets(value)
    case value
    when Hash then value.reject { |key, _| key.to_s.match?(SECRET_KEY) }.transform_values { |item| without_secrets(item) }
    when Array then value.map { |item| without_secrets(item) }
    else value
    end
  end
end
