# == Schema Information
#
# Table name: integrations_issue_links
#
#  id              :bigint           not null, primary key
#  external_title  :string
#  external_url    :text             not null
#  metadata        :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  app_id          :string           not null
#  conversation_id :bigint           not null
#  external_id     :string           not null
#
# Indexes
#
#  index_integrations_issue_links_on_conversation_id_and_app_id  (conversation_id,app_id)
#  index_issue_links_on_account_conversation_app_external_id     (account_id,conversation_id,app_id,external_id) UNIQUE
#
class Integrations::IssueLink < ApplicationRecord
  before_validation :ensure_account_id

  belongs_to :account
  belongs_to :conversation

  validates :app_id, :external_id, :external_url, presence: true
  validates :external_id, uniqueness: { scope: [:account_id, :conversation_id, :app_id] }

  private

  def ensure_account_id
    self.account_id = conversation&.account_id
  end
end
