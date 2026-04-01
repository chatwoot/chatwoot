# == Schema Information
#
# Table name: portals
#
#  id                    :bigint           not null, primary key
#  archived              :boolean          default(FALSE)
#  color                 :string
#  config                :jsonb
#  custom_domain         :string
#  header_text           :text
#  homepage_link         :string
#  name                  :string           not null
#  page_title            :string
#  slug                  :string           not null
#  ssl_settings          :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  channel_web_widget_id :bigint
#
# Indexes
#
#  index_portals_on_channel_web_widget_id  (channel_web_widget_id)
#  index_portals_on_custom_domain          (custom_domain) UNIQUE
#  index_portals_on_slug                   (slug) UNIQUE
#
FactoryBot.define do
  factory :portal, class: 'Portal' do
    account
    name { Faker::Book.name }
    slug { SecureRandom.hex }
  end
end
