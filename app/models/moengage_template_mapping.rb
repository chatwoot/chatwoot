# == Schema Information
#
# Table name: moengage_template_mappings
#
#  id                :bigint           not null, primary key
#  enabled           :boolean          default(TRUE), not null
#  event_name        :string           not null
#  parameter_map     :jsonb            not null
#  template_language :string           default("en"), not null
#  template_name     :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  hook_id           :bigint           not null
#  inbox_id          :bigint           not null
#
# Indexes
#
#  idx_moengage_template_mappings_unique           (account_id,hook_id,event_name) UNIQUE
#  index_moengage_template_mappings_on_account_id  (account_id)
#  index_moengage_template_mappings_on_hook_id     (hook_id)
#  index_moengage_template_mappings_on_inbox_id    (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (hook_id => integrations_hooks.id)
#
class MoengageTemplateMapping < ApplicationRecord
  belongs_to :account
  belongs_to :hook, class_name: 'Integrations::Hook'
  belongs_to :inbox

  validates :event_name, presence: true
  validates :template_name, presence: true
  validates :template_language, presence: true
  validates :event_name, uniqueness: { scope: %i[account_id hook_id] }

  scope :active, -> { where(enabled: true) }
  scope :for_event, ->(name) { where(event_name: name) }
end
