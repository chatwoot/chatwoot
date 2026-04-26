# == Schema Information
#
# Table name: synapseos_agentic_deployment_logs
#
#  id             :bigint           not null, primary key
#  action         :string           not null
#  error_message  :text
#  payload        :jsonb
#  result_summary :jsonb
#  slug           :string           not null
#  status         :string           not null
#  account_id     :integer
#  super_admin_id :integer
#  created_at     :datetime         not null
#
# Indexes
#
#  index_synapseos_agentic_deployment_logs_on_account_id  (account_id)
#  index_synapseos_agentic_deployment_logs_on_action      (action)
#  index_synapseos_agentic_deployment_logs_on_slug        (slug)
#
class SynapseosAgenticDeploymentLog < ApplicationRecord
  self.table_name = 'synapseos_agentic_deployment_logs'

  ACTIONS = %w[create update delete deploy undeploy build restore_snapshot sync_whatsapp_credential].freeze
  STATUSES = %w[success failure].freeze

  validates :slug, presence: true
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :by_slug, ->(slug) { where(slug: slug) }
  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: 'failure') }
end
