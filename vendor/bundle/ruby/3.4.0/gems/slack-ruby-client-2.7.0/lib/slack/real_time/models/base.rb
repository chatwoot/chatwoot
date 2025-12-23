# frozen_string_literal: true
module Slack
  module RealTime
    module Models
      class Base < Hashie::Mash
        # see https://github.com/intridea/hashie/issues/394
        def log_built_in_message(*); end
      end
    end
  end
end
