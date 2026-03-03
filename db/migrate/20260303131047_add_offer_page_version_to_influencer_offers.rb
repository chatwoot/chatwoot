class AddOfferPageVersionToInfluencerOffers < ActiveRecord::Migration[7.0]
  def change
    add_column :influencer_offers, :offer_page_version, :string
  end
end
