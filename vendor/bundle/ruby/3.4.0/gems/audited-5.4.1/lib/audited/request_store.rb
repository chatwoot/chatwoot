# frozen_string_literal: true

require "active_support"

module Audited
  class RequestStore < ActiveSupport::CurrentAttributes
    attribute :audited_store
  end
end
