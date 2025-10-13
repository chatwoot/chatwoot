# == Schema Information
#
# Table name: marketing_campaigns
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  description :text             default("")
#  end_date    :datetime         not null
#  start_date  :datetime         not null
#  title       :string           default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  source_id   :string           default("")
#
# Indexes
#
#  index_marketing_campaigns_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class MarketingCampaign < ApplicationRecord
  belongs_to :account

  validates :title, presence: true
  validates :start_date, :end_date, presence: true

  validate :end_date_after_start_date

  scope :active, -> { where(active: true) }

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    return unless end_date < start_date

    errors.add(:end_date, 'must be after start date')
  end
end
