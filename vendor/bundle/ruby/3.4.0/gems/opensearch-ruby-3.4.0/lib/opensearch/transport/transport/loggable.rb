# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
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

module OpenSearch
  # Module to encapsulate all logging functionality.
  #
  # @since 7.0.0
  module Loggable
    # Log a debug message.
    #
    # @example Log a debug message.
    #   log_debug('Message')
    #
    # @param [ String ] message The message to log.
    #
    # @since 7.0.0
    def log_debug(message)
      logger.debug(message) if logger&.debug?
    end

    # Log an error message.
    #
    # @example Log an error message.
    #   log_error('Message')
    #
    # @param [ String ] message The message to log.
    #
    # @since 7.0.0
    def log_error(message)
      logger.error(message) if logger&.error?
    end

    # Log a fatal message.
    #
    # @example Log a fatal message.
    #   log_fatal('Message')
    #
    # @param [ String ] message The message to log.
    #
    # @since 7.0.0
    def log_fatal(message)
      logger.fatal(message) if logger&.fatal?
    end

    # Log an info message.
    #
    # @example Log an info message.
    #   log_info('Message')
    #
    # @param [ String ] message The message to log.
    #
    # @since 7.0.0
    def log_info(message)
      logger.info(message) if logger&.info?
    end

    # Log a warn message.
    #
    # @example Log a warn message.
    #   log_warn('Message')
    #
    # @param [ String ] message The message to log.
    #
    # @since 7.0.0
    def log_warn(message)
      logger.warn(message) if logger&.warn?
    end
  end
end
