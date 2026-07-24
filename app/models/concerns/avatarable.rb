# frozen_string_literal: true

require 'uri'

module Avatarable
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    has_one_attached :avatar
    validate :acceptable_avatar, if: -> { avatar.changed? }
    after_save :fetch_avatar_from_gravatar
  end

  def avatar_url
    return '' unless avatar.attached? && avatar.representable?

    representation = avatar.representation(resize_to_fill: [250, nil])
    frontend_url = URI.parse(ENV.fetch('FRONTEND_URL'))

    rails_blob_representation_proxy_url(
      representation.blob.signed_id,
      representation.variation.key,
      representation.blob.filename,
      host: frontend_url.host,
      protocol: frontend_url.scheme
    )
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

    acceptable_types = ['image/jpeg', 'image/png', 'image/gif'].freeze
    errors.add(:avatar, 'filetype not supported') unless acceptable_types.include?(avatar.content_type)
  end
end
