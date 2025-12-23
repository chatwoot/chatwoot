# frozen_string_literal: true

require 'securerandom'

module HTTParty
  class Request
    class MultipartBoundary
      def self.generate
        "------------------------#{SecureRandom.urlsafe_base64(12)}"
      end
    end
  end
end
