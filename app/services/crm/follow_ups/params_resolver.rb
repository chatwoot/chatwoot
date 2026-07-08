class Crm::FollowUps::ParamsResolver
  def initialize(account:, user:, card:, conversation:, attributes:)
    @account = account
    @user = user
    @card = card
    @conversation = conversation
    @attributes = attributes
  end

  def perform
    {
      conversation: @conversation,
      contact_id: resolved_contact_id,
      inbox_id: resolved_inbox_id,
      assignee_id: resolved_assignee_id,
      title: @attributes[:title],
      description: @attributes[:description],
      follow_up_type: @attributes[:follow_up_type].presence || 'task',
      automation_mode: @attributes[:automation_mode].presence || 'reminder_only',
      due_at: @attributes[:due_at],
      timezone: resolved_timezone,
      metadata: sanitized_metadata
    }
  end

  private

  def resolved_contact_id
    @card.contact_id || @conversation&.contact_id
  end

  def resolved_inbox_id
    @card.inbox_id || @conversation&.inbox_id
  end

  def resolved_assignee_id
    @card.owner_id || @conversation&.assignee_id || @user.id
  end

  def resolved_timezone
    Crm::Timezone::Resolver.new(
      explicit: @attributes[:timezone],
      contact: contact,
      account: @account
    ).name!
  end

  def contact
    @contact ||= @card.try(:contact) || @conversation&.contact
  end

  def sanitized_metadata
    Crm::FollowUps::MetadataSanitizer.new(
      metadata: @attributes[:metadata],
      automation_mode: @attributes[:automation_mode].presence || 'reminder_only'
    ).perform
  end
end
