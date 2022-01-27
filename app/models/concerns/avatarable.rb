# frozen_string_literal: true

module Avatarable
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    has_one_attached :avatar
    validate :acceptable_avatar, if: -> { avatar.changed? }
  end

  def avatar_url
    return url_for(avatar.representation(resize: '250x250')) if avatar.attached? && avatar.representable?

    if [SuperAdmin, User, Contact].include?(self.class) && email.present?
      hash = Digest::MD5.hexdigest(email)
      return "https://www.gravatar.com/avatar/#{hash}?d=404"
    end

    ''
  end

  def acceptable_avatar
    return unless avatar.attached?

    errors.add(:avatar, 'is too big') if avatar.byte_size > 15.megabytes

    acceptable_types = ['image/jpeg', 'image/png', 'image/gif'].freeze
    errors.add(:avatar, 'filetype not supported') unless acceptable_types.include?(avatar.content_type)
  end
end
