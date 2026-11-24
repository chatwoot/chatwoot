# Medians are computed in Ruby, because ActiveRecord has no median. Every group is kept, so the caller cuts the list.
class Captain::Copilot::Aggregation::Medians
  MEDIAN_ROWS = 100_000

  def initialize(relation, time_zone:)
    @relation = relation
    @time_zone = time_zone
  end

  def call(fields, value)
    rows = median_rows(fields, value)
    return median(rows.map(&:last)) if fields.empty?

    in_order(rows.group_by { |row| median_key(row, fields) }.transform_values { |group| median(group.map(&:last)) }, fields)
  end

  private

  # Whole numbers, such as hours, are padded so they sort as text with the other keys.
  def in_order(medians, fields)
    return medians.sort_by { |_, median| -median.to_f }.to_h unless fields.any?(&:date?)

    medians.sort_by { |key, _| Array(key).map { |part| part.is_a?(Integer) ? format('%012d', part) : part.to_s } }.to_h
  end

  def median_rows(fields, value)
    rows = @relation.where(value.not_eq(nil)).limit(MEDIAN_ROWS + 1).pluck(*fields.map(&:selected), value)
    raise ArgumentError, "A median reads at most #{MEDIAN_ROWS} records. Narrow the filters." if rows.size > MEDIAN_ROWS

    rows.map { |row| Array(row) }
  end

  def median_key(row, fields)
    keys = fields.each_with_index.map { |field, index| field.date? && row[index] ? date_part(row[index], field.part) : row[index] }
    fields.one? ? keys.first : keys
  end

  def date_part(time, part)
    time = time.in_time_zone(@time_zone)
    { 'hour_of_day' => time.hour, 'day_of_week' => time.wday, 'day' => time.to_date, 'week' => time.to_date.beginning_of_week(:sunday),
      'month' => time.to_date.beginning_of_month, 'year' => time.to_date.beginning_of_year }.fetch(part)
  end

  def median(values)
    return if values.empty?

    sorted = values.sort
    middle = sorted.size / 2
    sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
  end
end
