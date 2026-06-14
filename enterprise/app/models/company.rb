# == Schema Information
#
# Table name: companies
#
#  additional_attributes :jsonb
#  custom_attributes     :jsonb
#  last_activity_at      :datetime
#  id             :bigint           not null, primary key
#  contacts_count :integer
#  description    :text
#  domain         :string
#  name           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#
# Indexes
#
#  index_companies_on_account_and_domain   (account_id,domain) UNIQUE WHERE (domain IS NOT NULL)
#  index_companies_on_account_id           (account_id)
#  index_companies_on_name_and_account_id  (name,account_id)
#
class Company < ApplicationRecord
  include Avatarable

  ACTIVITY_ROLLUP_INTERVAL = 5.minutes

  validates :account_id, presence: true
  validates :name, presence: true, length: { maximum: Limits::COMPANY_NAME_LENGTH_LIMIT }
  validates :domain, allow_blank: true, format: {
    with: /\A[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+\z/,
    message: I18n.t('errors.companies.domain.invalid')
  }
  validates :domain, uniqueness: { scope: :account_id }, if: -> { domain.present? }
  validates :description, length: { maximum: Limits::COMPANY_DESCRIPTION_LENGTH_LIMIT }
  validates :custom_attributes, jsonb_attributes_length: true

  belongs_to :account
  has_many :contacts, dependent: :nullify
  before_validation :prepare_jsonb_attributes
  after_create_commit :fetch_favicon, if: -> { domain.present? }

  scope :ordered_by_name, -> { order(:name) }
  scope :search_by_name_or_domain, lambda { |query|
    where('name ILIKE :search OR domain ILIKE :search', search: "%#{query.strip}%")
  }

  scope :order_on_contacts_count, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"companies\".\"contacts_count\" #{direction} NULLS LAST")
      )
    )
  }
  scope :order_on_last_activity_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"companies\".\"last_activity_at\" #{direction} NULLS LAST")
      )
    )
  }

  def record_activity_at!(activity_at)
    return if last_activity_at.present? && last_activity_at > activity_at - ACTIVITY_ROLLUP_INTERVAL

    update!(last_activity_at: activity_at)
  end

  private

  def prepare_jsonb_attributes
    self.additional_attributes = {} unless additional_attributes.is_a?(Hash)
    self.custom_attributes = {} unless custom_attributes.is_a?(Hash)
  end

  def fetch_favicon
    Avatar::AvatarFromFaviconJob.set(wait: 5.seconds).perform_later(self)
  end
end
