# == Schema Information
#
# Table name: workflow_account_inbox_templates
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_template_id :bigint           not null
#  inbox_id            :bigint           not null
#
# Indexes
#
#  account_template_with_workflow_account_template_inbox  (account_template_id)
#  inbox_with_workflow_account_template_inbox             (inbox_id)
#
class Workflow::AccountInboxTemplate < ApplicationRecord
  validates :account_template, presence: true
  validates :inbox, presence: true

  belongs_to :inbox
  belongs_to :account_template
end
