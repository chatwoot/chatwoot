# == Schema Information
#
# Table name: integrations_slacks
#
#  id            :bigint           not null, primary key
#  client_id     :string
#  client_secret :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer
#
class Integrations::Slack < ApplicationRecord
  belongs_to :account

  validates :account_id, :client_id, :client_secret, presence: true
end
