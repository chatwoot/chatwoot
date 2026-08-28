class Captain::Tools::Admin::ListCannedResponsesService < Captain::Tools::Admin::BaseTool
  def self.name
    'list_canned_responses'
  end

  description 'List canned responses configured for the account'
  param :search, type: :string, desc: 'Optional filter by short code or content (partial match)'

  def execute(search: nil)
    canned_responses = account.canned_responses
    if search.present?
      sanitized_search = search.delete("\0")
      canned_responses = canned_responses.where(
        'short_code ILIKE :search OR content ILIKE :search',
        search: "%#{sanitized_search}%"
      )
    end

    return 'No canned responses found' if canned_responses.none?

    canned_responses.limit(100).map { |canned_response| format_canned_response(canned_response) }.join("\n---\n")
  end
end
