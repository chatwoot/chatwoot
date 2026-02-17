class KbFolder < ApplicationRecord
  # Security limits
  MAX_NAME_LENGTH = 100
  MAX_PATH_LENGTH = 500
  MAX_NESTING_DEPTH = 10

  # Dangerous characters for folder names (security)
  INVALID_CHARS_REGEX = %r{[<>:"|?*\x00-\x1f\\]}.freeze
  DANGEROUS_NAMES = %w[. .. .git .svn .env node_modules __pycache__].freeze

  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true

  validates :name, presence: true,
                   length: { maximum: MAX_NAME_LENGTH, message: "cannot exceed #{MAX_NAME_LENGTH} characters" }
  validates :full_path, presence: true,
                        uniqueness: { scope: :account_id, message: 'already exists' },
                        length: { maximum: MAX_PATH_LENGTH, message: "path cannot exceed #{MAX_PATH_LENGTH} characters" }
  validates :parent_path, presence: true,
                          length: { maximum: MAX_PATH_LENGTH, message: "cannot exceed #{MAX_PATH_LENGTH} characters" }
  validate :validate_name_security
  validate :validate_nesting_depth
  validate :validate_path_security
  validate :validate_storage_limit, on: :create

  scope :in_folder, ->(path) { where(parent_path: path) }
  scope :ordered, -> { order(:name) }

  before_validation :sanitize_name
  before_validation :set_full_path, on: :create

  def self.subfolders_in(account_id, parent_path)
    where(account_id: account_id, parent_path: parent_path).ordered
  end

  private

  def sanitize_name
    return if name.blank?

    # Remove leading/trailing whitespace
    self.name = name.strip
    # Remove consecutive spaces
    self.name = name.gsub(/\s+/, ' ')
  end

  def set_full_path
    return if full_path.present?

    self.full_path = parent_path == '/' ? "/#{name}" : "#{parent_path}/#{name}"
  end

  def validate_name_security
    return if name.blank?

    # Check for invalid characters
    if name.match?(INVALID_CHARS_REGEX)
      errors.add(:name, 'contains invalid characters')
      return
    end

    # Check for path traversal attempts
    if name.include?('..') || name.include?('/')
      errors.add(:name, 'cannot contain path separators')
      return
    end

    # Check for dangerous/reserved names
    if DANGEROUS_NAMES.include?(name.downcase)
      errors.add(:name, 'is a reserved name')
      return
    end

    # Check for names starting with dot (hidden files convention)
    if name.start_with?('.')
      errors.add(:name, 'cannot start with a dot')
    end
  end

  def validate_nesting_depth
    return if parent_path.blank?

    depth = parent_path.count('/')
    return unless depth >= MAX_NESTING_DEPTH

    errors.add(:parent_path, "exceeds maximum nesting depth of #{MAX_NESTING_DEPTH} levels")
  end

  def validate_path_security
    return if parent_path.blank?

    # Check for path traversal
    if parent_path.include?('..')
      errors.add(:parent_path, 'contains invalid path traversal characters')
      return
    end

    # Ensure path starts with /
    unless parent_path.start_with?('/')
      errors.add(:parent_path, 'must start with /')
    end
  end

  def validate_storage_limit
    return if account_id.blank? || name.blank?

    current_storage = KbResource.storage_used_by_account(account_id)
    new_total = current_storage + name.bytesize

    return unless new_total > KbResource::MAX_STORAGE_PER_ACCOUNT

    errors.add(:name, "would exceed account storage limit of #{KbResource::MAX_STORAGE_PER_ACCOUNT / 1.gigabyte}GB")
  end
end

KbFolder.include_mod_with('Audit::KbFolder')
