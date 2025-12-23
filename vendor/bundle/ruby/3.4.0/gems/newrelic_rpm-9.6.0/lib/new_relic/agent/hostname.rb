# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'socket'
require 'new_relic/helper'

module NewRelic
  module Agent
    module Hostname
      def self.get
        dyno_name = ENV['DYNO']
        @hostname ||= if dyno_name && ::NewRelic::Agent.config[:'heroku.use_dyno_names']
          matching_prefix = heroku_dyno_name_prefix(dyno_name)
          dyno_name = "#{matching_prefix}.*" if matching_prefix
          dyno_name
        else
          Socket.gethostname.force_encoding(Encoding::UTF_8)
        end
      end

      # Pass '-f' to the external executable 'hostname' to request the fully
      # qualified domain name (fqdn). For implementations of 'hostname' that
      # do not support '-f' (such as the one OpenBSD ships with), fall back
      # to calling 'hostname' without the '-f'. If both ways of calling
      # 'hostname' fail, or in a context where 'hostname' is not even
      # available (within an AWS Lambda function, for example), call the
      # 'get' method which uses Socket instead of an external executable.
      def self.get_fqdn
        begin
          NewRelic::Helper.run_command('hostname -f')
        rescue NewRelic::CommandRunFailedError
          NewRelic::Helper.run_command('hostname')
        end
      rescue NewRelic::CommandExecutableNotFoundError, NewRelic::CommandRunFailedError => e
        NewRelic::Agent.logger.debug("#{e.class} - #{e.message}")
        get
      end

      def self.heroku_dyno_name_prefix(dyno_name)
        get_dyno_prefixes.find do |dyno_prefix|
          dyno_name.start_with?(dyno_prefix + '.')
        end
      end

      def self.get_dyno_prefixes
        ::NewRelic::Agent.config[:'heroku.dyno_name_prefixes_to_shorten']
      end

      LOCALHOST = %w[
        localhost
        0.0.0.0
        127.0.0.1
        0:0:0:0:0:0:0:1
        0:0:0:0:0:0:0:0
        ::1
        ::
      ].freeze

      def self.local?(host_or_ip)
        LOCALHOST.include?(host_or_ip)
      end

      def self.get_external(host_or_ip)
        local?(host_or_ip) ? get : host_or_ip
      end
    end
  end
end
