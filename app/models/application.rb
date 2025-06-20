class Application < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :status, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
end
