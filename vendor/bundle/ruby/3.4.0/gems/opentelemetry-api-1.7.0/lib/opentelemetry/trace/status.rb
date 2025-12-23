# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Status represents the status of a finished {Span}. It is composed of a
    # status code in conjunction with an optional descriptive message.
    class Status
      class << self
        private :new

        # Returns a newly created {Status} with code == UNSET and an optional
        # description.
        #
        # @param [String] description
        # @return [Status]
        def unset(description = '')
          new(UNSET, description: description)
        end

        # Returns a newly created {Status} with code == OK and an optional
        # description.
        #
        # @param [String] description
        # @return [Status]
        def ok(description = '')
          new(OK, description: description)
        end

        # Returns a newly created {Status} with code == ERROR and an optional
        # description.
        #
        # @param [String] description
        # @return [Status]
        def error(description = '')
          new(ERROR, description: description)
        end
      end

      # Retrieve the status code of this Status.
      #
      # @return [Integer]
      attr_reader :code

      # Retrieve the description of this Status.
      #
      # @return [String]
      attr_reader :description

      # @api private
      # The constructor is private and only for use internally by the class.
      # Users should use the {unset}, {error}, or {ok} factory methods to
      # obtain a {Status} instance.
      #
      # @param [Integer] code One of the status codes below
      # @param [String] description
      def initialize(code, description: '')
        @code = code
        @description = description
      end

      # Returns false if this {Status} represents an error, else returns true.
      #
      # @return [Boolean]
      def ok?
        @code != ERROR
      end

      # The following represents the set of status codes of a
      # finished {Span}

      # The operation completed successfully.
      OK = 0

      # The default status.
      UNSET = 1

      # An error.
      ERROR = 2
    end
  end
end
