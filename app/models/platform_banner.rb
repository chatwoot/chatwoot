# == Schema Information
#
# Table name: platform_banners
#
#  id             :bigint           not null, primary key
#  active         :boolean          default(TRUE), not null
#  banner_message :text             not null
#  banner_type    :integer          default("info"), not null
#  title          :string
#  video_url      :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class PlatformBanner < ApplicationRecord
  # The dashboard plays the embed template's src in an iframe; script-based embeds have none.
  VIDEO_URL_REGEX = /\A#{Regexp.union(CustomMarkdownRenderer.embed_regexes.except('github_gist', 'wistia').values)}/

  enum :banner_type, { info: 0, warning: 1, error: 2, feature_announcement: 3 }

  validates :banner_message, presence: true
  validates :title, presence: true, if: :feature_announcement?
  validates :video_url, format: { with: VIDEO_URL_REGEX }, if: :feature_announcement?

  scope :active, -> { where(active: true) }
end
