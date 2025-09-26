# frozen_string_literal: true

# OTP Configuration
# This file contains configuration constants for OTP (One-Time Password) functionality

module OtpConfig
  # Default OTP expiration time in minutes
  DEFAULT_EXPIRY_MINUTES = ENV.fetch('OTP_EXPIRY_MINUTES', 10).to_i
  
  # Maximum number of OTP generation attempts per user per day
  MAX_DAILY_ATTEMPTS = ENV.fetch('OTP_MAX_DAILY_ATTEMPTS', 10).to_i
  
  # Minimum interval between OTP generation requests (in seconds)
  MIN_RESEND_INTERVAL = ENV.fetch('OTP_MIN_RESEND_INTERVAL', 60).to_i

  class << self
    def expiry_minutes
      DEFAULT_EXPIRY_MINUTES
    end

    def max_daily_attempts
      MAX_DAILY_ATTEMPTS
    end

    def min_resend_interval
      MIN_RESEND_INTERVAL
    end
  end
end