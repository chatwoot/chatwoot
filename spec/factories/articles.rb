# == Schema Information
#
# Table name: articles
#
#  id                    :bigint           not null, primary key
#  content               :text
#  description           :text
#  locale                :string           default("en"), not null
#  meta                  :jsonb
#  position              :integer
#  slug                  :string           not null
#  status                :integer
#  title                 :string
#  views                 :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  associated_article_id :bigint
#  author_id             :bigint
#  category_id           :integer
#  folder_id             :integer
#  portal_id             :integer          not null
#
# Indexes
#
#  index_articles_on_account_id             (account_id)
#  index_articles_on_associated_article_id  (associated_article_id)
#  index_articles_on_author_id              (author_id)
#  index_articles_on_portal_id              (portal_id)
#  index_articles_on_slug                   (slug) UNIQUE
#  index_articles_on_status                 (status)
#  index_articles_on_views                  (views)
#
FactoryBot.define do
  factory :article, class: 'Article' do
    account
    category { nil }
    portal
    locale { 'en' }
    association :author, factory: :user
    title { "#{Faker::Movie.title} #{SecureRandom.hex}" }
    content { 'MyText' }
    description { 'MyDescrption' }
    status { :published }
    views { 0 }
  end
end
