class Captain::Copilot::ResultTable
  include Captain::Copilot::ConversationAccess

  PAGE_SIZE = 20
  # Matched findings come first, so the first page holds the matches of most reviews without sending every finding to the
  # model on each follow-up question.
  REVIEW_PAGE_SIZE = 100
  CATEGORY_COUNTS = 20

  def initialize(run)
    @run = run
  end

  def page(number, matched_only: false)
    raise ArgumentError, 'page must be a positive integer' unless number.is_a?(Integer) && number.positive?
    raise ArgumentError, 'matched_only must be a boolean' unless [true, false].include?(matched_only)

    @run.is_a?(CopilotRun::Collection) ? collection_page(number) : review_page(number, matched_only)
  end

  private

  # Rows come from the resource, which shows only the records the user can still see.
  def collection_page(page)
    resource = Captain::Copilot::Resources.build(@run.resource, account: @run.account, user: @run.user)
    total = @run.selected_ids.size
    rows = resource.rows(@run.selected_ids.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || [])
    { run: @run.summary, type: 'table', page: page, total: total, has_more: page * PAGE_SIZE < total,
      content: collection_markdown(resource, rows, page, total) }
  end

  def collection_markdown(resource, rows, page, total)
    lines = ["Collection ##{@run.id}: #{total} #{@run.resource}.", "Filters: #{escape(@run.filters.to_json)}."]
    if @run.selection_truncated?
      lines << "Display and reviews cover the first #{CopilotRun::MAX_SELECTION} records. get_data from this collection still covers every record."
    end
    return (lines + ['No records on this page.']).join("\n\n") if rows.empty?

    (lines + [collection_rows_table(resource, rows), "Page #{page} of #{total} #{@run.resource}. Ask for another page to see more."]).join("\n\n")
  end

  def collection_rows_table(resource, rows)
    header = [@run.resource.singularize.capitalize, *resource.class::COLUMNS]
    markdown_table(header, rows.map { |row| [row_label(row), *row[:values].map { |value| escape(value) }] })
  end

  # Records of generated table resources have no dashboard page, so their label is plain text.
  def row_label(row)
    row[:url] ? "[#{escape(row[:label])}](#{row[:url]})" : escape(row[:label])
  end

  def review_page(page, matched_only)
    visible = accessible_conversations(account: @run.account, user: @run.user)
    findings = visible_findings(visible, matched_only).page(page).per(REVIEW_PAGE_SIZE)
    conversations = visible.where(id: findings.map(&:conversation_id)).includes(:assignee).index_by(&:id)
    total = findings.total_count
    { run: @run.summary, type: 'table', page: page, total: total, has_more: page * REVIEW_PAGE_SIZE < total,
      content: markdown(findings, conversations, page, total, matched_only) }
  end

  # Matched findings come first, then the rest in the order the review picked them, newest first. The review creates
  # findings in that order, so their IDs follow it.
  def visible_findings(visible, matched_only)
    scope = @run.findings.where(conversation_id: visible.select(:id)).where.not(status: %i[awaiting_review screened_out])
    scope = scope.where(matched: true) if matched_only
    scope.order(matched: :desc, id: :asc)
  end

  # The table is the only copy of the findings the model gets. A table of every finding says which ones matched.
  def markdown(findings, conversations, page, total, matched_only)
    lines = summary_lines
    return (lines + ['No saved findings on this page.']).join("\n\n") if findings.empty?

    header = matched_only ? %w[Conversation Assignee Category Finding] : %w[Conversation Assignee Matched Category Finding]
    cells = findings.map do |finding|
      conversation = conversations.fetch(finding.conversation_id)
      link = "[##{conversation.display_id}](/app/accounts/#{@run.account_id}/conversations/#{conversation.display_id})"
      [link, escape(conversation.assignee&.name || 'Unassigned'), (matched_cell(finding) unless matched_only), escape(finding.category),
       escape(finding_text(finding))].compact
    end
    (lines + [markdown_table(header, cells), page_note(page, findings.size, total)]).join("\n\n")
  end

  def matched_cell(finding)
    return '' unless finding.reviewed?

    finding.matched ? 'yes' : 'no'
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
  def finding_text(finding)
    finding.reviewed? ? finding.reason : "Not reviewed: #{finding.error || finding.status}"
  end

  def summary_lines
    summary = @run.summary
    lines = ["Review ##{@run.id}: #{summary[:status]}. Processed #{summary[:processed]} of #{summary[:selected]}: " \
             "#{summary[:screened_out]} screened out, #{summary[:reviewed]} reviewed, #{summary[:matched]} matched, #{summary[:failed]} failed.",
             "Filters: #{escape(@run.filters.to_json)}."]
    lines << "Screening question: #{escape(@run.question)}" if @run.question.present?
    lines + coverage_gaps(summary) + covered_dates + category_counts +
      ['The opening and newest messages were reviewed. Attachment contents were not reviewed.']
  end

  # The dates the processed conversations span, so a review that stopped partway says which part of the period it read.
  def covered_dates
    field = @run.filters['date_field'] || 'last_activity_at'
    column = Conversation.arel_table[field]
    first, last = Conversation.where(id: @run.findings.select(:conversation_id)).pick(column.minimum, column.maximum)
    first ? ["Processed conversations span #{field} #{first.to_date.iso8601} to #{last.to_date.iso8601}."] : []
  end

  # Counted by the database over every reviewed conversation, so the most common categories never depend on the model
  # tallying findings.
  def category_counts
    counts = @run.findings.reviewed.group(:category).order(Arel.star.count.desc).limit(CATEGORY_COUNTS).count
    return [] if counts.empty?

    ["Categories of reviewed conversations: #{counts.map { |category, count| "#{escape(category)} (#{count})" }.join(', ')}."]
  end

  def coverage_gaps(summary)
    gaps = []
    gaps << 'The selection limit was reached. Narrow the filters to cover the rest.' if summary[:selection_truncated]
    if @run.finished? && summary[:remaining].positive?
      gaps << "#{summary[:remaining]} conversations are not reviewed yet. Ask to continue the review."
    end
    gaps << "Execution stopped: #{escape(summary[:error])}." if summary[:error]
    gaps
  end

  def escape(value)
    ERB::Util.html_escape(value.to_s.squish).gsub(/[\\`*\[\]_|]/) { |character| "\\#{character}" }
  end
end
