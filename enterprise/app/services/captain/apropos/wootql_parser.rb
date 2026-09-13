# Syntax only. Resource names, field types, and permissions are resolved later.
class Captain::Apropos::WootqlParser
  MAX_BYTES = Captain::Apropos::WootqlLexer::MAX_BYTES
  MAX_STAGES = 32
  MAX_DEPTH = 16
  Query = Struct.new(:resource, :stages, keyword_init: true)
  LITERALS = { 'true' => true, 'false' => false, 'null' => nil }.freeze

  def initialize(source)
    @tokens = Captain::Apropos::WootqlLexer.new(source).tokens
    @position = 0
    @conditions = 0
  end

  def parse
    resource = identifier
    stages = []
    while accept('|')
      raise Captain::Apropos::Error, 'WootQL exceeds 32 stages' if stages.size >= MAX_STAGES

      stages << stage
    end
    expect(:end)
    Query.new(resource: resource, stages: stages)
  end

  private

  def stage
    operation = identifier
    arguments = case operation
                when 'where' then expression(0)
                when 'project' then separated { projection }
                when 'join' then join
                when 'summarize' then summary
                when 'sort' then separated { sort_field }
                when 'take' then value
                else raise Captain::Apropos::Error, "Unknown WootQL stage: #{operation}"
                end
    { operation: operation, arguments: arguments }
  end

  def projection
    name = field
    { field: name, name: keyword('as') ? identifier : name }
  end

  def join
    kind = keyword('left') ? 'left' : 'inner'
    resource = identifier
    expect_keyword('as')
    prefix = identifier
    expect_keyword('on')
    left = field
    expect('=')
    { resource: resource, prefix: prefix, kind: kind, left: left, right: field }
  end

  def summary
    aggregates = separated do
      function = identifier
      expect('(')
      target = peek.kind == ')' ? nil : field
      expect(')')
      name = keyword('as') ? identifier : [function, target&.tr('.', '_')].compact.join('_')
      { function: function, field: target, name: name }
    end
    { aggregates: aggregates, keys: keyword('by') ? separated { field } : [] }
  end

  def sort_field
    name = field
    direction = if keyword('desc')
                  'desc'
                else
                  keyword('asc')
                  'asc'
                end
    { field: name, direction: direction }
  end

  def expression(depth)
    raise Captain::Apropos::Error, 'WootQL predicate nesting exceeds 16 levels' if depth > MAX_DEPTH

    left = conjunction(depth)
    left = { operator: 'or', left: left, right: conjunction(depth) } while keyword('or')
    left
  end

  def conjunction(depth)
    left = condition(depth)
    left = { operator: 'and', left: left, right: condition(depth) } while keyword('and')
    left
  end

  def condition(depth)
    raise Captain::Apropos::Error, 'WootQL predicate nesting exceeds 16 levels' if depth > MAX_DEPTH
    return { operator: 'not', expression: condition(depth + 1) } if keyword('not')

    if accept('(')
      nested = expression(depth + 1)
      expect(')')
      return nested
    end

    comparison
  end

  def comparison
    @conditions += 1
    raise Captain::Apropos::Error, 'WootQL exceeds 64 predicate terms' if @conditions > 64

    name = field
    if keyword('is')
      negate = keyword('not')
      test = keyword('empty') ? 'empty' : expect_keyword('null').value
      return { operator: "is_#{negate ? 'not_' : ''}#{test}", field: name }
    end
    if keyword('in')
      expect('(')
      values = separated { value }
      expect(')')
      return { operator: 'in', field: name, value: values }
    end
    operator = keyword('contains') ? 'contains' : expect_comparison
    { operator: operator, field: name, value: value }
  end

  def value
    case peek.kind
    when :number, :string then { literal: take.value }
    when :parameter then { parameter: take.value }
    when '-'
      take
      { literal: -expect(:number).value }
    else named_value
    end
  end

  def named_value
    return { literal: LITERALS.fetch(take.value) } if LITERALS.key?(peek.value)

    if keyword('now')
      expect('(')
      expect(')')
      return { now: true } unless accept('-')

      return { ago: expect(:duration).value }
    end
    raise Captain::Apropos::Error, "Expected a literal, $parameter, or now() at byte #{peek.position}"
  end

  def separated
    values = [yield]
    values << yield while accept(',')
    values
  end

  def field
    parts = [identifier]
    parts << identifier while accept('.')
    raise Captain::Apropos::Error, 'WootQL field path exceeds 16 segments' if parts.size > MAX_DEPTH

    parts.join('.')
  end

  def identifier = expect(:identifier).value
  def peek = @tokens.fetch(@position)

  def take
    token = peek
    @position += 1
    token
  end

  def accept(kind)
    take if peek.kind == kind
  end

  def keyword(word)
    take if peek.kind == :identifier && peek.value == word
  end

  def expect(kind)
    accept(kind) || raise(Captain::Apropos::Error, "Expected #{kind} at WootQL byte #{peek.position}")
  end

  def expect_keyword(word)
    keyword(word) || raise(Captain::Apropos::Error, "Expected #{word} at WootQL byte #{peek.position}")
  end

  def expect_comparison
    return take.value if %w[= != > >= < <=].include?(peek.kind)

    raise Captain::Apropos::Error, "Expected comparison at WootQL byte #{peek.position}"
  end
end
