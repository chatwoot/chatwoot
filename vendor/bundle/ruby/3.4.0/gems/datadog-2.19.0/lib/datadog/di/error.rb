# frozen_string_literal: true

module Datadog
  module DI
    # Base class for Dynamic Instrumentation exceptions.
    #
    # None of these exceptions should be propagated out of DI to user
    # applications, therefore these exceptions are not considered to be
    # part of the public API of the library.
    #
    # @api private
    class Error < StandardError
      # Probe does not contain a line number (i.e., is not a line probe).
      class MissingLineNumber < Error
      end

      # Failed to communicate to the local Datadog agent (e.g. to send
      # probe status or a snapshot).
      class AgentCommunicationError < Error
      end

      # Attempting to instrument a method or file which does not exist.
      #
      # This could be due to the code that is referenced in the probe
      # having not been loaded yet, or due to the probe referencing code
      # that does not in fact exist anywhere (e.g. due to a misspelling).
      class DITargetNotDefined < Error
      end

      # Attempting to instrument a line and the file containing the line
      # was loaded prior to code tracking being enabled.
      class DITargetNotInRegistry < Error
      end

      # Raised when trying to install a probe whose installation failed
      # earlier in the same process. This exception should contain the
      # original exception report from initial installation attempt.
      class ProbePreviouslyFailed < Error
      end

      # Raised when installing a line probe and multiple files match the
      # specified path suffix.
      # A probe must be installed into one file only, since UI only
      # supports one instrumented location for a probe.
      # If multiple files match, UI cannot properly render the data from
      # all of them, and arbitrarily choosing one file may be not what the
      # user intended. Instrumentation will fail when multiple files match
      # and the user will need to make their suffix more precise.
      class MultiplePathsMatch < Error
      end
    end
  end
end
