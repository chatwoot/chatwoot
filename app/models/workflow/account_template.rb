# == Schema Information
#
# Table name: workflow_account_templates
#
#  id          :bigint           not null, primary key
#  config      :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  template_id :string           not null
#
# Indexes
#
#  index_workflow_account_templates_on_account_id  (account_id)
#
class Workflow::AccountTemplate < ApplicationRecord
  validates :account_id, presence: true
  validates :template_id, presence: true

  belongs_to :account

  has_many :workflow_account_inbox_templates, dependent: :destroy

  def template
    @template ||= Workflows::Template.find(id: template_id)
  end
end
