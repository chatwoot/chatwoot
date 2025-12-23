# frozen_string_literal: true

# This module is copied from activesupport
# https://github.com/rails/rails/blob/3235827585d87661942c91bc81f64f56d710f0b2/activesupport/lib/active_support/security_utils.rb
module Slack
  module Utils
    # rubocop:disable Naming/MethodParameterName
    module Security
      # Constant time string comparison, for fixed length strings.
      #
      # The values compared should be of fixed length, such as strings
      # that have already been processed by HMAC. Raises in case of length mismatch.

      if defined?(OpenSSL.fixed_length_secure_compare)
        def fixed_length_secure_compare(a, b)
          OpenSSL.fixed_length_secure_compare(a, b)
        end
      else
        def fixed_length_secure_compare(a, b)
          raise ArgumentError, 'inputs must be of equal length' unless a.bytesize == b.bytesize

          l = a.unpack "C#{a.bytesize}"

          res = 0
          b.each_byte { |byte| res |= byte ^ l.shift }
          res.zero?
        end
      end
      module_function :fixed_length_secure_compare

      # Secure string comparison for strings of variable length.
      #
      # While a timing attack would not be able to discern the content of
      # a secret compared via secure_compare, it is possible to determine
      # the secret length. This should be considered when using secure_compare
      # to compare weak, short secrets to user input.
      def secure_compare(a, b)
        a.bytesize == b.bytesize && fixed_length_secure_compare(a, b)
      end
      module_function :secure_compare
    end
    # rubocop:enable Naming/MethodParameterName
  end
end
