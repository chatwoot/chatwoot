class Captain::Copilot::PresentationService
  include Captain::Copilot::ConversationAccess

  PAGE_SIZE = 20

  def initialize(run)
    @run = run
  end

  def table(page: 1, matched_only: false)
    raise ArgumentError, 'page must be a positive integer' unless page.is_a?(Integer) && page.positive?
    raise ArgumentError, 'matched_only must be a boolean' unless [true, false].include?(matched_only)

    visible = accessible_conversations(account: @run.account, user: @run.user)
    scope = visible_findings(visible, matched_only)
    findings = scope.page(page).per(PAGE_SIZE)
    display_ids = visible.where(id: findings.map(&:conversation_id)).pluck(:id, :display_id).to_h
    rows = findings.map { |finding| result_row(finding, display_ids.fetch(finding.conversation_id)) }
    total = findings.total_count
    { run: @run.receipt, type: 'table', page: page, total: total, has_more: page * PAGE_SIZE < total, rows: rows,
      content: markdown(rows, page, total) }
  end

  private

  def visible_findings(visible, matched_only)
    scope = @run.findings.where(conversation_id: visible.select(:id)).where.not(status: %w[screened_in screened_out]).order(:conversation_id)
    matched_only ? scope.where(matched: true) : scope
  end

  def result_row(finding, display_id)
    { conversation_id: display_id, url: "/app/accounts/#{@run.account_id}/conversations/#{display_id}", status: finding.status,
      matched: finding.matched, category: finding.category, reason: finding.reason, error: finding.error,
      evidence_message_ids: finding.evidence_message_ids, reviewed_message_ids: finding.reviewed_message_ids,
      history_truncated: finding.history_truncated }
  end

  def markdown(rows, page, total)
    lines = summary
    return (lines + ['No saved findings on this page.']).join("\n\n") if rows.empty?

    table = ['| Conversation | Category | Finding |', '| --- | --- | --- |']
    table += rows.map do |row|
      "| [##{row[:conversation_id]}](#{row[:url]}) | #{escape(row[:category])} | #{escape(finding_text(row))} |"
    end
    (lines + [table.join("\n"), "Page #{page}, #{total} accessible findings. Ask for another page to see more."]).join("\n\n")
  end

  # A finding's status describes the review, not the conversation, so only failed reviews are labelled.
  def finding_text(row)
    row[:status] == 'resolved' ? row[:reason] : "Not reviewed: #{row[:error] || row[:status]}"
  end

  def summary
    receipt = @run.receipt
    lines = ["Review ##{@run.id}: #{receipt[:status]}. Processed #{receipt[:processed]} of #{receipt[:selected]}: " \
             "#{receipt[:screened_out]} screened out, #{receipt[:reviewed]} reviewed, #{receipt[:matched]} matched, #{receipt[:errors]} errors.",
             "Filters: #{escape(@run.filters.to_json)}."]
    lines << "Screening question: #{escape(@run.match)}" if @run.match.present?
    lines << 'The selection limit was reached. Narrow the filters to cover the rest.' if receipt[:selection_truncated]
    lines << "Execution stopped: #{escape(receipt[:error])}." if receipt[:error]
    lines << 'Recent messages were reviewed. Attachment contents were not reviewed.'
    lines
  end

  def escape(value)
    ERB::Util.html_escape(value.to_s.squish).gsub(/[\\`*\[\]_|]/) { |character| "\\#{character}" }
  end
end
