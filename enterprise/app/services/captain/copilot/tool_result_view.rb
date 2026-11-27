# What the model sees of a tool result. The tool call keeps the whole result. A result over LIMIT characters reaches the
# model as an outline with its result_id, and the model reads the rest with read_tool_result. The view is worked out from
# the saved result each time, so a replayed tool call shows the model the same thing as the first call did.
class Captain::Copilot::ToolResultView
  # About 10,000 tokens of English. It keeps one result far below the size at which gpt-5.2 drops a tool output silently.
  LIMIT = 40_000
  # Characters a long text result shows from its start and from its end.
  TEXT_EDGE = 6_000
  OUTLINE_LIMIT = 8_000
  OUTLINE_STRING = 80
  # The model copies a display page into its reply, so an outline would leave it nothing to show. Pages are bounded:
  # ReviewService caps each reason and category, and MessagesView truncates each excerpt.
  WHOLE_RESULT_TOOLS = %w[display].freeze

  def self.for_model(result, tool_call)
    text = serialize(result)
    return result if text.size <= LIMIT || WHOLE_RESULT_TOOLS.include?(tool_call.name)

    Rails.logger.info "[Copilot] tool call #{tool_call.id} (#{tool_call.name}) result has #{text.size} characters; the model gets its outline"
    view = new(tool_call)
    data = parse(result)
    data.is_a?(String) ? view.text_view(data) : view.data_view(data, text.size)
  end

  # A short reference that stands in for a result the model saw earlier.
  def self.handle(tool_call, characters)
    { result_id: tool_call.id, tool: tool_call.name, characters: characters,
      note: 'This result was shown earlier and is left out here to save room. Read it with read_tool_result when you need it again.' }
  end

  def self.serialize(result)
    result.is_a?(String) ? result : JSON.generate(result)
  end

  # Tools such as MCP servers often return JSON as text. Parsed, it can be outlined and filtered like any other data.
  def self.parse(result)
    return result unless result.is_a?(String) && result.lstrip.start_with?('{', '[')

    JSON.parse(result)
  rescue JSON::ParserError
    result
  end

  def initialize(tool_call)
    @tool_call = tool_call
  end

  def data_view(data, characters)
    { result_id: @tool_call.id, characters: characters,
      note: 'The result is too large to show whole, so it is saved and only its outline is shown. The outline gives the keys, ' \
            'the length of each list and the first item of each list. Read the data with read_tool_result. Do not call the ' \
            'tool again to see more of it.',
      outline: self.class.outline(data) }
  end

  def text_view(text)
    { result_id: @tool_call.id, characters: text.size, lines: text.lines.size,
      note: "The text is too large to show whole, so it is saved and only its first and last #{TEXT_EDGE} characters are " \
            'shown. Read the rest with read_tool_result by line or by search. Do not call the tool again to see more of it.',
      start: text.first(TEXT_EDGE), end: text.last(TEXT_EDGE) }
  end

  # Keys, list lengths and the first item of each list, with long strings shortened. A deeper outline is tried first and
  # a shallower one is used when it does not fit.
  def self.outline(data)
    8.downto(1).each do |depth|
      outline = outline_node(data, depth)
      return outline if JSON.generate(outline).size <= OUTLINE_LIMIT
    end
    outline_node(data, 0)
  end

  def self.outline_node(value, depth)
    case value
    when Hash
      depth.zero? ? "object with #{value.size} keys" : value.transform_values { |child| outline_node(child, depth - 1) }
    when Array
      outline_list(value, depth)
    when String
      value.truncate(OUTLINE_STRING)
    else
      value
    end
  end

  def self.outline_list(list, depth)
    return { list_length: list.size } if depth.zero? || list.empty?

    { list_length: list.size, first_item: outline_node(list.first, depth - 1) }
  end
end
