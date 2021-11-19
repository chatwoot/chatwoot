# frozen_string_literal: true

module Reportable
  extend ActiveSupport::Concern

  included do
    has_many :events, dependent: :destroy_async
  end
end
