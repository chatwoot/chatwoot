module Hashie
  module Extensions
    module Dash
      # Extends a Dash with the ability to remap keys from a source hash.
      #
      # Property translation is useful when you need to read data from another
      # application -- such as a Java API -- where the keys are named
      # differently from Ruby conventions.
      #
      # == Example from inconsistent APIs
      #
      #   class PersonHash < Hashie::Dash
      #     include Hashie::Extensions::Dash::PropertyTranslation
      #
      #     property :first_name, from :firstName
      #     property :last_name, from: :lastName
      #     property :first_name, from: :f_name
      #     property :last_name, from: :l_name
      #   end
      #
      #   person = PersonHash.new(firstName: 'Michael', l_name: 'Bleigh')
      #   person[:first_name]  #=> 'Michael'
      #   person[:last_name]   #=> 'Bleigh'
      #
      # You can also use a lambda to translate the value. This is particularly
      # useful when you want to ensure the type of data you're wrapping.
      #
      # == Example using translation lambdas
      #
      #   class DataModelHash < Hashie::Dash
      #     include Hashie::Extensions::Dash::PropertyTranslation
      #
      #     property :id, transform_with: ->(value) { value.to_i }
      #     property :created_at, from: :created, with: ->(value) { Time.parse(value) }
      #   end
      #
      #   model = DataModelHash.new(id: '123', created: '2014-04-25 22:35:28')
      #   model.id.class          #=> Integer (Fixnum if you are using Ruby 2.3 or lower)
      #   model.created_at.class  #=> Time
      module PropertyTranslation
        def self.included(base)
          base.instance_variable_set(:@transforms, {})
          base.instance_variable_set(:@translations_hash, ::Hash.new { |hash, key| hash[key] = {} })
          base.extend(ClassMethods)
          base.send(:include, InstanceMethods)
        end

        module ClassMethods
          attr_reader :transforms, :translations_hash

          # Ensures that any inheriting classes maintain their translations.
          #
          # * <tt>:default</tt> - The class inheriting the translations.
          def inherited(klass)
            super
            klass.instance_variable_set(:@transforms, transforms.dup)
            klass.instance_variable_set(:@translations_hash, translations_hash.dup)
          end

          def permitted_input_keys
            @permitted_input_keys ||=
              properties
              .map { |property| inverse_translations.fetch property, property }
          end

          # Defines a property on the Trash. Options are as follows:
          #
          # * <tt>:default</tt> - Specify a default value for this property, to be
          # returned before a value is set on the property in a new Dash.
          # * <tt>:from</tt> - Specify the original key name that will be write only.
          # * <tt>:with</tt> - Specify a lambda to be used to convert value.
          # * <tt>:transform_with</tt> - Specify a lambda to be used to convert value
          # without using the :from option. It transform the property itself.
          def property(property_name, options = {})
            super

            from = options[:from]
            converter = options[:with]
            transformer = options[:transform_with]

            if from
              fail_self_transformation_error!(property_name) if property_name == from
              define_translation(from, property_name, converter || transformer)
              define_writer_for_source_property(from)
            elsif valid_transformer?(transformer)
              transforms[property_name] = transformer
            end
          end

          def transformed_property(property_name, value)
            transforms[property_name].call(value)
          end

          def transformation_exists?(name)
            transforms.key? name
          end

          def translation_exists?(name)
            translations_hash.key? name
          end

          def translations
            @translations ||= {}.tap do |translations|
              translations_hash.each do |(property_name, property_translations)|
                translations[property_name] =
                  if property_translations.size > 1
                    property_translations.keys
                  else
                    property_translations.keys.first
                  end
              end
            end
          end

          def inverse_translations
            @inverse_translations ||= {}.tap do |translations|
              translations_hash.each do |(property_name, property_translations)|
                property_translations.each_key do |key|
                  translations[key] = property_name
                end
              end
            end
          end

          private

          def define_translation(from, property_name, translator)
            translations_hash[from][property_name] = translator
          end

          def define_writer_for_source_property(property)
            define_method "#{property}=" do |val|
              __translations[property].each do |name, with|
                self[name] = with.respond_to?(:call) ? with.call(val) : val
              end
            end
          end

          def fail_self_transformation_error!(property_name)
            raise ArgumentError,
                  "Property name (#{property_name}) and :from option must not be the same"
          end

          def valid_transformer?(transformer)
            transformer.respond_to? :call
          end
        end

        module InstanceMethods
          # Sets a value on the Dash in a Hash-like way.
          #
          # Note: Only works on pre-existing properties.
          def []=(property, value)
            if self.class.translation_exists? property
              send("#{property}=", value)

              if self.class.transformation_exists? property
                super property, self.class.transformed_property(property, value)
              elsif self.class.properties.include?(property)
                super(property, value)
              end
            elsif self.class.transformation_exists? property
              super property, self.class.transformed_property(property, value)
            elsif property_exists? property
              super
            end
          end

          # Deletes any keys that have a translation
          def initialize_attributes(attributes)
            return unless attributes
            attributes_copy = attributes.dup.delete_if do |k, v|
              if self.class.translations_hash.include?(k)
                self[k] = v
                true
              end
            end
            super attributes_copy
          end

          # Raises an NoMethodError if the property doesn't exist
          def property_exists?(property)
            fail_no_property_error!(property) unless self.class.property?(property)
            true
          end

          private

          def __translations
            self.class.translations_hash
          end
        end
      end
    end
  end
end
