# == Schema Information
#
# Table name: companies
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  contacts_count        :integer          default(0), not null
#  custom_attributes     :jsonb
#  description           :text
#  domain                :string
#  last_activity_at      :datetime
#  name                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#
# Indexes
#
#  index_companies_on_account_and_domain   (account_id,domain) UNIQUE WHERE (domain IS NOT NULL)
#  index_companies_on_account_id           (account_id)
#  index_companies_on_name_and_account_id  (name,account_id)
#
# NOTE: This model was dropped with the enterprise edition alongside its
# controller/views. It is restored here as part of the Kiraid CRM surface
# (contacts belong to a company via contacts.company_id). If you want to remove
# the Companies feature entirely, delete this file plus the companies routes,
# the Api::V1::Accounts::CompaniesController, the views under app/views/api/v1/accounts/companies,
# and feature_flag `companies` — the contacts.company_id column can stay nullable.
class Company < ApplicationRecord
  include Avatarable

  validates :account_id, presence: true
  validates :name, presence: true

  belongs_to :account
  has_many :contacts, dependent: :nullify

  scope :search, ->(query) { query.present? ? where('name ILIKE :q OR domain ILIKE :q', q: "%#{query}%") : all }

  after_create_commit :fetch_avatar_from_favicon

  def contact_ids
    contacts.pluck(:id)
  end

  private

  def fetch_avatar_from_favicon
    return if domain.blank?

    Avatar::AvatarFromFaviconJob.perform_later(self)
  end
end
