class Captain::AssistantOverviewSummarySchema < RubyLLM::Schema
  MAX_POINTS = 3

  array :points,
        description: 'The most decision-useful observations from the report. Return fewer than three when fewer genuinely stand out.',
        max_items: MAX_POINTS do
    string min_length: 1, max_length: 300
  end
end
