# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  # @api private
  module Logging
    PREFIX = '[ElasticAPM] '

    LEVELS = {
      debug: Logger::DEBUG,
      info: Logger::INFO,
      warn: Logger::WARN,
      error: Logger::ERROR,
      fatal: Logger::FATAL
    }.freeze

    def debug(msg, *args, &block)
      log(:debug, msg, *args, &block)
    end

    def info(msg, *args, &block)
      log(:info, msg, *args, &block)
    end

    def warn(msg, *args, &block)
      log(:warn, msg, *args, &block)
    end

    def error(msg, *args, &block)
      log(:error, msg, *args, &block)
    end

    def fatal(msg, *args, &block)
      log(:fatal, msg, *args, &block)
    end

    private

    def log(lvl, msg, *args)
      return unless (logger = @config&.logger)
      return unless LEVELS[lvl] >= (@config&.log_level || 0)

      formatted_msg = prepend_prefix(format(msg.to_s, *args))

      return logger.send(lvl, formatted_msg) unless block_given?

      logger.send(lvl, "#{formatted_msg}\n#{yield}")
    end

    def prepend_prefix(str)
      "#{PREFIX}#{str}"
    end
  end
end
