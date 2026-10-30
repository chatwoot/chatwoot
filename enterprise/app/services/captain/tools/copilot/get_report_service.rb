class Captain::Tools::Copilot::GetReportService < Captain::Tools::BaseTool
  # Set by the turn before each call, so the chart marker names this call's saved result.
  attr_accessor :tool_call

  METRICS = {
    'conversations_count' => 'conversations created in the period; for an agent, inbox or team, those currently assigned to it',
    'incoming_messages_count' => 'messages received from customers',
    'outgoing_messages_count' => 'replies and private notes sent by agents and bots; for an agent, the ones that agent sent',
    'resolutions_count' => 'conversations resolved in the period; for an agent, the ones that agent resolved',
    'avg_first_response_time' => 'average time from a conversation starting or leaving a bot to the first agent reply',
    'avg_resolution_time' => 'average time from a conversation starting to its resolution, for conversations resolved in the period',
    'reply_time' => 'average time from a customer message to the agent reply',
    'bot_resolutions_count' => 'conversations a bot resolved without a handoff',
    'bot_handoffs_count' => 'conversations a bot handed to an agent'
  }.freeze

  def self.name
    'get_report'
  end
  description 'Read the numbers the dashboard reports show, computed by the same reports. With by set to day, week, month or year, ' \
              'returns each requested metric per period for the account or for one agent, inbox, team or label, and its ' \
              'total_or_average over exactly since to before. With by set to agent, inbox, team or label, returns for each of them ' \
              'the conversations, resolved conversations and average first response, resolution and reply times. Times are in the ' \
              'account reporting time zone, and weeks run Sunday to Saturday as on the reports pages; a period cut by since or ' \
              'before is marked partial. With by set to range, returns ' \
              'each metric over exactly since to before; to compare date ranges, call once per range. ' \
              "Metrics:\n#{METRICS.map { |name, meaning| "- #{name}: #{meaning}" }.join("\n")}"
  parameters type: 'object', required: %w[by since before], additionalProperties: false,
             properties: {
               by: { type: 'string', enum: [Captain::Copilot::ReportService::RANGE] + Captain::Copilot::ReportService::PERIODS.keys +
                                           Captain::Copilot::ReportService::SUMMARY_BUILDERS.keys },
               metrics: { type: 'array', items: { type: 'string', enum: METRICS.keys }, minItems: 1, uniqueItems: true,
                          description: 'Required by range or period. Every metric the request needs, in one call' },
               since: { type: 'string', format: 'date-time' },
               before: { type: 'string', format: 'date-time' },
               agent_id: { type: 'integer', minimum: 1 },
               inbox_id: { type: 'integer', minimum: 1 },
               team_id: { type: 'integer', minimum: 1 },
               label: { type: 'string', description: 'Label name' },
               each: { type: 'string', enum: Captain::Copilot::ReportService::SUMMARY_BUILDERS.keys,
                       description: 'With a period, the metric per period for each agent, inbox, team or label with any of it, out of ' \
                                    "the #{Captain::Copilot::ReportService::MAX_CHECKED} with the most conversations" },
               business_hours: { type: 'boolean', description: 'Count times only within business hours' },
               chart: { type: 'boolean', description: 'Only when the agent asks for a graph or chart' }
             }

  # options holds business_hours, chart and the agent, inbox, team or label filter.
  def execute(by:, since:, before:, metrics: [], **options)
    options = options.stringify_keys
    Captain::Copilot::ReportService.new(account: @assistant.account, tool_call: tool_call, business_hours: options['business_hours'] == true,
                                        chart: options['chart'] == true)
                                   .call(by: by, since: since, before: before, metrics: metrics, filters: options)
  end

  # The same permission as the reports pages.
  def active?
    @user.present? && Captain::Copilot::ReportService.permitted?(account: @assistant.account, user: @user)
  end
end
