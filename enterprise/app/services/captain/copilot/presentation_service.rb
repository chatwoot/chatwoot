class Captain::Copilot::PresentationService
  include Captain::Copilot::ConversationAccess

  PAGE_SIZE = 20

  def initialize(run)
    @run = run
  end

  def table(page: 1, attention_only: false)
    raise ArgumentError, 'page must be a positive integer' unless page.is_a?(Integer) && page.positive?
    raise ArgumentError, 'attention_only must be a boolean' unless [true, false].include?(attention_only)

    visible = accessible_conversations(account: @run.account, user: @run.user)
    scope = visible_findings(visible, attention_only)
    findings = scope.page(page).per(PAGE_SIZE)
    display_ids = visible.where(id: findings.map(&:conversation_id)).pluck(:id, :display_id).to_h
    rows = findings.map { |finding| result_row(finding, display_ids.fetch(finding.conversation_id)) }
    total = findings.total_count
    { run: @run.receipt, type: 'table', page: page, total: total, has_more: page * PAGE_SIZE < total, rows: rows,
      content: markdown(rows, page, total) }
  end

  private

  def visible_findings(visible, attention_only)
    scope = @run.findings.where(conversation_id: visible.select(:id)).order(:conversation_id)
    attention_only ? scope.where(needs_attention: true) : scope
  end

  def result_row(finding, display_id)
    { conversation_id: display_id, url: "/app/accounts/#{@run.account_id}/conversations/#{display_id}", status: finding.status,
      needs_attention: finding.needs_attention, category: finding.category, reason: finding.reason, error: finding.error,
      evidence_message_ids: finding.evidence_message_ids, reviewed_message_ids: finding.reviewed_message_ids,
      history_truncated: finding.history_truncated }
  end

  def markdown(rows, page, total)
    lines = summary
    return (lines + ['No saved findings on this page.']).join("\n\n") if rows.empty?

    table = ['| Conversation | Category | Finding |', '| --- | --- | --- |']
    table += rows.map do |row|
      "| [##{row[:conversation_id]}](#{row[:url]}) | #{escape(row[:category])} | " \
        "#{escape(row[:reason] || row[:error])} (#{row[:status]}) |"
    end
    (lines + [table.join("\n"), "Page #{page}, #{total} accessible findings. Ask for another page to see more."]).join("\n\n")
  end

  def summary
    receipt = @run.receipt
    lines = ["Review ##{@run.id}: #{receipt[:status]}. Reviewed #{receipt[:reviewed]} of #{receipt[:selected]}. " \
             "Errors: #{receipt[:errors]}.", "Filters: #{escape(@run.filters.to_json)}."]
    lines << 'The selection limit was reached. Narrow the filters to cover the rest.' if receipt[:selection_truncated]
    lines << "Execution stopped: #{escape(receipt[:error])}." if receipt[:error]
    lines << 'Recent messages were reviewed. Attachment contents were not reviewed.'
    lines
  end

  def escape(value)
    ERB::Util.html_escape(value.to_s.squish).gsub(/[\\`*\[\]_|]/) { |character| "\\#{character}" }
  end
end
