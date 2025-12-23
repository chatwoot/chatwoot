# frozen_string_literal: true

require 'set'

module Bullet
  class NotificationCollector
    attr_reader :collection

    def initialize
      reset
    end

    def reset
      @collection = Set.new
    end

    def add(value)
      @collection << value
    end

    def notifications_present?
      !@collection.empty?
    end
  end
end
