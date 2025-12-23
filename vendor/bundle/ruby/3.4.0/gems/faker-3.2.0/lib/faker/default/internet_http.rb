# frozen_string_literal: true

module Faker
  class Internet
    class HTTP < Base
      STATUS_CODES = {
        information: [100, 101, 102, 103],
        successful: [200, 201, 202, 203, 204, 205, 206, 207, 208, 226],
        redirect: [300, 301, 302, 303, 304, 305, 306, 307, 308],
        client_error: [400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412,
                       413, 414, 415, 416, 417, 418, 421, 422, 423, 424, 425, 426, 428,
                       429, 431, 451],
        server_error: [500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511]
      }.freeze

      STATUS_CODES_GROUPS = STATUS_CODES.keys.freeze

      class << self
        ##
        # Produces an HTTP status code
        #
        # @return [Integer]
        #
        # @example
        #   Faker::Internet::HTTP.status_code #=> 418
        # @example
        #   Faker::Internet::HTTP.status_code(group: :information) #=> 102
        # @example
        #   Faker::Internet::HTTP.status_code(group: :successful) #=> 200
        # @example
        #   Faker::Internet::HTTP.status_code(group: :redirect) #=> 306
        # @example
        #   Faker::Internet::HTTP.status_code(group: :client_error) #=> 451
        # @example
        #   Faker::Internet::HTTP.status_code(group: :server_error) #=> 502
        #
        # @faker.version 2.13.0
        def status_code(group: nil)
          return STATUS_CODES[STATUS_CODES_GROUPS.sample].sample unless group

          raise ArgumentError, 'Invalid HTTP status code group' unless STATUS_CODES_GROUPS.include?(group)

          STATUS_CODES[group].sample
        end
      end
    end
  end
end
