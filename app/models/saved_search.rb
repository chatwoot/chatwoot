class SavedSearch < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: [:account_id, :user_id] }
  validates :search_type, inclusion: { in: AdvancedSearchService::SEARCH_TYPES }
  validates :query, length: { maximum: 500 }

  scope :recent, -> { order(last_used_at: :desc, created_at: :desc) }
  scope :by_type, ->(type) { where(search_type: type) }
  scope :frequently_used, -> { where('usage_count > 0').order(usage_count: :desc) }

  before_save :sanitize_filters

  def increment_usage!
    increment!(:usage_count)
    update_column(:last_used_at, Time.current)
  end

  def formatted_filters
    return {} if filters.blank?
    
    formatted = {}
    filters.each do |key, value|
      formatted[key.to_sym] = value
    end
    formatted
  end

  def search_summary
    parts = []
    parts << "\"#{query}\"" if query.present?
    
    if filters.present?
      filter_count = filters.reject { |k, v| v.blank? || (v.is_a?(Array) && v.empty?) }.count
      parts << "#{filter_count} filters" if filter_count > 0
    end
    
    parts.join(' with ').presence || 'All results'
  end

  private

  def sanitize_filters
    return if filters.blank?
    
    # Remove empty values and normalize
    self.filters = filters.reject { |k, v| 
      v.blank? || (v.is_a?(Array) && v.empty?)
    }.transform_values { |v|
      v.is_a?(Array) ? v.compact.reject(&:blank?) : v
    }
  end
end