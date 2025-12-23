require "valid_email2/address"
require "active_model"
require "active_model/validations"

module ValidEmail2
  class EmailValidator < ActiveModel::EachValidator
    def default_options
      { disposable: false, mx: false, strict_mx: false, disallow_subaddressing: false, multiple: false, dns_timeout: 5, dns_nameserver: nil }
    end

    def validate_each(record, attribute, value)
      return unless value.present?
      options = default_options.merge(self.options)

      addresses = sanitized_values(value).map { |v| ValidEmail2::Address.new(v, options[:dns_timeout], options[:dns_nameserver]) }

      error(record, attribute) && return unless addresses.all?(&:valid?)

      if options[:disallow_dotted]
        error(record, attribute) && return if addresses.any?(&:dotted?)
      end

      if options[:disallow_subaddressing]
        error(record, attribute) && return if addresses.any?(&:subaddressed?)
      end

      if options[:disposable]
        error(record, attribute) && return if addresses.any?(&:disposable?)
      end

      if options[:disposable_domain]
        error(record, attribute) && return if addresses.any?(&:disposable_domain?)
      end

      if options[:disposable_with_whitelist]
        error(record, attribute) && return if addresses.any? { |address| address.disposable? && !address.whitelisted? }
      end

      if options[:disposable_domain_with_whitelist]
        error(record, attribute) && return if addresses.any? { |address| address.disposable_domain? && !address.whitelisted? }
      end

      if options[:blacklist]
        error(record, attribute) && return if addresses.any?(&:blacklisted?)
      end

      if options[:mx]
        error(record, attribute) && return unless addresses.all?(&:valid_mx?)
      end

      if options[:strict_mx]
        error(record, attribute) && return unless addresses.all?(&:valid_strict_mx?)
      end
    end

    def sanitized_values(input)
      options = default_options.merge(self.options)

      if options[:multiple]
        email_list = input.is_a?(Array) ? input : input.split(',')
      else
        email_list = [input]
      end

      email_list.reject(&:empty?).map(&:strip)
    end

    def error(record, attribute)
      message = options[:message].respond_to?(:call) ? options[:message].call : options[:message]

      record.errors.add(attribute, message || :invalid)
    end
  end
end
