class Captain::Copilot::PresentationService
  include Captain::Copilot::ConversationAccess

  PAGE_SIZE = 20
  # A review page holds a whole review batch, so an answer about the matches never rests on part of them.
  REVIEW_PAGE_SIZE = CopilotRun::REVIEW_BUDGET

  def initialize(run)
    @run = run
  end

  def table(page: 1, matched_only: false)
    raise ArgumentError, 'page must be a positive integer' unless page.is_a?(Integer) && page.positive?
    raise ArgumentError, 'matched_only must be a boolean' unless [true, false].include?(matched_only)

    @run.kind == 'collection' ? collection_table(page) : review_table(page, matched_only)
  end

  private

  # Rows come from the resource, which shows only the records the user can still see.
  def collection_table(page)
    resource = Captain::Copilot::Resources.build(@run.resource, account: @run.account, user: @run.user)
    total = @run.selected_ids.size
    rows = resource.rows(@run.selected_ids.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || [])
    { run: @run.receipt, type: 'table', page: page, total: total, has_more: page * PAGE_SIZE < total, rows: rows,
      content: collection_markdown(resource, rows, page, total) }
  end

  def collection_markdown(resource, rows, page, total)
    lines = ["Collection ##{@run.id}: #{total} #{@run.resource}.", "Filters: #{escape(@run.filters.to_json)}."]
    lines << 'The selection limit was reached. Narrow the filters to cover the rest.' if @run.context['selection_truncated']
    return (lines + ['No records on this page.']).join("\n\n") if rows.empty?

    (lines + [collection_rows_table(resource, rows), "Page #{page} of #{total} #{@run.resource}. Ask for another page to see more."]).join("\n\n")
  end

  def collection_rows_table(resource, rows)
    header = [@run.resource.singularize.capitalize, *resource.class::COLUMNS]
    markdown_table(header, rows.map { |row| ["[#{escape(row[:label])}](#{row[:url]})", *row[:values].map { |value| escape(value) }] })
  end

  def review_table(page, matched_only)
    visible = accessible_conversations(account: @run.account, user: @run.user)
    scope = visible_findings(visible, matched_only)
    findings = scope.page(page).per(REVIEW_PAGE_SIZE)
    display_ids = visible.where(id: findings.map(&:conversation_id)).pluck(:id, :display_id).to_h
    rows = findings.map { |finding| result_row(finding, display_ids.fetch(finding.conversation_id)) }
    total = findings.total_count
    { run: @run.receipt, type: 'table', page: page, total: total, has_more: page * REVIEW_PAGE_SIZE < total, rows: rows,
      content: markdown(rows, page, total) }
  end

  # Matched findings come first, so they fill the first page when a continued review holds more than one page.
  def visible_findings(visible, matched_only)
    scope = @run.findings.where(conversation_id: visible.select(:id)).where.not(status: %w[screened_in screened_out])
    scope = scope.where(matched: true) if matched_only
    scope.order(matched: :desc, conversation_id: :asc)
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

    cells = rows.map { |row| ["[##{row[:conversation_id]}](#{row[:url]})", escape(row[:category]), escape(finding_text(row))] }
    table = markdown_table(%w[Conversation Category Finding], cells)
    (lines + [table, page_note(page, rows.size, total)]).join("\n\n")
  end

  def page_note(page, count, total)
    first = ((page - 1) * REVIEW_PAGE_SIZE) + 1
    last = first + count - 1
    note = "Findings #{first} to #{last} of #{total} accessible findings, matched first."
    last < total ? "#{note} #{total - last} more are on later pages. Ask for page #{page + 1} to read them." : note
  end

  def markdown_table(header, rows)
    (["| #{header.join(' | ')} |", "|#{' --- |' * header.size}"] + rows.map { |cells| "| #{cells.join(' | ')} |" }).join("\n")
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
    lines + coverage_gaps(receipt) + ['The opening and newest messages were reviewed. Attachment contents were not reviewed.']
  end

  def coverage_gaps(receipt)
    gaps = []
    gaps << 'The selection limit was reached. Narrow the filters to cover the rest.' if receipt[:selection_truncated]
    if @run.terminal? && receipt[:remaining].positive?
      gaps << "#{receipt[:remaining]} conversations are not reviewed yet. Ask to continue the review."
    end
    gaps << "Execution stopped: #{escape(receipt[:error])}." if receipt[:error]
    gaps
  end

  def escape(value)
    ERB::Util.html_escape(value.to_s.squish).gsub(/[\\`*\[\]_|]/) { |character| "\\#{character}" }
  end
end
