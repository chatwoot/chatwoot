module TelephoneNumber
  require 'nokogiri'
  class PhoneDataImporter
    attr_reader :data, :file, :override

    def initialize(file_name, override: false)
      @data = {}
      @file = File.open(file_name) { |f| Nokogiri::XML(f) }
      @override = override
    end

    def import!
      parse_main_data
      save_data_file
    end

    def parse_main_data
      file.css('territories territory').each do |territory|
        country_code = territory.attributes['id'].value.to_sym
        @data[country_code] ||= {}

        load_base_attributes(@data[country_code], territory)
        load_references(@data[country_code], territory)
        load_validations(@data[country_code], territory)
        load_formats(@data[country_code], territory)
      end
    end

    private

    def load_formats(country_data, territory)
      formats_arr = territory.css('availableFormats numberFormat').map do |format|
        {}.tap do |fhash|
          format.attributes.values.each do |attr|
            key = underscore(attr.name).to_sym
            fhash[key] = if key == :national_prefix_formatting_rule
                           attr.value
                         else
                           attr.value.delete("\n ")
                         end
          end
          format.elements.each do |child|
            key = underscore(child.name).to_sym
            fhash[key] = [:format, :intl_format].include?(key) ? child.text : child.text.delete("\n ")
          end
        end
      end

      return if override && formats_arr.empty?
      country_data[:formats] = formats_arr
    end

    def load_validations(country_data, territory)
      country_data[:validations] = {}
      territory.elements.each do |element|
        next if element.name == 'references' || element.name == 'availableFormats'
        country_data[:validations][underscore(element.name).to_sym] = {}.tap do |validation_hash|
          element.elements.each { |child| validation_hash[underscore(child.name).to_sym] = child.text.delete("\n ") }
        end
      end
      country_data.delete(:validations) if country_data[:validations].empty? && override
    end

    def load_base_attributes(country_data, territory)
      territory.attributes.each do |key, value_object|
        underscored_key = underscore(key).to_sym
        country_data[underscored_key] = if underscored_key == :national_prefix_for_parsing
                                          value_object.value.delete("\n ")
                                        else
                                          value_object.value
                                        end
      end
    end

    def load_references(country_data, territory)
      ref_arr = territory.css('references sourceUrl').map(&:text)
      return if override && ref_arr.empty?
      country_data[:references] = ref_arr
    end

    def underscore(camel_cased_word)
      return camel_cased_word unless camel_cased_word.match?(/[A-Z-]|::/)
      word = camel_cased_word.to_s.gsub(/::/, '/')
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end

    def save_data_file
      data_file = override ? 'telephone_number_data_override_file.dat' : "#{File.dirname(__FILE__)}/../../data/telephone_number_data_file.dat"
      File.open(data_file, 'wb+') { |f| Marshal.dump(@data, f) }
    end
  end
end
