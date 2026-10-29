# == Schema Information
#
# Table name: copilot_runs
#
#  id                   :bigint           not null, primary key
#  attempts             :integer          default(0), not null
#  context              :jsonb            not null
#  cost_complete        :boolean          default(TRUE), not null
#  error                :string
#  lease_token          :string
#  lease_until          :datetime
#  status               :string           default("queued"), not null
#  total_cost_usd       :decimal(16, 10)  default(0.0), not null
#  transcript           :jsonb            not null
#  type                 :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  copilot_message_id   :bigint
#  copilot_thread_id    :bigint           not null
#  copilot_tool_call_id :bigint
#  source_run_id        :bigint
#  user_id              :bigint           not null
#
# Indexes
#
#  index_copilot_runs_on_account_id            (account_id)
#  index_copilot_runs_on_copilot_message_id    (copilot_message_id) UNIQUE
#  index_copilot_runs_on_copilot_thread_id     (copilot_thread_id)
#  index_copilot_runs_on_copilot_tool_call_id  (copilot_tool_call_id) UNIQUE
#  index_copilot_runs_on_source_run_id         (source_run_id)
#  index_copilot_runs_on_user_id               (user_id)
#
# The records get_data selected, saved so later tool calls can page through, narrow or review them. A collection is
# saved finished, and no job runs it.
class CopilotRun::Collection < CopilotRun
  STATUSES = %w[completed].freeze

  store_accessor :context, :resource

  validates :status, inclusion: { in: STATUSES }
  validates :resource, presence: true
  validate :as_of_present

  def selected_ids
    context.fetch('selected_ids', [])
  end

  # Every record in the collection. A collection has no matches, so it ignores only_matched, which a review uses.
  def record_ids(**)
    selected_ids
  end

  def as_of
    Time.iso8601(context.fetch('as_of'))
  end

  def filters
    context.fetch('filters', {})
  end

  def selection_truncated?
    context['selection_truncated'] == true
  end

  # newest and sample pick particular records, so rebuilding from the filters would select different ones.
  def query?
    filters['newest'].nil? && filters['sample'].nil?
  end

  # How the records were chosen, earliest step first. The screener and the reviewer read it as already true, so a
  # condition only the database can see, such as a rating or a date, never rules a conversation out.
  def selection
    own = "#{resource} with filters #{filters.to_json}"
    case source_run
    when CopilotRun::Collection then "#{source_run.selection}, then the #{own} linked to them"
    when CopilotRun::Review
      review = "the conversations a review of them matched (#{source_run.question || source_run.criteria})"
      "#{source_run.source_run.selection}, then #{review}, then #{own}"
    else own
    end
  end

  def excluded_run
    copilot_thread.saved_set(context['excluded_run_id']) if context['excluded_run_id']
  end

  # A collection is a saved selection, so it has no review counts.
  def summary
    super.merge(resource: resource, filters: filters, selected: selected_ids.size, selection_truncated: selection_truncated?)
  end

  private

  def as_of_present
    errors.add(:as_of, :blank) if context['as_of'].blank?
  end
end
