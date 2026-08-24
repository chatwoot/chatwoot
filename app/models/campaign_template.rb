# == Schema Information
#
# Table name: campaign_templates
#
#  id         :bigint           not null, primary key
#  body       :text             not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_campaign_templates_on_account_id           (account_id)
#  index_campaign_templates_on_account_id_and_name  (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class CampaignTemplate < ApplicationRecord
  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :body, presence: true
end
