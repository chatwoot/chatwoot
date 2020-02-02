# frozen_string_literal: true

module Avatarable
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    has_one_attached :avatar
  end

  def avatar_url
    if avatar.attached? && avatar.representable?
      url_for(avatar.representation(resize: '250x250'))
    else
      ''
    end
  end
end
