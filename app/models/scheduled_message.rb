# == Schema Information
#
# Table name: scheduled_messages
#
#  id                             :bigint           not null, primary key
#  author_type                    :string
#  content                        :text
#  scheduled_at                   :datetime
#  status                         :integer          default("draft"), not null
#  template_params                :jsonb
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :bigint           not null
#  author_id                      :bigint
#  conversation_id                :bigint           not null
#  inbox_id                       :bigint           not null
#  message_id                     :bigint
#  recurring_scheduled_message_id :bigint
#
# Indexes
#
#  idx_on_author_type_author_id_status_6997d67ef6                (author_type,author_id,status)
#  index_scheduled_messages_on_account_id                        (account_id)
#  index_scheduled_messages_on_account_id_and_status             (account_id,status)
#  index_scheduled_messages_on_author                            (author_type,author_id)
#  index_scheduled_messages_on_conversation_id                   (conversation_id)
#  index_scheduled_messages_on_conversation_id_and_scheduled_at  (conversation_id,scheduled_at)
#  index_scheduled_messages_on_conversation_id_and_status        (conversation_id,status)
#  index_scheduled_messages_on_inbox_id                          (inbox_id)
#  index_scheduled_messages_on_inbox_id_and_status               (inbox_id,status)
#  index_scheduled_messages_on_message_id                        (message_id)
#  index_scheduled_messages_on_recurring_scheduled_message_id    (recurring_scheduled_message_id)
#  index_scheduled_messages_on_status_and_scheduled_at           (status,scheduled_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#  fk_rails_...  (message_id => messages.id)
#  fk_rails_...  (recurring_scheduled_message_id => recurring_scheduled_messages.id)
#
class ScheduledMessage < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :author, polymorphic: true, optional: true
  belongs_to :message, optional: true
  belongs_to :recurring_scheduled_message, optional: true

  has_one_attached :attachment

  enum status: { draft: 0, pending: 1, sent: 2, failed: 3 }

  before_validation :process_message_variables, if: :content_changed?

  validates :scheduled_at, presence: true, unless: -> { status == 'draft' }
  validates :content, presence: true, unless: :content_optional?
  validates :content, length: { maximum: 150_000 }
  validate :status_must_be_draft_or_pending, on: :create
  validate :must_be_editable, on: :update
  validate :scheduled_at_must_be_in_future, if: :should_validate_future_schedule?

  scope :due_for_sending, lambda {
    pending
      .where('scheduled_at <= ?', Time.current)
      .joins(:conversation)
      .merge(Conversation.where(status: [:open, :pending]))
  }

  def due_for_sending?
    scheduled_at.present? && scheduled_at <= Time.current && conversation&.status&.in?(%w[open pending])
  end

  def push_event_data
    base_event_data.tap do |data|
      data[:author] = author_event_data if author.present?
      data[:attachment] = attachment_data if attachment.attached?
      data[:recurring_scheduled_message_id] = recurring_scheduled_message_id if recurring_scheduled_message_id.present?
    end
  end

  def base_event_data
    {
      id: id, content: content, inbox_id: inbox_id,
      conversation_id: conversation.display_id, account_id: account_id,
      status: status, scheduled_at: scheduled_at&.to_i,
      template_params: template_params, author_id: author_id,
      author_type: author_type, message_id: message_id,
      created_at: created_at.to_i, updated_at: updated_at.to_i
    }
  end

  def attachment_data
    return unless attachment.attached?

    {
      id: attachment.id,
      scheduled_message_id: id,
      file_type: attachment.content_type,
      account_id: account_id,
      file_url: url_for(attachment),
      blob_id: attachment.blob.signed_id,
      filename: attachment.filename.to_s
    }
  end

  private

  def status_must_be_draft_or_pending
    return if draft? || pending?

    errors.add(:status, 'must be draft or pending when creating a scheduled message')
  end

  def must_be_editable
    return if status_was.in?(%w[sent failed]) && only_status_changed? && status.in?(%w[sent failed])

    return if status_was.in?(%w[draft pending])

    errors.add(:base, 'Scheduled message can only be modified while draft or pending')
  end

  def only_status_changed?
    changed_attributes.keys == ['status']
  end

  def scheduled_at_must_be_in_future
    return if scheduled_at.blank?
    return if scheduled_at > Time.current

    errors.add(:scheduled_at, 'must be in the future')
  end

  def should_validate_future_schedule?
    return false unless pending?

    new_record? || scheduled_at_changed? || status_changed?
  end

  def content_optional?
    template_params.present? || attachment.attached?
  end

  def author_event_data
    return author.push_event_data if author.is_a?(User)

    data = { id: author_id, type: author_type }
    data[:name] = author.name if author.respond_to?(:name)
    data
  end

  def process_message_variables
    return if content.blank?

    processed_content = modified_liquid_content(content)
    template = Liquid::Template.parse(processed_content)
    self.content = template.render(message_drops)
  rescue Liquid::Error
    # Keep original content if Liquid parsing/rendering fails
    nil
  end

  def modified_liquid_content(raw_content)
    return raw_content if raw_content.blank?

    # Wrap inline code (text between single backticks) in Liquid raw blocks
    # so that any {{ ... }} inside code is not interpreted by Liquid.
    raw_content.gsub(/`([^`\n]+)`/) do
      "{% raw %}`#{Regexp.last_match(1)}`{% endraw %}"
    end
  end

  def message_drops
    {
      'contact' => ContactDrop.new(conversation.contact),
      'conversation' => ConversationDrop.new(conversation),
      'inbox' => InboxDrop.new(inbox),
      'account' => AccountDrop.new(account)
    }
  end
end
