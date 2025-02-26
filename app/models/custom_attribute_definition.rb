# == Schema Information
#
# Table name: custom_attribute_definitions
#
#  id                     :bigint           not null, primary key
#  attribute_description  :text
#  attribute_display_name :string
#  attribute_display_type :integer          default("text")
#  attribute_key          :string
#  attribute_model        :integer          default("conversation_attribute")
#  attribute_values       :jsonb
#  default_value          :integer
#  regex_cue              :string
#  regex_pattern          :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#
# Indexes
#
#  attribute_key_model_index                         (attribute_key,attribute_model,account_id) UNIQUE
#  index_custom_attribute_definitions_on_account_id  (account_id)
#
class CustomAttributeDefinition < ApplicationRecord
  STANDARD_ATTRIBUTES = {
    :conversation => %w[status priority assignee_id inbox_id team_id display_id campaign_id labels browser_language country_code referer created_at
                        last_activity_at],
    :contact => %w[name email phone_number identifier country_code city created_at last_activity_at referer blocked]
  }.freeze

  scope :with_attribute_model, ->(attribute_model) { attribute_model.presence && where(attribute_model: attribute_model) }
  validates :attribute_display_name, presence: true

  validates :attribute_key,
            presence: true,
            uniqueness: { scope: [:account_id, :attribute_model] }

  validates :attribute_display_type, presence: true
  validates :attribute_model, presence: true
  validate :attribute_must_not_conflict, on: :create

  enum attribute_model: { conversation_attribute: 0, contact_attribute: 1 }
  enum attribute_display_type: { text: 0, number: 1, currency: 2, percent: 3, link: 4, date: 5, list: 6, checkbox: 7 }

  belongs_to :account
  after_update :update_widget_pre_chat_custom_fields
  after_destroy :sync_widget_pre_chat_custom_fields

  private

  def sync_widget_pre_chat_custom_fields
    ::Inboxes::SyncWidgetPreChatCustomFieldsJob.perform_later(account, attribute_key)
  end

  def update_widget_pre_chat_custom_fields
    ::Inboxes::UpdateWidgetPreChatCustomFieldsJob.perform_later(account, self)
  end

  def attribute_must_not_conflict
    model_keys = attribute_model.to_sym == :conversation_attribute ? :conversation : :contact
    return unless attribute_key.in?(STANDARD_ATTRIBUTES[model_keys])

    errors.add(:attribute_key, I18n.t('errors.custom_attribute_definition.key_conflict'))
  end
end
