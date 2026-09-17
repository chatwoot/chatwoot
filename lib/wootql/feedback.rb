module Wootql::Feedback
  MAX_FIELDS = 20
  MAX_TEXT = 240

  def self.location(source, position)
    prefix = source.byteslice(0, position)
    line = prefix.count("\n") + 1
    column = (prefix.split("\n", -1).last || '').length + 1
    excerpt = source.byteslice(position, MAX_TEXT).to_s.scrub('')
    "WootQL line #{line}, column #{column}, byte #{position}. Source starting here: #{excerpt.inspect}"
  end

  def self.stage_context(operation)
    contract = Wootql::Contracts::STAGES[operation]
    contract ? ["#{contract[:signature]}. #{contract[:description]}"] : []
  end

  def self.fields(fields)
    shown = fields.first(MAX_FIELDS).map { |name, definition| "#{name}: #{definition.type}" }
    "Fields available at this pipeline stage (#{fields.size} total, first #{MAX_FIELDS} shown): #{shown.join(', ')}"
  end
end
