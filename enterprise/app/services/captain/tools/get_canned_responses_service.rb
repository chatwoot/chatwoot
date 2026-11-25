# Returns the full text of the account's canned responses the model picks by name from the index in its prompt.
# The model chooses by meaning; this tool only looks names up within the account, so the trace shows which were read.
class Captain::Tools::GetCannedResponsesService < RubyLLM::Tool
  prepend Captain::Tools::Instrumentation

  MAX_CALLS = 3
  MAX_NAMES = 3
  NAME_LENGTH = (1..255)
  INDEX_ENTRY_LIMIT = 150
  INDEX_PREVIEW_LENGTH = 80

  description 'Read the full text of saved replies, by their names from the saved reply list'
  # A list, not comma-separated text, because saved reply names can contain commas.
  parameters type: 'object', required: %w[names], additionalProperties: false,
             properties: {
               names: { type: 'array', items: { type: 'string' }, minItems: 1, maxItems: MAX_NAMES,
                        description: 'Names of the saved replies to read, exactly as listed' }
             }

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
    requested = requested_names(names)
    return 'Give a list of one to three saved reply names.' if requested.nil?
    return 'The limit for reading saved replies in this draft has been reached.' if @calls >= MAX_CALLS

    @calls += 1
    lookups = requested.flat_map { |name| [name, name.delete_prefix('/')] }.map(&:downcase).uniq
    found = @account.canned_responses.where(CannedResponse.arel_table[:short_code].lower.in(lookups)).to_a
    log_call(requested.size, found.size)
    requested.map { |name| format_entry(name, best_match(found, name)) }.join
  end

  private

  def requested_names(names)
    return unless names.is_a?(Array) && names.size.between?(1, MAX_NAMES) && names.all?(String)

    cleaned = names.map(&:strip).uniq
    cleaned if cleaned.all? { |name| NAME_LENGTH.cover?(name.length) }
  end

  # Names are unique only with their case, so the exact name wins over one that differs in case. The model sometimes
  # adds the "/" agents type before a saved reply, so the name without it is tried too.
  def best_match(found, name)
    candidates = [name, name.delete_prefix('/')].uniq
    candidates.each do |candidate|
      exact = found.find { |canned_response| canned_response.short_code == candidate }
      return exact if exact
    end
    found.find { |canned_response| candidates.any? { |candidate| canned_response.short_code.casecmp?(candidate) } }
  end

  def format_entry(name, canned_response)
    canned_response ? "\nSaved reply #{canned_response.short_code}:\n#{canned_response.content}\n" : "\nNo saved reply named #{name}.\n"
  end

  def log_call(requested_count, found_count)
    Rails.logger.info("[CAPTAIN][GetCannedResponses] account=#{@account.id} call=#{@calls} requested=#{requested_count} found=#{found_count}")
  end
end
