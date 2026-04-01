# == Schema Information
#
# Table name: categories
#
#  id                     :bigint           not null, primary key
#  description            :text
#  icon                   :string           default("")
#  locale                 :string           default("en")
#  name                   :string
#  position               :integer
#  slug                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  associated_category_id :bigint
#  parent_category_id     :bigint
#  portal_id              :integer          not null
#
# Indexes
#
#  index_categories_on_associated_category_id         (associated_category_id)
#  index_categories_on_locale                         (locale)
#  index_categories_on_locale_and_account_id          (locale,account_id)
#  index_categories_on_parent_category_id             (parent_category_id)
#  index_categories_on_slug_and_locale_and_portal_id  (slug,locale,portal_id) UNIQUE
#
FactoryBot.define do
  factory :category, class: 'Category' do
    portal
    name { 'MyString' }
    description { 'MyText' }
    position { 1 }
    slug { name.parameterize }

    after(:build) do |category|
      category.account ||= category.portal.account
    end
  end
end
