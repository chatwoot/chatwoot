# frozen_string_literal: true
module Slack
  module RealTime
    module Api
      module MessageId
        private

        def next_id
          @next_id ||= 0
          @next_id += 1
        end
      end
    end
  end
end
