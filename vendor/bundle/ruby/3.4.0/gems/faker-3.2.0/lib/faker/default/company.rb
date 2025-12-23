# frozen_string_literal: true

module Faker
  class Company < Base
    flexible :company

    class << self
      ##
      # Produces a company name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.name #=> "Roberts Inc"
      #
      # @faker.version 1.6.0
      def name
        parse('company.name')
      end

      ##
      # Produces a company suffix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.suffix #=> "LLC"
      #
      # @faker.version 1.6.0
      def suffix
        fetch('company.suffix')
      end

      ##
      # Produces a company industry.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.industry #=> "Food & Beverages"
      #
      # @faker.version 1.6.0
      def industry
        fetch('company.industry')
      end

      ##
      # Produces a company catch phrase.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.catch_phrase #=> "Grass-roots grid-enabled portal"
      #
      # @faker.version 1.6.0
      def catch_phrase
        translate('faker.company.buzzwords').collect { |list| sample(list) }.join(' ')
      end

      ##
      # Produces a company buzzword.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.buzzword #=> "flexibility"
      #
      # @faker.version 1.8.7
      def buzzword
        sample(translate('faker.company.buzzwords').flatten)
      end

      ##
      # Produces some company BS.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.bs #=> "empower customized functionalities"
      #
      # @faker.version 1.6.0
      # When a straight answer won't do, BS to the rescue!
      def bs
        translate('faker.company.bs').collect { |list| sample(list) }.join(' ')
      end

      ##
      # Produces a company EIN (Employer Identification Number).
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.ein #=> "07-4009024"
      #
      # @faker.version 1.6.0
      def ein
        format('%09d', rand(10**9)).gsub(/(\d{2})(\d{7})/, '\\1-\\2')
      end

      ##
      # Produces a company duns number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.duns_number #=> "70-655-5105"
      #
      # @faker.version 1.6.0
      def duns_number
        format('%09d', rand(10**9)).gsub(/(\d{2})(\d{3})(\d{4})/, '\\1-\\2-\\3')
      end

      ##
      # Produces a company logo.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.logo #=> "https://pigment.github.io/fake-logos/logos/medium/color/12.png"
      #
      # @faker.version 1.8.7
      # Get a random company logo url in PNG format.
      def logo
        rand_num = rand(1..13)
        "https://pigment.github.io/fake-logos/logos/medium/color/#{rand_num}.png"
      end

      ##
      # Produces a company type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.type #=> "Partnership"
      #
      # @faker.version 1.8.7
      def type
        fetch('company.type')
      end

      ##
      # Produces a company profession.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.profession #=> "factory worker"
      #
      # @faker.version 1.6.0
      def profession
        fetch('company.profession')
      end

      ##
      # Produces a company department.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.department #=> "Information Technology"
      #
      # @faker.version next
      def department
        fetch('company.department')
      end

      ##
      # Produces a company spanish organisation number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.spanish_organisation_number #=> "D6819358"
      #
      # @faker.version 1.8.5
      #
      # Get a random Spanish organization number. See more here https://es.wikipedia.org/wiki/N%C3%BAmero_de_identificaci%C3%B3n_fiscal
      def spanish_organisation_number(organization_type: nil)
        # Valid leading character: A, B, C, D, E, F, G, H, J, N, P, Q, R, S, U, V, W
        # format: 1 digit letter (organization type) + 7 digit numbers + 1 digit control (letter or number based on
        # organization type)
        letters = %w[A B C D E F G H J N P Q R S U V W]

        organization_type = sample(letters) unless letters.include?(organization_type)
        code = format('%07d', rand(10**7))
        control = spanish_cif_control_digit(organization_type, code)

        [organization_type, code, control].join
      end

      ##
      # Produces a company swedish organisation number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.swedish_organisation_number #=> "3866029808"
      #
      # @faker.version 1.7.0
      # Get a random Swedish organization number. See more here https://sv.wikipedia.org/wiki/Organisationsnummer
      def swedish_organisation_number
        # Valid leading digit: 1, 2, 3, 5, 6, 7, 8, 9
        # Valid third digit: >= 2
        # Last digit is a control digit
        base = [sample([1, 2, 3, 5, 6, 7, 8, 9]), sample((0..9).to_a), sample((2..9).to_a), format('%06d', rand(10**6))].join
        base + luhn_algorithm(base).to_s
      end

      ##
      # Produces a company czech organisation number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.czech_organisation_number #=> "90642741"
      #
      # @faker.version 1.9.1
      def czech_organisation_number
        sum = 0
        base = []
        [8, 7, 6, 5, 4, 3, 2].each do |weight|
          base << sample((0..9).to_a)
          sum += (weight * base.last)
        end
        base << (11 - (sum % 11)) % 10
        base.join
      end

      ##
      # Produces a company french siren number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.french_siren_number #=> "163417827"
      #
      # @faker.version 1.8.5
      # Get a random French SIREN number. See more here https://fr.wikipedia.org/wiki/Syst%C3%A8me_d%27identification_du_r%C3%A9pertoire_des_entreprises
      def french_siren_number
        base = (1..8).map { rand(10) }.join
        base + luhn_algorithm(base).to_s
      end

      ##
      # Produces a company french siret number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.french_siret_number #=> "76430067900496"
      #
      # @faker.version 1.8.5
      def french_siret_number
        location = rand(100).to_s.rjust(4, '0')
        org_no = french_siren_number + location
        org_no + luhn_algorithm(org_no).to_s
      end

      ##
      # Produces a company norwegian organisation number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.norwegian_organisation_number #=> "842457173"
      #
      # @faker.version 1.8.0
      # Get a random Norwegian organization number. Info: https://www.brreg.no/om-oss/samfunnsoppdraget-vart/registera-vare/einingsregisteret/organisasjonsnummeret/
      def norwegian_organisation_number
        # Valid leading digit: 8, 9
        mod11_check = nil
        while mod11_check.nil?
          base = [sample([8, 9]), format('%07d', rand(10**7))].join
          mod11_check = mod11(base)
        end
        base + mod11_check.to_s
      end

      ##
      # Produces a company australian business number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.australian_business_number #=> "93579396170"
      #
      # @faker.version 1.6.4
      def australian_business_number
        base = format('%09d', rand(10**9))
        abn = "00#{base}"

        (99 - (abn_checksum(abn) % 89)).to_s + base
      end

      ##
      # Produces a company polish taxpayer identification_number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.polish_taxpayer_identification_number #=> "2767549463"
      #
      # @faker.version 1.9.1
      # Get a random Polish taxpayer identification number More info https://pl.wikipedia.org/wiki/NIP
      def polish_taxpayer_identification_number
        result = []
        weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
        loop do
          result = Array.new(3) { rand(1..9) } + Array.new(7) { rand(10) }
          break if (weight_sum(result, weights) % 11) == result[9]
        end
        result.join
      end

      ##
      # Produces a company polish register of national economy.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.polish_register_of_national_economy #=> "788435970"
      #
      # @faker.version 1.9.1
      # Get a random Polish register of national economy number. More info https://pl.wikipedia.org/wiki/REGON
      def polish_register_of_national_economy(length: 9)
        raise ArgumentError, 'Length should be 9 or 14' unless [9, 14].include? length

        random_digits = []
        loop do
          random_digits = Array.new(length) { rand(10) }
          break if collect_regon_sum(random_digits) == random_digits.last
        end
        random_digits.join
      end

      ##
      # Produces a company south african pty ltd registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.south_african_pty_ltd_registration_number #=> "7043/2400717902/07"
      #
      # @faker.version 1.9.2
      def south_african_pty_ltd_registration_number
        regexify(%r{\d{4}/\d{4,10}/07})
      end

      ##
      # Produces a company south african close corporation registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.south_african_close_corporation_registration_number #=> "CK38/5739937418/23"
      #
      # @faker.version 1.9.2
      def south_african_close_corporation_registration_number
        regexify(%r{(CK\d{2}|\d{4})/\d{4,10}/23})
      end

      ##
      # Produces a company south african listed company registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.south_african_listed_company_registration_number #=> "2512/87676/06"
      #
      # @faker.version 1.9.2
      def south_african_listed_company_registration_number
        regexify(%r{\d{4}/\d{4,10}/06})
      end

      ##
      # Produces a company south african trust registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.south_african_trust_registration_number #=> "IT5673/937519896"
      #
      # @faker.version 1.9.2
      def south_african_trust_registration_number
        regexify(%r{IT\d{2,4}/\d{2,10}})
      end

      ##
      # Produces a company brazilian company number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.brazilian_company_number #=> "37205322000500"
      #
      # @faker.version 1.9.2
      def brazilian_company_number(formatted: false)
        digits = Array.new(8) { Faker::Number.digit.to_i } + [0, 0, 0, Faker::Number.non_zero_digit.to_i]

        factors = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2, 6].cycle

        2.times do
          checksum = digits.inject(0) { |acc, digit| acc + digit * factors.next } % 11
          digits << (checksum < 2 ? 0 : 11 - checksum)
        end

        number = digits.join

        formatted ? format('%s.%s.%s/%s-%s', *number.scan(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/).flatten) : number
      end

      ##
      # Get a random Russian tax number.
      # @param region [String] Any region string
      # @param type [Symbol] Legeal or not, defaults to :legal
      #
      # @return [String]
      # @example
      #   Faker::Company.russian_tax_number                             #=> "0415584064"
      #   Faker::Company.russian_tax_number(region: 'AZ')               #=> "AZ50124562"
      #   Faker::Company.russian_tax_number(region: 'AZ', type: false)  #=> "AZ8802315465"
      #
      # @faker.version 1.9.4
      def russian_tax_number(region: nil, type: :legal)
        inn_number(region, type)
      end

      ##
      # Produces a company sic code.
      #
      # @return [String]
      #
      # @example
      #   Faker::Company.sic_code #=> "7383"
      #
      # @faker.version 1.9.4
      def sic_code
        fetch('company.sic_code')
      end

      private

      # Mod11 functionality from https://github.com/badmanski/mod11/blob/master/lib/mod11.rb
      def mod11(number)
        weight = [2, 3, 4, 5, 6, 7,
                  2, 3, 4, 5, 6, 7,
                  2, 3, 4, 5, 6, 7]

        sum = 0

        number.to_s.reverse.chars.each_with_index do |char, i|
          sum += char.to_i * weight[i]
        end

        remainder = sum % 11

        case remainder
        when 0 then remainder
        when 1 then nil
        else 11 - remainder
        end
      end

      def luhn_algorithm(number)
        multiplications = []

        number.to_s.reverse.chars.each_with_index do |digit, i|
          multiplications << if i.even?
                               digit.to_i * 2
                             else
                               digit.to_i
                             end
        end

        sum = 0

        multiplications.each do |num|
          num.to_s.each_byte do |character|
            sum += character.chr.to_i
          end
        end

        if (sum % 10).zero?
          0
        else
          (sum / 10 + 1) * 10 - sum
        end
      end

      def abn_checksum(abn)
        abn_weights = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19]
        sum = 0

        abn_weights.each_with_index do |weight, i|
          sum += weight * abn[i].to_i
        end

        sum
      end

      def collect_regon_sum(array)
        weights = if array.size == 9
                    [8, 9, 2, 3, 4, 5, 6, 7]
                  else
                    [2, 4, 8, 5, 0, 9, 7, 3, 6, 1, 2, 4, 8]
                  end
        sum = weight_sum(array, weights) % 11
        sum == 10 ? 0 : sum
      end

      def weight_sum(array, weights)
        sum = 0
        (0..weights.size - 1).each do |index|
          sum += (array[index] * weights[index])
        end
        sum
      end

      #
      # For more on Russian tax number algorithm here:
      # https://ru.wikipedia.org/wiki/Идентификационный_номер_налогоплательщика#Вычисление_контрольных_цифр
      #
      # Range of regions:
      # https://ru.wikipedia.org/wiki/Коды_субъектов_Российской_Федерации
      # region [String] Any region string
      # @param type [Symbol] Legeal or not, defaults to :legal
      #
      # @return [String]
      # @example
      #   Faker::Comnpany.russian_tax_number
      #   Faker::Comnpany.russian_tax_number(region: 'AZ')
      #   Faker::Comnpany.russian_tax_number(region: 'AZ', type: false)
      def inn_number(region, type)
        n10 = [2, 4, 10, 3, 5, 9, 4, 6, 8]
        n11 = [7, 2, 4, 10, 3, 5, 9, 4, 6, 8]
        n12 = [3, 7, 2, 4, 10, 3, 5, 9, 4, 6, 8]

        region = format('%.2d', rand(0o1..92)) if region.nil?
        checksum = if type == :legal
                     number = region.to_s + rand(1_000_000..9_999_999).to_s
                     inn_checksum(n10, number)
                   else
                     number = region.to_s + rand(10_000_000..99_999_999).to_s
                     inn_checksum(n11, number) + inn_checksum(n12, number + inn_checksum(n11, number))
                   end

        number + checksum
      end

      def inn_checksum(factor, number)
        (
          factor.map.with_index.reduce(0) do |v, i|
            v + i[0] * number[i[1]].to_i
          end % 11 % 10
        ).to_s
      end

      def spanish_cif_control_digit(organization_type, code)
        letters = %w[J A B C D E F G H I]

        control = code.chars.each_with_index.inject(0) do |sum, (value, index)|
          if (index + 1).even?
            sum + value.to_i
          else
            sum + spanish_b_algorithm(value.to_i)
          end
        end

        control = control.to_s[-1].to_i
        control = control.zero? ? control : 10 - control

        %w[A B C D E F G H J U V].include?(organization_type) ? control : letters[control]
      end

      def spanish_b_algorithm(value)
        result = value.to_i * 2

        return result if result < 10

        result.to_s[0].to_i + result.to_s[1].to_i
      end
    end
  end
end
