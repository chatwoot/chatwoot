# frozen_string_literal: true
module Slack
  module Web
    module Faraday
      module Options
        def options
          @options ||= begin
            options = { headers: {} }
            options[:headers]['User-Agent'] = user_agent if user_agent
            options[:proxy] = proxy if proxy
            options[:ssl] = { ca_path: ca_path, ca_file: ca_file } if ca_path || ca_file

            request_options = {}
            request_options[:timeout] = timeout if timeout
            request_options[:open_timeout] = open_timeout if open_timeout
            options[:request] = request_options if request_options.any?

            options
          end
        end
      end
    end
  end
end
