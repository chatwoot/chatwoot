# Generates the LLM welcome summary for the Captain Overview page from the
# assistant's stats hash (see Captain::AssistantStatsBuilder). Renders the
# captain_overview_summary.liquid prompt and returns markdown.
class Captain::OverviewSummaryService < Captain::BaseTaskService
  pattr_initialize [:account!, :assistant!, :first_name!, :stats!, :period!]

  def perform
    api_response = make_api_call(
      feature: 'editor',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: 'Write the summary.' }
      ]
    )

    return api_response if api_response[:error]

    { message: api_response[:message] }
  end

  private

  def system_prompt
    Liquid::Template.parse(prompt_from_file('captain_overview_summary')).render(prompt_variables)
  end

  def prompt_variables
    stat_variables.merge(period_variables)
  end

  def stat_variables
    {
      'first_name' => first_name.to_s,
      'assistant_name' => assistant.name.to_s,
      'conversations_handled' => current(:conversations_handled),
      'hours_saved' => current(:hours_saved),
      'auto_resolution_rate' => current(:auto_resolution_rate),
      'auto_resolution_trend' => trend(:auto_resolution_rate),
      'handoff_rate' => current(:handoff_rate),
      'handoff_trend' => trend(:handoff_rate),
      'reopen_rate' => current(:reopen_rate),
      'reopen_trend' => trend(:reopen_rate),
      'knowledge_coverage' => stats.dig(:knowledge, :coverage).to_s,
      'knowledge_approved' => stats.dig(:knowledge, :approved).to_s,
      'knowledge_documents' => stats.dig(:knowledge, :documents).to_s
    }
  end

  def period_variables
    {
      'today' => formatted_date(Time.zone.today),
      'period_label' => period[:label].to_s,
      'period_start' => formatted_date(period[:starts_on]),
      'period_end' => formatted_date(period[:ends_on])
    }
  end

  def formatted_date(date)
    date.strftime('%B %-d, %Y')
  end

  def current(key)
    stats.dig(key, :current).to_s
  end

  def trend(key)
    stats.dig(key, :trend).to_s
  end

  def event_name
    'captain_overview_summary'
  end

  def use_account_openai_hook?
    true
  end

  # The overview summary is an internal analytics readout, not a customer-facing
  # response, so it should not consume or be blocked by the captain_responses quota.
  def counts_toward_usage?
    false
  end
end
