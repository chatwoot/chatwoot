class Captain::Routines::RuntimeContext
  attr_reader :routine, :id, :started_at, :scheduled_for, :execution, :trace

  def initialize(routine:, id:, started_at:, scheduled_for: nil, on_step: nil)
    @routine = routine
    @id = id
    @started_at = started_at
    @scheduled_for = scheduled_for
    @on_step = on_step
    @frames = [{}]
    @trace = []
    @execution = Captain::Routines::ExecutionContext.build(
      id: id,
      started_at: started_at,
      scheduled_for: scheduled_for,
      timezone: routine.timezone
    )
  end

  delegate :account, to: :routine

  def bind(name, value)
    @frames.last[name.to_s] = value
  end

  def bindings
    @frames.reduce({}) { |result, frame| result.merge(frame) }
  end

  def root_bindings
    @frames.first.deep_dup
  end

  def with_frame(bindings = {})
    @frames << bindings.stringify_keys
    yield
  ensure
    @frames.pop
  end

  def resolve(reference)
    root, *path = reference.to_s.split('.')
    value = lookup(root)

    path.reduce(value) do |current, segment|
      resolve_segment(current, segment, reference)
    end
  end

  def resolve_value(value)
    case value
    when Hash
      return resolve(value['ref']) if value.keys == ['ref']

      value.transform_values { |nested| resolve_value(nested) }
    when Array
      value.map { |nested| resolve_value(nested) }
    else
      value
    end
  end

  def record(event)
    trace << event
    @on_step&.call(event)
  end

  private

  def lookup(name)
    return execution if name == 'execution'
    return routine.dsl.fetch('resources', {}) if name == 'resources'

    frame = @frames.reverse.find { |candidate| candidate.key?(name) }
    raise Captain::Routines::MissingReferenceError, "Reference '#{name}' is not bound" unless frame

    frame.fetch(name)
  end

  def resolve_segment(value, segment, reference)
    if value.is_a?(Hash)
      return value[segment] if value.key?(segment)
      return value[segment.to_sym] if value.key?(segment.to_sym)
    elsif value.is_a?(Array) && segment.match?(/\A\d+\z/)
      return value.fetch(segment.to_i)
    end

    raise Captain::Routines::MissingReferenceError, "Reference '#{reference}' does not contain '#{segment}'"
  end
end
