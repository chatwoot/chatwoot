# frozen_string_literal: true

module Avatarable
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    has_one_attached :avatar
    has_one_attached :azar_avatar
    has_one_attached :mono_avatar
    has_one_attached :gbits_avatar
    validate :acceptable_avatar, if: -> { avatar.changed? }
    validate :acceptable_azar_avatar, if: -> { azar_avatar.changed? }
    validate :acceptable_mono_avatar, if: -> { mono_avatar.changed? }
    validate :acceptable_gbits_avatar, if: -> { gbits_avatar.changed? }
    after_save :fetch_avatar_from_gravatar
  end

  def avatar_url
    return url_for(avatar.representation(resize_to_fill: [250, nil])) if avatar.attached? && avatar.representable?

    ''
  end

  def azar_avatar_url
    return url_for(azar_avatar.representation(resize_to_fill: [250, nil])) if azar_avatar.attached? && azar_avatar.representable?

    ''
  end

  def mono_avatar_url
    return url_for(mono_avatar.representation(resize_to_fill: [250, nil])) if mono_avatar.attached? && mono_avatar.representable?

    ''
  end

  def gbits_avatar_url
    return url_for(gbits_avatar.representation(resize_to_fill: [250, nil])) if gbits_avatar.attached? && gbits_avatar.representable?

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

    acceptable_types = ['image/jpeg', 'image/png', 'image/gif'].freeze
    errors.add(:avatar, 'filetype not supported') unless acceptable_types.include?(avatar.content_type)
  end

  def acceptable_azar_avatar
    return unless azar_avatar.attached?

    errors.add(:azar_avatar, 'is too big') if azar_avatar.byte_size > 15.megabytes

    acceptable_types = ['image/jpeg', 'image/png', 'image/gif'].freeze
    errors.add(:azar_avatar, 'filetype not supported') unless acceptable_types.include?(azar_avatar.content_type)
  end

  def acceptable_mono_avatar
    return unless mono_avatar.attached?

    errors.add(:mono_avatar, 'is too big') if mono_avatar.byte_size > 15.megabytes

    acceptable_types = ['image/jpeg', 'image/png', 'image/gif'].freeze
    errors.add(:mono_avatar, 'filetype not supported') unless acceptable_types.include?(mono_avatar.content_type)
  end

  def acceptable_gbits_avatar
    return unless gbits_avatar.attached?

    errors.add(:gbits_avatar, 'is too big') if gbits_avatar.byte_size > 15.megabytes

    acceptable_types = ['image/jpeg', 'image/png', 'image/gif'].freeze
    errors.add(:gbits_avatar, 'filetype not supported') unless acceptable_types.include?(gbits_avatar.content_type)
  end
end
