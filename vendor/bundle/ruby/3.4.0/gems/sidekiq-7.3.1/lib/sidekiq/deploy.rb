# frozen_string_literal: true

require "sidekiq/redis_connection"
require "time"

# This file is designed to be required within the user's
# deployment script; it should need a bare minimum of dependencies.
# Usage:
#
#   require "sidekiq/deploy"
#   Sidekiq::Deploy.mark!("Some change")
#
# If you do not pass a label, Sidekiq will try to use the latest
# git commit info.
#

module Sidekiq
  class Deploy
    MARK_TTL = 90 * 24 * 60 * 60 # 90 days

    LABEL_MAKER = -> {
      `git log -1 --format="%h %s"`.strip
    }

    def self.mark!(label = nil)
      Sidekiq::Deploy.new.mark!(label: label)
    end

    def initialize(pool = Sidekiq::RedisConnection.create)
      @pool = pool
    end

    def mark!(at: Time.now, label: nil)
      label ||= LABEL_MAKER.call
      # we need to round the timestamp so that we gracefully
      # handle an very common error in marking deploys:
      # having every process mark its deploy, leading
      # to N marks for each deploy. Instead we round the time
      # to the minute so that multiple marks within that minute
      # will all naturally rollup into one mark per minute.
      whence = at.utc
      floor = Time.utc(whence.year, whence.month, whence.mday, whence.hour, whence.min, 0)
      datecode = floor.strftime("%Y%m%d")
      key = "#{datecode}-marks"
      stamp = floor.iso8601

      @pool.with do |c|
        # only allow one deploy mark for a given label for the next minute
        lock = c.set("deploylock-#{label}", stamp, "nx", "ex", "60")
        if lock
          c.multi do |pipe|
            pipe.hsetnx(key, stamp, label)
            pipe.expire(key, MARK_TTL)
          end
        end
      end
    end

    def fetch(date = Time.now.utc.to_date)
      datecode = date.strftime("%Y%m%d")
      @pool.with { |c| c.hgetall("#{datecode}-marks") }
    end
  end
end
