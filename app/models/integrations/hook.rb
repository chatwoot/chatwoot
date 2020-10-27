# == Schema Information
#
# Table name: integrations_hooks
#
#  id           :bigint           not null, primary key
#  access_token :string
#  hook_type    :integer          default("account")
#  settings     :text
#  status       :integer          default("disabled")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  app_id       :string
#  inbox_id     :integer
#  reference_id :string
#
class Integrations::Hook < ApplicationRecord
  include Reauthorizable

  validates :account_id, presence: true
  validates :app_id, presence: true

  enum status: { disabled: 0, enabled: 1 }

  belongs_to :account
  belongs_to :inbox, optional: true
  has_secure_token :access_token

  enum hook_type: { account: 0, inbox: 1 }

  def app
    @app ||= Integrations::App.find(id: app_id)
  end

  def slack?
    app_id == 'slack'
  end

  def disable
    update(status: 'disabled')
  end
end
