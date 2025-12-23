module Faker
  class Json < Base
    require 'json'

    class << self
      ##
      # Produces a random simple JSON formatted string.
      #
      # @param width [Integer] Specifies the number of key-value pairs.
      # @param options [Hash] Specifies a Faker gem class to use for keys and for values, respectably. options_hash = {key: Class.method, value: Class.method}
      # @return [Hash{String => String}]
      #
      # @example
      #   Faker::Json.shallow_json(width: 3, options: { key: 'RockBand.name', value: 'Seinfeld.quote' }) # =>
      #     {"Parliament Funkadelic":"They're real, and they're spectacular.",
      #     "Fleetwood Mac":"I'm not a lesbian. I hate men, but I'm not a lesbian.",
      #     "The Roots":"It became very clear to me sitting out there today that every decision
      #     I've made in my entire life has been wrong. My life is the complete opposite of everything
      #     I want it to be. Every instinct I have, in every aspect of life, be it something to wear,
      #     something to eat - it's all been wrong."}
      #
      # @faker.version 1.9.2
      def shallow_json(width: 3, options: { key: 'Name.first_name', value: 'Name.first_name' })
        options[:key] = "Faker::#{options[:key]}"
        options[:value] = "Faker::#{options[:value]}"

        hash = build_shallow_hash(width, options)
        JSON.generate(hash)
      end

      ##
      # Produces a random nested JSON formatted string that can take JSON as an additional argument.
      #
      # @param json [Hash{String => String}] Specifies a Json.shallow_json and uses its keys as keys of the nested JSON.
      # @param width [Integer] Specifies the number of nested key-value pairs.
      # @param options [Hash] Specifies a Faker gem class to use for nested keys and for values, respectably. options_hash = {key: Class.method, value: Class.method}
      # @return [Hash{String => String}]
      #
      # @example
      #   json = Faker::Json.shallow_json(width: 3, options: { key: 'Name.first_name', value: 'Name.last_name' })
      #   puts json # =>
      #     {"Alisha":"Olson","Everardo":"DuBuque","Bridgette":"Turner"}
      #
      #   json2 = Faker::Json.add_depth_to_json(json: json, width: 2, options: { key: 'Name.first_name', value: 'Name.last_name' })
      #   puts json2 # =>
      #     {"Alisha":{"Daisy":"Trantow","Oda":"Haag"},
      #      "Everardo":{"Javier":"Marvin","Eliseo":"Schuppe"},
      #      "Bridgette":{"Jorge":"Kertzmann","Lelah":"MacGyver"}}
      #
      #    json3 = Faker::Json.add_depth_to_json(json: json2, width: 4, options: { key: 'Name.first_name', value: 'Name.last_name' })
      #      puts json3 # =>
      #        {"Alisha":
      #          {"Daisy":
      #            {"Bulah":"Wunsch","Cristian":"Champlin","Lester":"Bartoletti","Greg":"Jacobson"},
      #           "Oda":
      #             {"Salvatore":"Kuhlman","Aubree":"Okuneva","Larry":"Schmitt","Velva":"Gibson"}},
      #         "Everardo":
      #           {"Javier":
      #             {"Eduardo":"Orn","Laila":"Kub","Thad":"Legros","Dion":"Wilderman"},
      #           "Eliseo":
      #             {"Olin":"Hilpert","Marisa":"Greenfelder","Karlee":"Schmitt","Judd":"Larkin"}},
      #         "Bridgette":
      #           {"Jorge":
      #             {"Eloy":"Pfeffer","Kody":"Hansen","Paxton":"Lubowitz","Abe":"Lesch"},
      #           "Lelah":
      #             {"Rick":"Wiza","Bonita":"Bayer","Gardner":"Auer","Felicity":"Abbott"}}}
      #
      # @faker.version 1.9.2
      def add_depth_to_json(json: shallow_json, width: 3, options: { key: 'Name.first_name', value: 'Name.first_name' })
        options[:key] = "Faker::#{options[:key]}"
        options[:value] = "Faker::#{options[:value]}"

        hash = JSON.parse(json)
        hash.each do |key, _|
          add_hash_to_bottom(hash, [key], width, options)
        end
        JSON.generate(hash)
      end

      private

      def build_shallow_hash(width, options)
        key = options[:key]
        value = options[:value]

        hash = {}
        width.times do
          hash[eval(key)] = eval(value)
        end
        hash
      end

      def add_hash_to_bottom(hash, key_array, width, options)
        key_string = build_keys_from_array(key_array)
        if eval("hash#{key_string}").is_a?(::Hash)
          eval("hash#{key_string}").each do |key, _|
            key_array << key
            add_hash_to_bottom(hash, key_array, width, options)
          end
        else
          add_hash(key_array, hash, width, options)
          key_array.pop
        end
      end

      def add_hash(key_array, hash, width, options)
        string_to_eval = 'hash'
        key_array.length.times do |index|
          string_to_eval << "['#{key_array[index]}']"
        end
        string_to_eval << " = #{build_shallow_hash(width, options)}"
        eval(string_to_eval)
        hash
      end

      def build_keys_from_array(key_array)
        key_string = ''
        key_array.each do |value|
          key_string << "['#{value}']"
        end
        key_string
      end
    end
  end
end
