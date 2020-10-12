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

  has_many :account_inbox_templates, dependent: :destroy
  has_many :inboxes, through: :account_inbox_templates

  def template
    @template ||= Workflow::Template.find(id: template_id)
  end

  def add_inbox(inbox_id)
    account_inbox_template = account_inbox_templates.new(inbox_id: inbox_id)
    account_inbox_template.save!
  end

  def remove_inbox(inbox_id)
    account_inbox_template = account_inbox_templates.find_by(inbox_id: inbox_id)
    account_inbox_template.try(:destroy)
  end
end
