# frozen_string_literal: true

module Avatarable
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  ALLOWED_AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  included do
    has_one_attached :avatar
    validate :acceptable_avatar, if: -> { avatar.changed? }
    after_save :fetch_avatar_from_gravatar
  end

  # `additional_attributes` is one JSON column that several writers share, so a read-modify-write
  # that spans anything slow persists a copy taken before and throws away whatever landed in the
  # meantime. Re-read under the row lock and merge; never write a snapshot from before a network
  # call. The lock covers only the read and the write, never the call itself.
  def update_avatar_sync_markers!(remove: [], merge: {})
    with_lock do
      attributes = (additional_attributes || {}).except(*remove).merge(merge)
      next if attributes == additional_attributes

      # Persist without validations, which would fail on the avatar file checks.
      update_columns(additional_attributes: attributes) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def avatar_url
    return url_for(avatar.representation(resize_to_fill: [250, nil])) if avatar.attached? && avatar.representable?

    ''
  end

  def fetch_avatar_from_gravatar
    return unless saved_changes.key?(:email)
    return if email.blank?

    # Incase avatar_url is supplied, we don't want to fetch avatar from gravatar
    # So we will wait for it to be processed
    Avatar::AvatarFromGravatarJob.set(wait: 30.seconds).perform_later(self, email)
  end

  def acceptable_avatar
    return unless avatar.attached?

    errors.add(:avatar, 'is too big') if avatar.byte_size > 15.megabytes

    errors.add(:avatar, 'filetype not supported') unless ALLOWED_AVATAR_CONTENT_TYPES.include?(avatar.content_type)
  end
end
