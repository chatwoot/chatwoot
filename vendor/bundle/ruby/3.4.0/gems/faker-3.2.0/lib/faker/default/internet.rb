# frozen_string_literal: true

module Faker
  class Internet < Base
    # Private, Host, and Link-Local network address blocks as defined in https://en.wikipedia.org/wiki/IPv4#Special-use_addresses
    PRIVATE_IPV4_ADDRESS_RANGES = [
      [10..10,   0..255,   0..255, 1..255], # 10.0.0.0/8     - Used for local communications within a private network
      [100..100, 64..127,  0..255, 1..255], # 100.64.0.0/10  - Shared address space for communications between an ISP and its subscribers
      [127..127, 0..255,   0..255, 1..255], # 127.0.0.0/8    - Used for loopback addresses to the local host
      [169..169, 254..254, 0..255, 1..255], # 169.254.0.0/16 - Used for link-local addresses between two hosts on a single link when
      [172..172, 16..31,   0..255, 1..255], # 172.16.0.0/12  - Used for local communications within a private network
      [192..192, 0..0,     0..0,   1..255], # 192.0.0.0/24   - IETF Protocol Assignments
      [192..192, 168..168, 0..255, 1..255], # 192.168.0.0/16 - Used for local communications within a private network
      [198..198, 18..19,   0..255, 1..255]  # 198.18.0.0/15  - Used for benchmark testing of inter-network communications between subnets
    ].each(&:freeze).freeze

    class << self
      extend Gem::Deprecate

      ##
      # Returns the email address
      #
      # @return [String]
      #
      # @param name [String]
      # @param separators [Array]
      # @param domain [String]
      #
      # @example
      #   Faker::Internet.email                                                           #=> "renee@zieme.test"
      #   Faker::Internet.email(name: 'smith')                                            #=> "smith@bergnaum.test"
      #   Faker::Internet.email(name: 'sam smith', separators: ['-'])                     #=> "smith-sam@tromp.example"
      #   Faker::Internet.email(name: 'sam smith', separators: ['-'], domain: 'test')     #=> "sam-smith@test.example"
      #   Faker::Internet.email(domain: 'gmail.com')                                      #=> "foo@gmail.com"
      def email(name: nil, separators: nil, domain: nil)
        local_part = if separators
                       username(specifier: name, separators: separators)
                     else
                       username(specifier: name)
                     end

        sanitized_local_part = sanitize_email_local_part(local_part)

        generate_domain = if domain.nil?
                            domain_name
                          else
                            domain_name(domain: domain)
                          end

        construct_email(sanitized_local_part, generate_domain)
      end

      ##
      # Returns the email address with domain either gmail.com, yahoo.com or hotmail.com
      #
      # @return [String]
      #
      # @param name [String]
      #
      # @example
      #   Faker::Internet.free_email                                                           #=> "samsmith@gmail.com"
      #   Faker::Internet.free_email(name: 'smith')                                            #=> "smith@yahoo.com"
      def free_email(name: nil)
        construct_email(
          sanitize_email_local_part(username(specifier: name)),
          fetch('internet.free_email')
        )
      end
      deprecate :free_email, :email, 2023, 10

      ##
      # Returns the email address with fixed domain name as 'example'
      #
      # @return [String]
      #
      # @param name [String]
      #
      # @example
      #   Faker::Internet.safe_email                                                           #=> "samsmith@example.com"
      #   Faker::Internet.safe_email(name: 'smith')                                            #=> "smith@example.net"
      def safe_email(name: nil)
        construct_email(
          sanitize_email_local_part(username(specifier: name)),
          "example.#{sample(%w[org com net])}"
        )
      end
      deprecate :safe_email, :email, 2023, 10

      ##
      # Returns the username
      #
      # @return [String]
      #
      # @param specifier [Integer, Range, String] When int value passed it returns the username longer than specifier. Max value can be 10^6
      # @param separators [Array]
      #
      # @example
      #   Faker::Internet.username(specifier: 10)                     #=> "lulu.goodwin"
      #   Faker::Internet.username(specifier: 5..10)                  #=> "morris"
      #   Faker::Internet.username(specifier: 5..10)                  #=> "berryberry"
      #   Faker::Internet.username(specifier: 20, separators: ['-'])  #=> "nikki_sawaynnikki_saway"
      def username(specifier: nil, separators: %w[. _])
        with_locale(:en) do
          return shuffle(specifier.scan(/[[:word:]]+/)).join(sample(separators)).downcase if specifier.respond_to?(:scan)

          case specifier
          when Integer
            # If specifier is Integer and has large value, Argument error exception is raised to overcome memory full error
            raise ArgumentError, 'Given argument is too large' if specifier > 10**6

            tries = 0 # Don't try forever in case we get something like 1_000_000.
            result = nil
            loop do
              result = username(specifier: nil, separators: separators)
              tries += 1
              break unless result.length < specifier && tries < 7
            end
            return result * (specifier / result.length + 1) if specifier.positive?
          when Range
            tries = 0
            result = nil
            loop do
              result = username(specifier: specifier.min, separators: separators)
              tries += 1
              break unless !specifier.include?(result.length) && tries < 7
            end
            return result[0...specifier.max]
          end

          sample([
                   Char.prepare(Name.first_name),
                   [Name.first_name, Name.last_name].map do |name|
                     Char.prepare(name)
                   end.join(sample(separators))
                 ])
        end
      end

      ##
      # Produces a randomized string of characters suitable for passwords
      #
      # @param min_length [Integer] The minimum length of the password
      # @param max_length [Integer] The maximum length of the password
      # @param mix_case [Boolean] Toggles if uppercased letters are allowed. If true, at least one will be added.
      # @param special_characters [Boolean] Toggles if special characters are allowed. If true, at least one will be added.
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.password #=> "Vg5mSvY1UeRg7"
      # @example
      #   Faker::Internet.password(min_length: 8) #=> "YfGjIk0hGzDqS0"
      # @example
      #   Faker::Internet.password(min_length: 10, max_length: 20) #=> "EoC9ShWd1hWq4vBgFw"
      # @example
      #   Faker::Internet.password(min_length: 10, max_length: 20, mix_case: true) #=> "3k5qS15aNmG"
      # @example
      #   Faker::Internet.password(min_length: 10, max_length: 20, mix_case: true, special_characters: true) #=> "*%NkOnJsH4"
      #
      # @faker.version 2.1.3
      def password(min_length: 8, max_length: 16, mix_case: true, special_characters: false)
        raise ArgumentError, 'max_length must be more than min_length' if max_length < min_length

        character_types = []
        required_min_length = 0

        if mix_case
          character_types << :mix_case
          required_min_length += 2
        end

        if special_characters
          character_types << :special_characters
          required_min_length += 1
        end

        raise ArgumentError, "min_length should be at least #{required_min_length} to enable #{character_types.join(', ')} configuration" if min_length < required_min_length

        target_length = rand(min_length..max_length)

        password = []
        character_bag = []

        # use lower_chars by default and add upper_chars if mix_case
        lower_chars = ('a'..'z').to_a
        password << lower_chars[rand(lower_chars.count - 1)]
        character_bag += lower_chars

        digits = ('1'..'9').to_a
        password << digits[rand(digits.count - 1)]
        character_bag += digits

        if character_types.include?(:mix_case)
          upper_chars = ('A'..'Z').to_a
          password << upper_chars[rand(upper_chars.count - 1)]
          character_bag += upper_chars
        end

        if character_types.include?(:special_characters)
          special_chars = %w[! @ # $ % ^ & *]
          password << special_chars[rand(special_chars.count - 1)]
          character_bag += special_chars
        end

        password << character_bag[rand(character_bag.count - 1)] while password.length < target_length

        shuffle(password).join
      end

      ##
      # Returns the domain name
      #
      # @return [String]
      #
      # @param subdomain [Bool] If true passed adds a subdomain in response
      # @param domain [String]
      #
      # @example
      #   Faker::Internet.domain_name                                                   #=> "altenwerth-gerhold.example"
      #   Faker::Internet.domain_name(subdomain: true)                                  #=> "metz.mclaughlin-brekke.test"
      #   Faker::Internet.domain_name(subdomain: true, domain: 'faker')                 #=> "foo.faker.test"
      #   Faker::Internet.domain_name(domain: 'faker-ruby.org')                         #=> "faker-ruby.org"
      #   Faker::Internet.domain_name(subdomain: true, domain: 'faker-ruby.org')        #=> "foo.faker-ruby.org"
      #   Faker::Internet.domain_name(subdomain: true, domain: 'faker.faker-ruby.org')  #=> "faker.faker-ruby.org"
      def domain_name(subdomain: false, domain: nil)
        with_locale(:en) do
          if domain
            domain
              .split('.')
              .map { |domain_part| Char.prepare(domain_part) }
              .tap do |domain_elements|
                if domain_elements.length < 2
                  domain_elements << domain_suffix(safe: true)
                end
                if subdomain && domain_elements.length < 3
                  domain_elements.unshift(Char.prepare(domain_word))
                end
              end.join('.')
          else
            [domain_word, domain_suffix(safe: true)].tap do |domain_elements|
              if subdomain
                domain_elements.unshift(Char.prepare(domain_word))
              end
            end.join('.')
          end
        end
      end

      ##
      # Fixes ä, ö, ü, ß characters in string passed with ae, oe, ue, ss resp.
      #
      # @return [String]
      #
      # @param string [String]
      #
      # @example
      #   Faker::Internet.fix_umlauts                     #=> ""
      #   Faker::Internet.fix_umlauts(string: 'faker')    #=> "faker"
      #   Faker::Internet.fix_umlauts(string: 'faküer')   #=> "fakueer"
      def fix_umlauts(string: '')
        Char.fix_umlauts(string)
      end

      ##
      # Returns the domain word for internet
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.domain_word   #=> "senger"
      def domain_word
        with_locale(:en) { Char.prepare(Company.name.split.first) }
      end

      ## Returns the domain suffix e.g. com, org, co, biz, info etc.
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.domain_suffix              #=> "com"
      #   Faker::Internet.domain_suffix              #=> "biz"
      #   Faker::Internet.domain_suffix(safe: true)  #=> "example"
      #   Faker::Internet.domain_suffix(safe: true)  #=> "test"
      def domain_suffix(safe: nil)
        if safe
          fetch('internet.safe_domain_suffix')
        else
          fetch('internet.domain_suffix')
        end
      end

      ##
      # Returns the MAC address
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.mac_address                   #=> "74:d0:c9:22:95:12"
      #   Faker::Internet.mac_address(prefix: 'a')      #=> "0a:91:ce:24:89:3b"
      #   Faker::Internet.mac_address(prefix: 'aa')     #=> "aa:38:a0:3e:e8:41"
      #   Faker::Internet.mac_address(prefix: 'aa:44')  #=> "aa:44:30:88:6e:95"
      def mac_address(prefix: '')
        prefix_digits = prefix.split(':').map { |d| d.to_i(16) }
        address_digits = Array.new((6 - prefix_digits.size)) { rand(256) }
        (prefix_digits + address_digits).map { |d| format('%02x', d) }.join(':')
      end

      ##
      # Returns the IPv4 address
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.ip_v4_address   #=> "97.117.128.93"
      def ip_v4_address
        [rand_in_range(0, 255), rand_in_range(0, 255),
         rand_in_range(0, 255), rand_in_range(0, 255)].join('.')
      end

      ##
      # Returns the private IPv4 address
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.private_ip_v4_address   #=> "127.120.80.42"
      def private_ip_v4_address
        sample(PRIVATE_IPV4_ADDRESS_RANGES).map { |range| rand(range) }.join('.')
      end

      ##
      # Returns the public IPv4 address
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.public_ip_v4_address   #=> "127.120.80.42"
      def public_ip_v4_address
        addr = nil
        loop do
          addr = ip_v4_address
          break unless reserved_net_checker[addr]
        end
        addr
      end

      ##
      # Returns the private network regular expressions
      #
      # @return [Array]
      #
      # @example
      #   Faker::Internet.private_nets_regex  #=> [/^10\./, /^100\.(6[4-9]|[7-9]\d|1[0-1]\d|12[0-7])\./, /^127\./, /^169\.254\./, /^172\.(1[6-9]|2\d|3[0-1])\./, /^192\.0\.0\./, /^192\.168\./, /^198\.(1[8-9])\./]
      def private_nets_regex
        [
          /^10\./,                                       # 10.0.0.0    - 10.255.255.255
          /^100\.(6[4-9]|[7-9]\d|1[0-1]\d|12[0-7])\./,   # 100.64.0.0  - 100.127.255.255
          /^127\./,                                      # 127.0.0.0   - 127.255.255.255
          /^169\.254\./,                                 # 169.254.0.0 - 169.254.255.255
          /^172\.(1[6-9]|2\d|3[0-1])\./,                 # 172.16.0.0  - 172.31.255.255
          /^192\.0\.0\./,                                # 192.0.0.0   - 192.0.0.255
          /^192\.168\./,                                 # 192.168.0.0 - 192.168.255.255
          /^198\.(1[8-9])\./                             # 198.18.0.0  - 198.19.255.255
        ]
      end

      ##
      # Returns lambda to check if address passed is private or not
      #
      # @return [Lambda]
      #
      # @example
      #   Faker::Internet.private_net_checker.call("127.120.80.42")   #=> true
      #   Faker::Internet.private_net_checker.call("148.120.80.42")   #=> false
      def private_net_checker
        ->(addr) { private_nets_regex.any? { |net| net =~ addr } }
      end

      ##
      # Returns the reserved network regular expressions
      #
      # @return [Array]
      #
      # @example
      #   Faker::Internet.reserved_nets_regex   #=> [/^0\./, /^192\.0\.2\./, /^192\.88\.99\./, /^198\.51\.100\./, /^203\.0\.113\./, /^(22[4-9]|23\d)\./, /^(24\d|25[0-5])\./]
      def reserved_nets_regex
        [
          /^0\./,                 # 0.0.0.0      - 0.255.255.255
          /^192\.0\.2\./,         # 192.0.2.0    - 192.0.2.255
          /^192\.88\.99\./,       # 192.88.99.0  - 192.88.99.255
          /^198\.51\.100\./,      # 198.51.100.0 - 198.51.100.255
          /^203\.0\.113\./,       # 203.0.113.0  - 203.0.113.255
          /^(22[4-9]|23\d)\./,    # 224.0.0.0    - 239.255.255.255
          /^(24\d|25[0-5])\./     # 240.0.0.0    - 255.255.255.254  and  255.255.255.255
        ]
      end

      ##
      # Returns lambda function to check address passed is reserved or not
      #
      # @return [Lambda]
      #
      # @example
      #   Faker::Internet.reserved_net_checker.call('192.88.99.255')   #=> true
      #   Faker::Internet.reserved_net_checker.call('192.88.199.255')  #=> false
      def reserved_net_checker
        ->(addr) { (private_nets_regex + reserved_nets_regex).any? { |net| net =~ addr } }
      end

      ##
      # Returns Ipv4 address with CIDR, range from 1 to 31
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.ip_v4_cidr  #=> "129.162.99.74/16"
      #   Faker::Internet.ip_v4_cidr  #=> "129.162.99.74/24"
      def ip_v4_cidr
        "#{ip_v4_address}/#{rand(1..31)}"
      end

      ##
      # Returns Ipv6 address
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.ip_v6_address   #=> "7754:76d4:c7aa:7646:ea68:1abb:4055:4343"
      def ip_v6_address
        (1..8).map { rand(65_536).to_s(16) }.join(':')
      end

      ##
      # Returns Ipv6 address with CIDR, range between 1 to 127
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.ip_v6_cidr  #=> "beca:9b99:4bb6:9712:af2f:516f:8507:96e1/99"
      def ip_v6_cidr
        "#{ip_v6_address}/#{rand(1..127)}"
      end

      ##
      # Returns URL
      #
      # @return [String]
      #
      # @param host [String]
      # @param path [String]
      # @param scheme [String]
      #
      # @example
      #   Faker::Internet.url                                                           #=> "http://treutel.test/demarcus"
      #   Faker::Internet.url(host: 'faker')                                            #=> "http://faker/shad"
      #   Faker::Internet.url(host: 'faker', path: '/docs')                             #=> "http://faker/docs"
      #   Faker::Internet.url(host: 'faker', path: '/docs', scheme: 'https')            #=> "https://faker/docs"
      def url(host: domain_name, path: "/#{username}", scheme: 'http')
        "#{scheme}://#{host}#{path}"
      end

      ##
      # Returns unique string in URL
      #
      # @return [String]
      #
      # @param words [String] Comma or period separated words list
      # @param glue [String] Separator to add between words passed, default used are '-' or '_'
      #
      # @example
      #   Faker::Internet.slug                                    #=> "repudiandae-sed"
      #   Faker::Internet.slug(words: 'test, faker')              #=> "test-faker"
      #   Faker::Internet.slug(words: 'test. faker')              #=> "test-faker"
      #   Faker::Internet.slug(words: 'test. faker', glue: '$')   #=> "test$faker"
      def slug(words: nil, glue: nil)
        glue ||= sample(%w[- _])
        return words.delete(',.').gsub(' ', glue).downcase unless words.nil?

        sample(translate('faker.internet.slug'), 2).join(glue)
      end

      ##
      # Generates random token
      #
      # @return[String]
      #
      # @example
      #   Faker::Internet.device_token  #=> "749f535671cf6b34d8e794d212d00c703b96274e07161b18b082d0d70ef1052f"
      def device_token
        shuffle(rand(16**64).to_s(16).rjust(64, '0').chars.to_a).join
      end

      ##
      # Generates the random browser identifier
      #
      # @return [String]
      #
      # @param vendor [String] Name of vendor, supported vendors are aol, chrome, firefox, internet_explorer, netscape, opera, safari
      #
      # @example
      #   Faker::Internet.user_agent                    #=> "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
      #   Faker::Internet.user_agent(vendor: 'chrome')  #=> "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
      #   Faker::Internet.user_agent(vendor: 'safari')  #=> "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A"
      #   Faker::Internet.user_agent(vendor: 'faker')   #=> "Mozilla/5.0 (Windows; U; Win 9x 4.90; SG; rv:1.9.2.4) Gecko/20101104 Netscape/9.1.0285"
      def user_agent(vendor: nil)
        agent_hash = translate('faker.internet.user_agent')
        agents = vendor.respond_to?(:to_sym) && agent_hash[vendor.to_sym] || agent_hash[sample(agent_hash.keys)]
        sample(agents)
      end

      ##
      # Generate Web Crawler's user agents
      #
      # @return [String]
      #
      # @param vendor [String] Name of vendor, supported vendors are googlebot, bingbot, duckduckbot, baiduspider, yandexbot
      #
      # @example
      #   Faker::Internet.bot_user_agent                        #=> "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)"
      #   Faker::Internet.bot_user_agent(vendor: 'googlebot')   #=> "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/99.0.4844.84 Safari/537.36"
      #   Faker::Internet.bot_user_agent(vendor: 'bingbot')     #=> "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm) Chrome/86.0.4240.68 Safari/537.36 Edg/86.0.622.31"
      def bot_user_agent(vendor: nil)
        agent_hash = translate('faker.internet.bot_user_agent')
        agents = vendor.respond_to?(:to_sym) && agent_hash[vendor.to_sym] || agent_hash[sample(agent_hash.keys)]
        sample(agents)
      end

      ##
      # Generated universally unique identifier
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.uuid  #=> "8a6cdd40-6d78-4fdb-912b-190e3057197f"
      def uuid
        # borrowed from: https://github.com/ruby/ruby/blob/d48783bb0236db505fe1205d1d9822309de53a36/lib/securerandom.rb#L250
        ary = Faker::Config.random.bytes(16).unpack('NnnnnN')
        ary[2] = (ary[2] & 0x0fff) | 0x4000
        ary[3] = (ary[3] & 0x3fff) | 0x8000
        '%08x-%04x-%04x-%04x-%04x%08x' % ary # rubocop:disable Style/FormatString
      end

      ##
      # Produces a random string of alphabetic characters, (no digits)
      #
      # @param length [Integer] The length of the string to generate
      # @param padding [Boolean] Toggles if a final equal '=' will be added.
      # @param urlsafe [Boolean] Toggles charset to '-' and '_' instead of '+' and '/'.
      #
      # @return [String]
      #
      # @example
      #   Faker::Internet.base64
      #     #=> "r_hbZ2DSD-ZACzZT"
      # @example
      #   Faker::Internet.base64(length: 4, padding: true, urlsafe: false)
      #     #=> "x1/R="
      #
      # @faker.version 2.11.0
      def base64(length: 16, padding: false, urlsafe: true)
        char_range = [
          Array('0'..'9'),
          Array('A'..'Z'),
          Array('a'..'z'),
          urlsafe ? %w[- _] : %w[+ /]
        ].flatten
        s = Array.new(length) { sample(char_range) }.join
        s += '=' if padding
        s
      end

      ##
      # Produces a randomized hash of internet user details
      # @example
      #   Faker::Internet.user #=> { username: 'alexie', email: 'trudie@grant.test' }
      #
      # @example
      #   Faker::Internet.user('username', 'email', 'password') #=> { username: 'alexie', email: 'gayle@kohler.test', password: 'DtEf9P8wS31iMyC' }
      #
      # @return [hash]
      #
      # @faker.version next
      def user(*args)
        user_hash = {}
        args = %w[username email] if args.empty?
        args.each { |arg| user_hash[:"#{arg}"] = send(arg) }
        user_hash
      end

      alias user_name username

      private

      def sanitize_email_local_part(local_part)
        char_range = [
          Array('0'..'9'),
          Array('A'..'Z'),
          Array('a'..'z'),
          "!#$%&'*+-/=?^_`{|}~.".chars
        ].flatten

        local_part.chars.map do |char|
          char_range.include?(char) ? char : '#'
        end.join
      end

      def construct_email(local_part, domain_name)
        [local_part, domain_name].join('@')
      end
    end
  end
end
