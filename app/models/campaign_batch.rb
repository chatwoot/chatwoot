# == Schema Information
#
# Table name: campaign_batches
#
#  id           :bigint           not null, primary key
#  contact_ids  :jsonb            not null
#  processed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  campaign_id  :bigint           not null
#
# Indexes
#
#  index_campaign_batches_on_campaign_id  (campaign_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#
class CampaignBatch < ApplicationRecord
  belongs_to :campaign

  validates :contact_ids, presence: true
end
