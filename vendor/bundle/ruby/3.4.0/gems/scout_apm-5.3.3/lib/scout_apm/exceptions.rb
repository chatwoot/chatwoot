module ScoutApm
  module AllExceptionsExceptOnesWeMustNotRescue
    # Borrowed from https://github.com/rspec/rspec-support/blob/v3.8.0/lib/rspec/support.rb#L132-L140
    # These exceptions are dangerous to rescue as rescuing them
    # would interfere with things we should not interfere with.
    AVOID_RESCUING = [NoMemoryError, SignalException, Interrupt, SystemExit]

    def self.===(exception)
      AVOID_RESCUING.none? { |ar| ar === exception }
    end
  end
end