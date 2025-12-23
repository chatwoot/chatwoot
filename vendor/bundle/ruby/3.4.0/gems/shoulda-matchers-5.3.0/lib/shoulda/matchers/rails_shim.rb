module Shoulda
  module Matchers
    # @private
    module RailsShim # rubocop:disable Metrics/ModuleLength
      class << self
        def action_pack_version
          Gem::Version.new(::ActionPack::VERSION::STRING)
        rescue NameError
          Gem::Version.new('0')
        end

        def active_record_gte_6?
          Gem::Requirement.new('>= 6').satisfied_by?(active_record_version)
        end

        def active_record_version
          Gem::Version.new(::ActiveRecord::VERSION::STRING)
        rescue NameError
          Gem::Version.new('0')
        end

        def active_model_version
          Gem::Version.new(::ActiveModel::VERSION::STRING)
        rescue NameError
          Gem::Version.new('0')
        end

        def active_model_st_6_1?
          Gem::Requirement.new('< 6.1').satisfied_by?(active_model_version)
        end

        def active_model_lt_7?
          Gem::Requirement.new('< 7').satisfied_by?(active_model_version)
        end

        def generate_validation_message(
          record,
          attribute,
          type,
          model_name,
          options
        )
          if record && record.errors.respond_to?(:generate_message)
            record.errors.generate_message(attribute.to_sym, type, options)
          else
            simply_generate_validation_message(
              attribute,
              type,
              model_name,
              options,
            )
          end
        rescue RangeError
          simply_generate_validation_message(
            attribute,
            type,
            model_name,
            options,
          )
        end

        def serialized_attributes_for(model)
          attribute_types_for(model).
            inject({}) do |hash, (attribute_name, attribute_type)|
              if attribute_type.is_a?(::ActiveRecord::Type::Serialized)
                hash.merge(attribute_name => attribute_type.coder)
              else
                hash
              end
            end
        rescue NotImplementedError
          {}
        end

        def attribute_serialization_coder_for(model, attribute_name)
          serialized_attributes_for(model)[attribute_name.to_s]
        end

        def verb_for_update
          :patch
        end

        def parent_of(mod)
          if mod.respond_to?(:module_parent)
            mod.module_parent
          else
            mod.parent
          end
        end

        def has_secure_password?(record, attribute_name)
          if secure_password_module
            attribute_name == :password &&
              record.class.ancestors.include?(secure_password_module)
          else
            record.respond_to?("authenticate_#{attribute_name}")
          end
        end

        def digestible_attributes_in(record)
          record.methods.inject([]) do |array, method_name|
            match = method_name.to_s.match(
              /\A(\w+)_(?:confirmation|digest)=\Z/,
            )

            if match
              array.concat([match[1].to_sym])
            else
              array
            end
          end
        end

        def secure_password_module
          ::ActiveModel::SecurePassword::InstanceMethodsOnActivation
        rescue NameError
          nil
        end

        def attribute_types_for(model)
          if model.respond_to?(:attribute_types)
            model.attribute_types
          elsif model.respond_to?(:type_for_attribute)
            model.columns.inject({}) do |hash, column|
              key = column.name.to_s
              value = model.type_for_attribute(column.name)
              hash.merge(key => value)
            end
          else
            raise NotImplementedError
          end
        end

        def attribute_type_for(model, attribute_name)
          attribute_types_for(model)[attribute_name.to_s]
        rescue NotImplementedError
          if model.respond_to?(:type_for_attribute)
            model.type_for_attribute(attribute_name)
          else
            FakeAttributeType.new(model, attribute_name)
          end
        end

        def supports_full_attributes_api?(model)
          defined?(::ActiveModel::Attributes) &&
            model.respond_to?(:attribute_types)
        end

        private

        def simply_generate_validation_message(
          attribute,
          type,
          model_name,
          options
        )
          default_translation_keys = [
            :"activemodel.errors.models.#{model_name}.attributes.#{attribute}
              .#{type}",
            :"activemodel.errors.models.#{model_name}.#{type}",
            :"activemodel.errors.messages.#{type}",
            :"activerecord.errors.models.#{model_name}.attributes.#{attribute}
              .#{type}",
            :"activerecord.errors.models.#{model_name}.#{type}",
            :"activerecord.errors.messages.#{type}",
            :"errors.attributes.#{attribute}.#{type}",
            :"errors.messages.#{type}",
          ]
          primary_translation_key = default_translation_keys.shift
          translate_options =
            { default: default_translation_keys }.merge(options)
          I18n.translate(primary_translation_key, translate_options)
        end

        class FakeAttributeType
          def initialize(model, attribute_name)
            @model = model
            @attribute_name = attribute_name
          end

          def coder
            nil
          end

          private

          attr_reader :model, :attribute_name
        end
      end
    end
  end
end
