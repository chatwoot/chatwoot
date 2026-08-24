# frozen_string_literal: true

# [whisker] Client Error Report — collects widget/pet errors for debugging
# Lightweight Sentry-style reporter for self-hosted installs.
class ClientErrorReport < ApplicationRecord
  belongs_to :account, optional: true

  validates :website_token, presence: true
  validates :platform, presence: true
  validates :message, presence: true

  PLATFORMS = %w[widget dashboard pet].freeze

  before_validation :normalize_platform

  scope :recent, -> { order(created_at: :desc) }
  scope :for_token, ->(token) { where(website_token: token) }

  private

  def normalize_platform
    self.platform = platform.to_s.downcase.strip
    self.platform = 'widget' unless PLATFORMS.include?(platform)
  end
end
