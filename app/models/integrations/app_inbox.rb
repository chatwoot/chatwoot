# == Schema Information
#
# Table name: integrations_app_inboxes
#
#  id         :bigint           not null, primary key
#  settings   :text
#  status     :integer          default("disabled")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#  app_id     :string
#  inbox_id   :integer
#
class Integrations::AppInbox < ApplicationRecord
  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :app_id, presence: true

  enum status: { disabled: 0, enabled: 1 }

  belongs_to :account
  belongs_to :inbox

  def app
    @app ||= Integrations::AppInbox.find(id: app_id)
  end
end
