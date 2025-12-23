# frozen_string_literal: true
module Slack
  module Messages
    class Message < Hashie::Mash
      def to_s
        keys.sort_by(&:to_s).map do |key|
          "#{key}=#{self[key]}"
        end.join(', ')
      end

      private

      # see https://github.com/intridea/hashie/issues/394
      def log_built_in_message(*); end
    end
  end
end
