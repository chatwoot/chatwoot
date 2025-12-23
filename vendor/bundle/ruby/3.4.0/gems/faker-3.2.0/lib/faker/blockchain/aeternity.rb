# frozen_string_literal: true

module Faker
  class Blockchain
    class Aeternity < Base
      class << self
        ##
        # Produces a random Aeternity wallet address
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Aeternity.address
        #     #=> "ak_zvU8YQLagjcfng7Tg8yCdiZ1rpiWNp1PBn3vtUs44utSvbJVR"
        #
        def address
          "ak_#{rand_strings}"
        end

        ##
        # Produces a random Aeternity transaction
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Aeternity.transaction
        #     #=> "th_147nDP22h3pHrLt2qykTH4txUwQh1ccaXp"
        #
        def transaction
          "th_#{rand_strings(51)}"
        end

        ##
        # Produces a random Aeternity contract
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Aeternity.contract
        #     #=> "ct_Hk2JsNeWGEYQEHHQCfcBeGrwbhtYSwFTPdDhW2SvjFYVojyhW"
        #
        def contract
          "ct_#{rand_strings}"
        end

        ##
        # Produces a random Aeternity oracle
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Aeternity.oracle
        #     #=> "ok_28QDg7fkF5qiKueSdUvUBtCYPJdmMEoS73CztzXCRAwMGKHKZh"
        #
        def oracle
          "ok_#{rand_strings(51)}"
        end

        protected

        def rand_strings(length = 50)
          hex_alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
          var = +''
          length.times { var << sample(shuffle(hex_alphabet.chars)) }
          var
        end
      end
    end
  end
end
