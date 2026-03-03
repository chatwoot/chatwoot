class AddReferralAndConsentToInfluencerOffers < ActiveRecord::Migration[7.0]
  def change
    add_column :influencer_offers, :referral_link, :string
    add_column :influencer_offers, :consent_data_processing, :boolean, default: false
    add_column :influencer_offers, :consent_terms, :boolean, default: false
  end
end
