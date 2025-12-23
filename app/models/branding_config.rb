# frozen_string_literal: true

# == Schema Information
#
# Table name: branding_configs
#
#  id           :bigint           not null, primary key
#  brand_name   :string           default("SynkiCRM"), not null
#  brand_website :string           default("https://synkicrm.com.br/"), not null
#  support_email :string           default("suporte@synkicrm.com.br"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class BrandingConfig < ApplicationRecord
  include Rails.application.routes.url_helpers

  has_one_attached :logo_main
  has_one_attached :logo_compact
  has_one_attached :favicon
  has_one_attached :apple_touch_icon

  validates :brand_name, presence: true
  validates :brand_website, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :support_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validate :validate_logo_main, if: -> { logo_main.attached? }
  validate :validate_logo_compact, if: -> { logo_compact.attached? }
  validate :validate_favicon, if: -> { favicon.attached? }
  validate :validate_apple_touch_icon, if: -> { apple_touch_icon.attached? }

  # Singleton pattern
  def self.instance
    first || create!
  end

  def logo_main_url
    return nil unless logo_main.attached?

    url_for(logo_main)
  end

  def logo_compact_url
    return nil unless logo_compact.attached?

    url_for(logo_compact)
  end

  def favicon_url
    return nil unless favicon.attached?

    url_for(favicon)
  end

  def apple_touch_icon_url
    return nil unless apple_touch_icon.attached?

    url_for(apple_touch_icon)
  end

  def as_json(options = {})
    super(options).merge(
      logo_main_url: logo_main_url,
      logo_compact_url: logo_compact_url,
      favicon_url: favicon_url,
      apple_touch_icon_url: apple_touch_icon_url
    )
  end

  private

  def validate_logo_main
    validate_image_attachment(logo_main, 'logo_main', max_size: 2.megabytes)
  end

  def validate_logo_compact
    validate_image_attachment(logo_compact, 'logo_compact', max_size: 2.megabytes)
  end

  def validate_favicon
    validate_image_attachment(favicon, 'favicon', max_size: 1.megabyte, allowed_types: %w[image/png image/x-icon image/svg+xml image/vnd.microsoft.icon])
  end

  def validate_apple_touch_icon
    validate_image_attachment(apple_touch_icon, 'apple_touch_icon', max_size: 1.megabyte)
  end

  def validate_image_attachment(attachment, field_name, max_size:, allowed_types: nil)
    return unless attachment.attached?

    # Check file size
    if attachment.byte_size > max_size
      errors.add(field_name, "must be less than #{max_size / 1.megabyte}MB")
    end

    # Check content type
    allowed_types ||= %w[image/png image/jpeg image/jpg image/svg+xml image/gif image/webp]
    unless allowed_types.include?(attachment.content_type)
      errors.add(field_name, "must be one of: #{allowed_types.join(', ')}")
    end
  rescue StandardError => e
    errors.add(field_name, "validation error: #{e.message}")
  end
end
