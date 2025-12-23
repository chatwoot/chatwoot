# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module LogOnce
      NUM_LOG_ONCE_KEYS = 1000

      def log_once(level, key, *msgs)
        @already_logged_lock.synchronize do
          return if @already_logged.include?(key)

          if @already_logged.size >= NUM_LOG_ONCE_KEYS && key.kind_of?(String)
            # The reason for preventing too many keys in `logged` is for
            # memory concerns.
            # The reason for checking the type of the key is that we always want
            # to allow symbols to log, since there are very few of them.
            # The assumption here is that you would NEVER pass dynamically-created
            # symbols, because you would never create symbols dynamically in the
            # first place, as that would already be a memory leak in most Rubies,
            # even if we didn't hang on to them all here.
            return
          end

          @already_logged[key] = true
        end

        self.send(level, *msgs)
      end

      def clear_already_logged
        @already_logged_lock.synchronize do
          @already_logged = {}
        end
      end
    end
  end
end
