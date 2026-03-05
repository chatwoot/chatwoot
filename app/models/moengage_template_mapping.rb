# == Schema Information
#
# Table name: moengage_template_mappings
#
#  id                :bigint           not null, primary key
#  account_id        :bigint           not null
#  hook_id           :bigint           not null
#  inbox_id          :bigint           not null
#  event_name        :string           not null
#  template_name     :string           not null
#  template_language :string           default("en"), not null
#  parameter_map     :jsonb            not null
#  enabled           :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
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
