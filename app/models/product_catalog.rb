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
  include Events::Types

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

  # Internal association - includes all media regardless of s3_status (for jobs/internal use)
  has_many :all_product_media, class_name: 'ProductMedium', dependent: :destroy

  # Public association - only returns media with completed S3 uploads (for API responses)
  has_many :product_media, -> { where(s3_status: 'completed') }, class_name: 'ProductMedium'

  has_many :kb_resource_product_catalogs, dependent: :destroy
  has_many :kb_resources, through: :kb_resource_product_catalogs

  validates :account_id, presence: true
  validates :industry, presence: true
  validates :productName, presence: true
  validates :type, presence: true
  validates :payment_options, presence: true
  validates :listPrice, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :validate_payment_options

  # Skip callbacks for bulk operations (handled separately in jobs/controllers)
  attr_accessor :skip_catalog_callbacks

  after_create_commit :dispatch_create_event, unless: :skip_catalog_callbacks
  after_update_commit :dispatch_update_event, unless: :skip_catalog_callbacks
  after_destroy_commit :dispatch_destroy_event, unless: :skip_catalog_callbacks
  before_destroy :cleanup_s3_folder

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

  def dispatch_product_event(target_account:, added: 0, updated: 0, deleted: 0, added_ids: [], updated_ids: [], deleted_ids: [])
    Rails.configuration.dispatcher.dispatch(
      PRODUCT_CATALOG_UPDATED,
      Time.zone.now,
      account: target_account,
      added_count: added,
      updated_count: updated,
      deleted_count: deleted,
      added_product_ids: added_ids,
      updated_product_ids: updated_ids,
      deleted_product_ids: deleted_ids
    )
  end

  def dispatch_create_event
    dispatch_product_event(target_account: account, added: 1, added_ids: [product_id])
  end

  def dispatch_update_event
    dispatch_product_event(target_account: account, updated: 1, updated_ids: [product_id])
  end

  def dispatch_destroy_event
    dispatch_product_event(target_account: account, deleted: 1, deleted_ids: [product_id])
  end

  def cleanup_s3_folder
    ProductCatalogs::S3CleanupService.new.delete_product_folder(account_id, product_id || id)
  end

end

ProductCatalog.include_mod_with('Audit::ProductCatalog')
