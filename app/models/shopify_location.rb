# == Schema Information
#
# Table name: shopify_locations
#
#  id                     :bigint           not null, primary key
#  address                :jsonb            not null
#  fulfills_online_orders :boolean          default(FALSE), not null
#  is_active              :boolean          default(TRUE), not null
#  name                   :string           not null
#  ships_inventory        :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#
# Indexes
#
#  index_shopify_locations_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class ShopifyLocation < ApplicationRecord
  belongs_to :account, optional: true
end
