# Active Record is not defined as a runtime dependency in the gemspec.
unless defined?(::ActiveRecord)
  begin
    # If by some miracle it hasn't been loaded yet, try to load it.
    require "active_record"
  rescue LoadError
    # If it fails to load, then assume the user is try to use flag_shih_tzu with some other database adapter
    warn "FlagShihTzu probably won't work unless you have some version of Active Record loaded. Versions >= 2.3 are supported."
  end
end

if defined?(::ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 3

  module ActiveModel
    # Open ActiveModel::Validations to define some additional ones
    module Validations

      # A simple EachValidator that will check for the presence of the flags specified
      class PresenceOfFlagsValidator < EachValidator
        def validate_each(record, attribute, value)
          value = record.send(:read_attribute_for_validation, attribute)
          check_flag(record, attribute)
          record.errors.add(attribute, :blank, options) if value.blank? || value == 0
        end

        private

        def check_flag(record, attribute)
          unless record.class.flag_columns.include? attribute.to_s
            raise ArgumentError.new("#{attribute} is not one of the flags columns (#{record.class.flag_columns.join(', ')})")
          end
        end
      end

      # Use these validators in your model
      module HelperMethods
        # Validates that the specified attributes are flags and are not blank.
        # Happens by default on save. Example:
        #
        #  class Spaceship < ActiveRecord::Base
        #    include FlagShihTzu
        #
        #    has_flags({ 1 => :warpdrive, 2 => :hyperspace }, :column => 'engines')
        #    validates_presence_of_flags :engines
        #  end
        #
        # The engines attribute must be a flag in the object and it cannot be blank.
        #
        # Configuration options:
        # * <tt>:message</tt> - A custom error message (default is: "can't be blank").
        # * <tt>:on</tt> - Specifies when this validation is active. Runs in all
        #   validation contexts by default (+nil+), other options are <tt>:create</tt>
        #   and <tt>:update</tt>.
        # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if
        #   the validation should occur (e.g. <tt>:if => :allow_validation</tt>, or
        #   <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>). The method, proc
        #   or string should return or evaluate to a true or false value.
        # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine
        #   if the validation should not occur (e.g. <tt>:unless => :skip_validation</tt>,
        #   or <tt>:unless => Proc.new { |spaceship| spaceship.warp_step <= 2 }</tt>). The method,
        #   proc or string should return or evaluate to a true or false value.
        # * <tt>:strict</tt> - Specifies whether validation should be strict.
        #   See <tt>ActiveModel::Validation#validates!</tt> for more information.
        def validates_presence_of_flags(*attr_names)
          validates_with PresenceOfFlagsValidator, _merge_attributes(attr_names)
        end
      end

    end
  end
end
