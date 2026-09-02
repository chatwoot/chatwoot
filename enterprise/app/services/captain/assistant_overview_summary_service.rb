class Captain::AssistantOverviewSummaryService < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::AssistantOverviewSummarySchema

  pattr_initialize [:account!, :assistant!, { range: Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset: nil }]

  def perform
    return { points: [] } unless report_has_activity?

    response = make_api_call(feature: 'editor', messages: messages, schema: RESPONSE_SCHEMA)
    return response if response[:error]

    { points: extract_points(response[:message]) }
  end

  private

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: 'Identify the standout points in this report.' }
    ]
  end

  def system_prompt
    Captain::PromptRenderer.render(
      'assistant_overview_summary',
      assistant_name: assistant.name,
      language: account.locale_english_name,
      report_data: JSON.pretty_generate(report_data)
    )
  end

  def report_data
    @report_data ||= {
      period: stats_window.period,
      overview: Captain::AssistantOverviewStatsBuilder.new(assistant, range, timezone_offset).metrics,
      resolution_flow: Captain::AssistantResolutionFlowBuilder.new(assistant, range, timezone_offset).build,
      resolution_trend: Captain::AssistantResolutionTrendStatsBuilder.new(assistant, range, timezone_offset).metrics
    }
  end

  def stats_window
    @stats_window ||= Captain::AssistantStatsWindow.new(range, timezone_offset)
  end

  def report_has_activity?
    report_data[:overview][:conversations_handled].values_at(:current, :previous).any?(&:positive?)
  end

  def extract_points(message)
    data = message.is_a?(Hash) ? message.deep_symbolize_keys : {}
    Array(data[:points]).filter_map { |point| point.to_s.strip.presence }.first(RESPONSE_SCHEMA::MAX_POINTS)
  end

  def event_name
    'captain_assistant_overview_summary'
  end

  def use_account_openai_hook?
    true
  end

  def counts_toward_usage?
    false
  end

  def build_follow_up_context?
    false
  end
end
