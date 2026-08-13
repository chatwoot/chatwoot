class Captain::Routines::ExecutionContext
  CONTRACT = {
    implicit_for: %w[decide compose],
    immutable: true,
    fields: {
      id: 'unique routine execution ID',
      started_at: 'frozen ISO 8601 timestamp captured when the execution starts',
      scheduled_for: 'ISO 8601 scheduled timestamp when the run was scheduled, otherwise null',
      timezone: 'Routine timezone',
      local_time: 'started_at represented in the Routine timezone',
      local_date: 'calendar date in the Routine timezone',
      weekday: 'weekday in the Routine timezone'
    }
  }.freeze

  class << self
    def build(id:, started_at:, timezone:, scheduled_for: nil)
      local_time = started_at.in_time_zone(timezone)

      {
        'id' => id,
        'started_at' => started_at.iso8601,
        'scheduled_for' => scheduled_for&.iso8601,
        'timezone' => timezone,
        'local_time' => local_time.iso8601,
        'local_date' => local_time.to_date.iso8601,
        'weekday' => local_time.strftime('%A')
      }.freeze
    end

    def prompt
      JSON.pretty_generate(CONTRACT)
    end
  end
end
