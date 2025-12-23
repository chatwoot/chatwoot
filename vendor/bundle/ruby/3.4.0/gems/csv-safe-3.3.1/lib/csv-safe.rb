# frozen_string_literal: true

require 'csv'

# Decorate the built in CSV library
# Override << to sanitize incoming rows
# Override initialize to add a converter that will sanitize fields being read
class CSVSafe < CSV
  def initialize(data, converters: nil, **options)
    updated_converters = converters || []
    updated_converters << lambda(&method(:sanitize_field))
    super(data, **options.merge(converters: updated_converters))
  end

  def <<(row)
    super(sanitize_row(row))
  end
  alias_method :add_row, :<<
  alias_method :puts,    :<<

  private

  def starts_with_special_character?(str)
    str.start_with?("-", "=", "+", "@", "%", "|", "\r", "\t")
  end

  def prefix(field)
    encoded = field.encode(CSV::ConverterEncoding)
    "'" + encoded
  rescue StandardError
    "'" + field
  end

  def prefix_if_necessary(field)
    as_string = field.to_s
    if starts_with_special_character?(as_string)
      prefix(as_string)
    else
      field
    end
  end

  def sanitize_field(field)
    if field.nil? || field.is_a?(Numeric)
      field
    else
      prefix_if_necessary(field)
    end
  end

  def sanitize_row(row)
    case row
    when self.class::Row
      then row.fields.map { |field| sanitize_field(field) }
    when Hash
      then @headers.map { |header| sanitize_field(row[header]) }
    else
      row.map { |field| sanitize_field(field) }
    end
  end
end
