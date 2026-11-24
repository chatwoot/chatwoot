# Returns the full text of the account's canned responses the model picks by name from the index in its prompt.
# The model chooses by meaning; this tool only looks names up within the account, so the trace shows which were read.
class Captain::Tools::GetCannedResponsesService < RubyLLM::Tool
  prepend Captain::Tools::Instrumentation

  MAX_CALLS = 3
  MAX_NAMES = 3
  NAMES_LENGTH = (1..300)
  INDEX_ENTRY_LIMIT = 150
  INDEX_PREVIEW_LENGTH = 80

  description 'Read the full text of saved replies, by their names from the saved reply list'
  parameter :names, description: 'Names of the saved replies to read, separated by commas', required: true

  # One line per canned response, its name and the start of its text, for the prompt.
  def self.index_for(account)
    canned_responses = account.canned_responses.order(updated_at: :desc).limit(INDEX_ENTRY_LIMIT + 1).to_a
    if canned_responses.size > INDEX_ENTRY_LIMIT
      Rails.logger.info("[CAPTAIN][GetCannedResponses] account=#{account.id} more than #{INDEX_ENTRY_LIMIT} canned responses, newest listed")
    end
    canned_responses.first(INDEX_ENTRY_LIMIT).map { |canned_response| index_line(canned_response) }.join("\n").presence
  end

  def self.index_line(canned_response)
    preview = canned_response.content.to_s.squish.truncate(INDEX_PREVIEW_LENGTH)
    "- #{canned_response.short_code}: #{preview}"
  end

  def initialize(account:)
    @account = account
    @calls = 0
    super()
  end

  def name
    'get_canned_responses'
  end

  def execute(names: nil, **)
    return 'Give one to three saved reply names, separated by commas.' unless names.is_a?(String) && NAMES_LENGTH.cover?(names.strip.length)
    return 'The limit for reading saved replies in this draft has been reached.' if @calls >= MAX_CALLS

    @calls += 1
    requested = names.split(',').map { |name| name.strip.delete_prefix('/').downcase }.compact_blank.uniq.first(MAX_NAMES)
    found = @account.canned_responses.where(CannedResponse.arel_table[:short_code].lower.in(requested)).to_a
    log_call(requested.size, found.size)
    format_result(requested, found)
  end

  private

  def format_result(requested, found)
    by_name = found.index_by { |canned_response| canned_response.short_code.downcase }
    requested.map do |name|
      canned_response = by_name[name]
      canned_response ? "\nSaved reply #{name}:\n#{canned_response.content}\n" : "\nNo saved reply named #{name}.\n"
    end.join
  end

  def log_call(requested_count, found_count)
    Rails.logger.info("[CAPTAIN][GetCannedResponses] account=#{@account.id} call=#{@calls} requested=#{requested_count} found=#{found_count}")
  end
end
