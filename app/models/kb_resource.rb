class KbResource < ApplicationRecord
  include Events::Types

  MAX_FILE_SIZE = 200.megabytes
  MAX_STORAGE_PER_ACCOUNT = 2.gigabytes

  # Security limits
  MAX_NAME_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 1000
  MAX_FOLDER_PATH_LENGTH = 500

  # Dangerous patterns for path traversal and injection
  DANGEROUS_PATTERNS = [
    '..', # Path traversal
    '<script', # XSS
    'javascript:', # XSS
    "\x00", # Null byte injection
    "\r", "\n" # CRLF injection
  ].freeze

  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :kb_resource_product_catalogs, dependent: :destroy
  has_many :product_catalogs, through: :kb_resource_product_catalogs

  validates :name, presence: true,
                   length: { maximum: MAX_NAME_LENGTH, message: "cannot exceed #{MAX_NAME_LENGTH} characters" }
  validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH, message: "cannot exceed #{MAX_DESCRIPTION_LENGTH} characters" },
                          allow_blank: true
  validates :folder_path, length: { maximum: MAX_FOLDER_PATH_LENGTH, message: "cannot exceed #{MAX_FOLDER_PATH_LENGTH} characters" },
                          allow_blank: true
  validates :file_name, presence: true
  validates :s3_key, presence: true, uniqueness: true
  validate :validate_file_size, on: :create
  validate :validate_storage_limit, on: :create
  validate :validate_name_security
  validate :validate_description_security
  validate :validate_folder_path_security

  before_validation :sanitize_inputs

  scope :visible, -> { where(is_visible: true) }
  scope :ordered, -> { order(created_at: :desc) }

  # Skip callbacks for manual event dispatch (used when updating associations separately)
  attr_accessor :skip_create_callback, :skip_update_callback, :tracked_changes

  after_create_commit :dispatch_create_event, unless: :skip_create_callback
  after_update_commit :dispatch_update_event, unless: :skip_update_callback
  after_destroy_commit :dispatch_destroy_event

  def presigned_url
    KbResources::PresignedUrlService.new.generate_url(s3_key)
  end

  # Manually dispatch create event (used after updating associations)
  def dispatch_create_event!
    dispatch_create_event
  end

  # Manually dispatch update event (used after updating associations)
  def dispatch_update_event!(changed_attrs = nil)
    dispatch_update_event(changed_attrs || tracked_changes)
  end

  # Returns total storage used by account in bytes (files + folder names)
  def self.storage_used_by_account(account_id)
    files_size = where(account_id: account_id).sum(:file_size) || 0
    folders_size = KbFolder.where(account_id: account_id).sum('LENGTH(name)') || 0
    files_size + folders_size
  end

  # Returns remaining storage available for account in bytes
  def self.storage_remaining_for_account(account_id)
    MAX_STORAGE_PER_ACCOUNT - storage_used_by_account(account_id)
  end

  private

  def sanitize_inputs
    self.name = name&.strip&.gsub(/[<>]/, '')
    self.description = description&.strip
  end

  def validate_file_size
    return if file_size.blank?
    return unless file_size > MAX_FILE_SIZE

    errors.add(:file_size, "exceeds maximum allowed size of #{MAX_FILE_SIZE / 1.megabyte}MB")
  end

  def validate_storage_limit
    return if account_id.blank? || file_size.blank?

    current_storage = KbResource.storage_used_by_account(account_id)
    new_total = current_storage + file_size

    return unless new_total > MAX_STORAGE_PER_ACCOUNT

    errors.add(:file_size, "would exceed account storage limit of #{MAX_STORAGE_PER_ACCOUNT / 1.gigabyte}GB")
  end

  def validate_name_security
    return if name.blank?

    DANGEROUS_PATTERNS.each do |pattern|
      if name.downcase.include?(pattern.downcase)
        errors.add(:name, 'contains invalid characters')
        break
      end
    end
  end

  def validate_description_security
    return if description.blank?

    DANGEROUS_PATTERNS.each do |pattern|
      if description.downcase.include?(pattern.downcase)
        errors.add(:description, 'contains invalid characters')
        break
      end
    end
  end

  def validate_folder_path_security
    return if folder_path.blank?

    if folder_path.include?('..')
      errors.add(:folder_path, 'contains invalid path traversal characters')
      return
    end

    # Ensure folder path starts with /
    unless folder_path.start_with?('/')
      errors.add(:folder_path, 'must start with /')
    end
  end

  def resource_payload(changed_attributes: nil)
    payload = {
      id: id,
      name: name,
      s3_url: presigned_url
    }
    # Only include product_ids for create (no changed_attributes), for update it's in changed_attributes
    if changed_attributes.present?
      payload[:changed_attributes] = changed_attributes
    else
      payload[:product_ids] = product_catalogs.pluck(:product_id)
    end
    payload
  end

  def dispatch_resource_event(action:, resource_data:)
    Rails.configuration.dispatcher.dispatch(
      KB_RESOURCE_UPDATED,
      Time.zone.now,
      account: account,
      action: action,
      resource: resource_data
    )
  end

  def dispatch_create_event
    dispatch_resource_event(action: 'created', resource_data: resource_payload)
  end

  def dispatch_update_event(changed_attrs = nil)
    changes = changed_attrs || previous_changes.except('updated_at')
    dispatch_resource_event(action: 'updated', resource_data: resource_payload(changed_attributes: changes))
  end

  def dispatch_destroy_event
    dispatch_resource_event(action: 'deleted', resource_data: { id: id, name: name })
  end
end

KbResource.include_mod_with('Audit::KbResource')
