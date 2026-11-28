# Keeps a Copilot turn's prompt inside the model's context window. Earlier turns are replayed within a share of the
# window, and inside a turn the older tool results are replaced by their handles once the next prompt would cross
# another share of it. Every saved result stays readable through read_tool_result.
class Captain::Copilot::ContextBudget
  # For a model RubyLLM does not know, such as one behind a custom endpoint.
  DEFAULT_WINDOW = 128_000
  # Earlier turns replayed whole get at most this share of the window, and never more than HISTORY_CAP tokens, since every
  # model call in the turn sends them again.
  HISTORY_SHARE = 0.2
  HISTORY_CAP = 60_000
  # Once the next prompt would pass this share of the window, older results in the prompt are replaced by their handles.
  COMPACT_SHARE = 0.5
  # Tool results larger than this, in characters, are replaced by a handle when an earlier turn is replayed or the prompt
  # is compacted. Smaller ones cost less than reading them again.
  HANDLE_MIN = 4_000
  # A conservative estimate for text the model has not counted yet. UTF-8 bytes over 3 is above the real count for English
  # and close to it for scripts that take 3 bytes a character.
  BYTES_PER_TOKEN = 3

  def self.window(chat)
    chat.model.context_window.presence || DEFAULT_WINDOW
  end

  def self.history_budget(chat)
    [(window(chat) * HISTORY_SHARE).to_i, HISTORY_CAP].min
  end

  def self.estimate(messages)
    messages.sum { |message| (message.is_a?(Hash) ? JSON.generate(message) : JSON.generate(message.to_h)).bytesize } / BYTES_PER_TOKEN
  end

  # A replayed or compacted tool message: a large result becomes its handle.
  def self.replay_content(content, tool_call)
    return content if tool_call.nil? || content.to_s.size <= HANDLE_MIN

    JSON.generate(Captain::Copilot::ToolResultView.handle(tool_call, Captain::Copilot::ToolResultView.serialize(tool_call.result).size))
  end

  def initialize(chat, thread_id:, run_id:)
    @chat = chat
    @thread_id = thread_id
    @run_id = run_id
  end

  # Called before each model call. Returns true when it compacted the prompt.
  def fit!
    next_prompt = expected_prompt_tokens
    limit = (self.class.window(@chat) * COMPACT_SHARE).to_i
    return false if next_prompt <= limit

    compacted = compact!(keep_latest: 1)
    return false if compacted.zero?

    Rails.logger.info "[Copilot] run #{@run_id} next prompt about #{next_prompt} tokens, over #{limit}; replaced #{compacted} results with handles"
    true
  end

  # The provider refused the prompt, so the estimate was too low. Sending the same prompt again would fail the same way,
  # so the turn retries once with every large result replaced by its handle. False when that was already tried or nothing
  # is left to replace.
  def compact_after_overflow!
    return false if @compacted_after_overflow

    @compacted_after_overflow = true
    replaced = compact!(keep_latest: 0)
    Rails.logger.info "[Copilot] run #{@run_id} exceeded the context window; replaced #{replaced} results with handles"
    replaced.positive?
  end

  # Replaces every large tool result in the prompt with its handle, except the newest keep_latest ones, which the model has
  # not read yet. Returns how many it replaced.
  def compact!(keep_latest:)
    indexes = @chat.messages.each_index.select { |index| large_tool_message?(@chat.messages[index]) }
    indexes = indexes[0...-keep_latest] if keep_latest.positive?
    tool_calls = CopilotToolCall.of_thread(@thread_id).where(call_id: indexes.map { |index| @chat.messages[index].tool_call_id }).index_by(&:call_id)
    indexes.count { |index| replace_with_handle(index, tool_calls[@chat.messages[index].tool_call_id]) }
  end

  private

  # The last response's exact prompt and output counts, plus an estimate for what was added after it.
  def expected_prompt_tokens
    index = @chat.messages.rindex { |message| message.role == :assistant && message.tokens.input }
    return self.class.estimate(@chat.messages) if index.nil?

    counted_tokens(@chat.messages[index]) + self.class.estimate(@chat.messages[(index + 1)..])
  end

  # The provider's count of the prompt that produced this response, cached parts included, plus the response itself.
  def counted_tokens(message)
    tokens = message.tokens
    tokens.input.to_i + tokens.cache_read.to_i + tokens.cache_write.to_i + tokens.output.to_i
  end

  def replace_with_handle(index, tool_call)
    return false unless tool_call

    message = @chat.messages[index]
    @chat.messages[index] = RubyLLM::Message.new(role: :tool, tool_call_id: message.tool_call_id,
                                                 content: self.class.replay_content(message.content, tool_call))
    true
  end

  # A handle is shorter than HANDLE_MIN, so a result already replaced is never replaced again.
  def large_tool_message?(message)
    message.role == :tool && message.content.to_s.size > HANDLE_MIN
  end
end
