# == Schema Information
#
# Table name: product_catalogs
#
#  id                         :bigint           not null, primary key
#  description                :text
#  industry                   :string           not null
#  is_visible                 :boolean          default(TRUE), not null
#  link                       :text
#  listPrice                  :decimal(10, 2)
#  payment_options            :string
#  pdfLinks                   :text
#  photoLinks                 :text
#  productName                :string           not null
#  subcategory                :string
#  type                       :string           not null
#  videoLinks                 :text
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :bigint           not null
#  bulk_processing_request_id :bigint
#  last_updated_by_id         :bigint
#  product_id                 :string
#  user_id                    :bigint
#
# Indexes
#
#  index_product_catalogs_on_account_id                  (account_id)
#  index_product_catalogs_on_account_id_and_product_id   (account_id,product_id) UNIQUE
#  index_product_catalogs_on_bulk_processing_request_id  (bulk_processing_request_id)
#  index_product_catalogs_on_created_at                  (created_at)
#  index_product_catalogs_on_last_updated_by_id          (last_updated_by_id)
#  index_product_catalogs_on_user_id                     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (bulk_processing_request_id => bulk_processing_requests.id)
#  fk_rails_...  (last_updated_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class ProductCatalog < ApplicationRecord
  include PgSearch::Model

  # Disable Single Table Inheritance (STI) to allow 'type' column for product type
  self.inheritance_column = :_type_disabled

  # Configure pg_search for efficient full-text search
  pg_search_scope :search_by_text,
                  against: {
                    productName: 'A',      # Highest priority
                    product_id: 'A',
                    type: 'B',             # Medium priority
                    industry: 'B',
                    subcategory: 'C',      # Lower priority
                    description: 'D'
                  },
                  using: {
                    tsearch: {
                      prefix: true,        # Allow partial matching
                      any_word: true,      # Match any word in query
                      dictionary: 'english'
                    }
                  }

  belongs_to :account
  belongs_to :bulk_processing_request, optional: true
  belongs_to :user, optional: true
  belongs_to :last_updated_by, class_name: 'User', optional: true
  has_many :product_media, dependent: :destroy

  validates :account_id, presence: true
  validates :industry, presence: true
  validates :productName, presence: true
  validates :type, presence: true
  validates :payment_options, presence: true
  validates :listPrice, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :validate_payment_options

  scope :by_industry, ->(industry) { where(industry: industry) }
  scope :by_type, ->(type) { where(type: type) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }

  # Helper methods to work with semicolon-separated URLs
  def external_links
    link&.split(';')&.map(&:strip)&.reject(&:blank?) || []
  end

  def pdf_urls
    pdfLinks&.split(';')&.map(&:strip)&.reject(&:blank?) || []
  end

  def photo_urls
    photoLinks&.split(';')&.map(&:strip)&.reject(&:blank?) || []
  end

  def video_urls
    videoLinks&.split(';')&.map(&:strip)&.reject(&:blank?) || []
  end

  def payment_methods
    payment_options&.split(';')&.map(&:strip)&.reject(&:blank?) || []
  end

  private

  def validate_payment_options
    return if payment_options.blank?

    valid_options = %w[FINANCING CREDIT CASH]
    options_array = payment_options.split(';').map(&:strip)

    invalid_options = options_array - valid_options
    return if invalid_options.empty?

    errors.add(:payment_options, "contains invalid options: #{invalid_options.join(', ')}")
  end
end

ProductCatalog.include_mod_with('Audit::ProductCatalog')
