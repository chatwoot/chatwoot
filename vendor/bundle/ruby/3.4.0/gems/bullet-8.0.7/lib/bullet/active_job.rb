# frozen_string_literal: true

module Bullet
  module ActiveJob
    def self.included(base)
      base.class_eval do
        around_perform do |_job, block|
          Bullet.profile { block.call }
        end
      end
    end
  end
end
