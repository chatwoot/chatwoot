# Writes report periods, durations and the names of agents, inboxes, teams and labels the way the reports pages show
# them. Included by Captain::Copilot::ReportService, which sets the account and the since and before times.
module Captain::Copilot::ReportLabels
  private

  # A day is its date. A longer period is its first and last day within since and the last day, and partial when they cut it.
  def period_label(start, period)
    return { period: start.to_date.iso8601 } if period == 'day'

    finish = start + 1.public_send(period)
    first = [start, @since].max.to_date
    last = ([finish, @before].min - 1.second).to_date
    label = { period: "#{first.iso8601} to #{last.iso8601}" }
    first > start.to_date || last < (finish - 1.second).to_date ? label.merge(partial: true) : label
  end

  def subject_name(type, id)
    records = { 'agent' => @account.users, 'inbox' => @account.inboxes, 'team' => @account.teams, 'label' => @account.labels }[type]
    records&.find_by(id: id)&.then { |record| record.try(:name) || record.try(:title) }
  end

  def dimension_names(dimension)
    records = { 'agent' => @account.users, 'inbox' => @account.inboxes, 'team' => @account.teams }[dimension]
    records ? records.pluck(:id, :name).to_h : {}
  end

  # The two largest units, such as "2 days and 1 hour", so the answer reads like the reports pages instead of counting
  # seconds of an average. Zero is a measured time, such as a reply outside business hours; nil means nothing was measured.
  def duration(seconds)
    return if seconds.nil?

    ActiveSupport::Duration.build(seconds.to_f.round).parts.first(2).sum { |unit, count| count.public_send(unit) }.inspect
  end
end
