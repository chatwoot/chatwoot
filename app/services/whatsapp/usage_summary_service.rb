# Summarizes an account's WhatsApp conversation-window credit usage: the
# configured limit, lifetime consumption, remaining balance (can go negative
# once the account is over its limit), spend over common time ranges, and a
# per-inbox breakdown for reporting.
class Whatsapp::UsageSummaryService
  pattr_initialize [:account!]

  def summary
    {
      limit: limit,
      used: used,
      remaining: limit - used,
      spent_today: usages.where(created_at: Time.current.beginning_of_day..).count,
      spent_this_week: usages.where(created_at: Time.current.beginning_of_week..).count,
      spent_this_month: usages.where(created_at: Time.current.beginning_of_month..).count,
      by_inbox: usage_by_inbox
    }
  end

  private

  def limit
    account.limits['whatsapp_conversations'].to_i
  end

  def used
    usages.count
  end

  def usages
    account.whatsapp_conversation_usages
  end

  def usage_by_inbox
    usages.group(:inbox_id).count.map do |inbox_id, count|
      { inbox_id: inbox_id, inbox_name: inbox_name_for(inbox_id), count: count }
    end
  end

  def inbox_name_for(inbox_id)
    inboxes_by_id[inbox_id]&.name
  end

  def inboxes_by_id
    @inboxes_by_id ||= account.inboxes.where(id: usages.distinct.pluck(:inbox_id)).index_by(&:id)
  end
end
