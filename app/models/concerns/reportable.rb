# frozen_string_literal: true

module Reportable
  extend ActiveSupport::Concern

  included do
    has_many :reporting_events, dependent: :destroy
  end
end
