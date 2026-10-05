require 'administrate/base_dashboard'

class PlatformBannerDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    banner_type: Field::Select.with_options(collection: %w[info warning error feature_announcement]),
    title: Field::String,
    banner_message: Field::Text.with_options(truncate: 200),
    video_url: Field::String,
    active: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id banner_type title banner_message active created_at].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id banner_type title banner_message video_url active created_at updated_at].freeze
  FORM_ATTRIBUTES = %i[banner_type title banner_message video_url active].freeze

  def display_resource(platform_banner)
    "Banner ##{platform_banner.id} (#{platform_banner.banner_type})"
  end
end
