class Digitaltolk::Tasks::FixClosedActivity
  def perform
    Conversation.where(closed: true).where('last_activity_at > ?', DateTime.parse('March 14, 2025')).each do |conversation|
      msgs = conversation.messages.activity.where('content LIKE ?', '%Conversation was closed by%')
      msgs.where.not(id: msgs.pluck(:id).last).destroy_all
    end
  end
end