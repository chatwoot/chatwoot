# Bar charts Copilot can show under its answer, only when the agent asks for one. A tool returns a marker naming its own
# tool call, with the chart data in the same saved result. The answer includes the marker, and the turn attaches the data
# from the saved result, so the numbers never pass through the model.
module Captain::Copilot::Chart
  MARKER = /\[copilot-chart:(\d+)\]/
  DATE_AT_END = /\d{4}-\d{2}-\d{2}\z/

  # Each chart is a hash of title, label and points, a point being a category and a value. The agent asked for the chart,
  # so a single bar is drawn. A chart with no value above zero is left out, and without any chart the result says why, so
  # the model explains instead of writing out the data.
  def self.for(tool_call, charts)
    data = charts.filter_map { |chart| data_for(**chart) }
    return { chart: "[copilot-chart:#{tool_call.id}]", chart_data: data } if data.any?

    { chart_note: 'No chart was drawn, because no value in the range is above zero.' }
  end

  def self.data_for(title:, label:, points:)
    return if points.none? { |_, value| value.to_f.positive? }

    title, categories = labels(title, points.map(&:first))
    { title: title, categories: categories, series: [{ id: 'value', label: label, data: points.map(&:last) }] }
  end

  # The answer with the chart data its markers name, from the thread's saved tool results, so the numbers the panel draws
  # are the ones the tools computed.
  def self.attach(response, thread_id)
    ids = response['content'].scan(MARKER).flatten
    return response if ids.empty?

    charts = CopilotToolCall.joins(:copilot_run).where(id: ids, copilot_runs: { copilot_thread_id: thread_id })
                            .to_h { |call| [call.id.to_s, call.result&.dig('chart_data')] }.compact
    charts.any? ? response.merge('charts' => charts) : response
  end

  # The panel cuts each label to its bar's width, so dates within one month read as the day of the month, with the month
  # in the title.
  def self.labels(title, categories)
    dates = categories.map { |category| category.to_s[DATE_AT_END] }
    dates.all? ? date_labels(title, dates.map { |date| Date.iso8601(date) }) : [title, categories.map(&:to_s)]
  end

  def self.date_labels(title, dates)
    months = dates.map { |date| date.strftime('%b %Y') }.uniq
    return [title, dates.map { |date| date.strftime('%-d %b') }] unless months.one?

    [title.include?(months.first) ? title : "#{title}, #{months.first}", dates.map { |date| date.strftime('%-d') }]
  end
end
